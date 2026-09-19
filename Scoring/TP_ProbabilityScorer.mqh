#ifndef __TP_PROBABILITYSCORER_MQH__
#define __TP_PROBABILITYSCORER_MQH__

#include "../MarketState/TP_MarketState.mqh"
#include "../Sessions/TP_Sessions.mqh"
#include "../MarketAnalysis/TP_DeltaFlow.mqh"

//+------------------------------------------------------------------+
//| Scorer probabilistico (scoring ponderado)                        |
//|                                                                  |
//| P(dir) = Suma(w_i x f_i(dir)) / Suma(w_i)                        |
//|                                                                  |
//| Cada feature (tendencia, HTF, setup, sesion) aporta un peso.     |
//| La sesion aporta un FACTOR CONTINUO (0..1) por su peso:          |
//|   - solape (Londres+NY) : factor 1.0   (máximo)                  |
//|   - inicio de sesion    : factor 0.7                             |
//|   - media sesion        : factor 0.5                             |
//|   - valle / cierre      : factor 0.3                             |
//|   - fuera de sesiones   : factor 0.0 (no aporta)                 |
//|                                                                  |
//| Threshold = 0 desactiva el filtro (comportamiento clasico).      |
//| Andamiaje para un futuro Naive Bayes con datos etiquetados.      |
//+------------------------------------------------------------------+
class CTPProbabilityScorer
{
private:

   double m_threshold;
   double m_wTendencia;
   double m_wHtf;
   double m_wSetup;
   double m_wSesion;

   double m_pBuy;
   double m_pSell;

   double m_sesionFactor;

   CTPSessions m_sessions;

   //--------------------------------------------------
   // Feature de flujo/delta (opcional)
   //--------------------------------------------------

   bool m_deltaActivo;

   double m_wDelta;

   CTPDeltaFlow *m_deltaFlow;

   //--------------------------------------------------
   // Peso activo de cada feature (0 si peso en 0)
   //--------------------------------------------------

   double WActivo(double w)
   {
      return (w > 0.0) ? w : 0.0;
   }

   //--------------------------------------------------
   // Factor continuo de sesion (0..1)
   //--------------------------------------------------

   double FactorSesion()
   {
      if(!m_sessions.IsLondonOpen() &&
         !m_sessions.IsNewYorkOpen())
         return 0.0;   // fuera de ventanas activas

      // Solape Londres + NY = liquidez maxima
      if(m_sessions.IsLondonOpen() &&
         m_sessions.IsNewYorkOpen())
         return 1.0;

      MqlDateTime tm;
      TimeToStruct(TimeCurrent(), tm);
      int hora = tm.hour;

      bool esLondon = m_sessions.IsLondonOpen();
      bool esNY     = m_sessions.IsNewYorkOpen();

      // Rango de la sesion activa (hora servidor)
      int inicio = esLondon ? 8 : 13;
      int fin    = esLondon ? 17 : 22;

      int transcurrido = hora - inicio;

      if(transcurrido < 0)
         transcurrido = 0;

      int total = fin - inicio;

      if(total <= 0)
         return 0.5;

      // Proporcion dentro de la sesion (0 inicio -> 1 cierre)
      double proporcion = (double)transcurrido / (double)total;

      // Apertura con mas peso, valles hacia el cierre
      if(proporcion < 0.25)
         return 0.8;      // inicio, gran peso

      if(proporcion < 0.75)
         return 0.5;      // media sesion

      return 0.3;         // cierre / valle
   }

   //--------------------------------------------------
   // Suma de pesos activos
   //--------------------------------------------------

   double SumaPesos()
   {
      double suma = 0.0;

      suma += WActivo(m_wTendencia);
      suma += WActivo(m_wHtf);
      suma += WActivo(m_wSetup);

      // La sesion cuenta en el denominador solo si tiene peso
      if(m_wSesion > 0.0)
         suma += m_wSesion;

      // El delta cuenta solo si el interruptor esta activo
      if(m_deltaActivo && m_deltaFlow != NULL)
         suma += m_wDelta;

      return suma;
   }

public:

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

   CTPProbabilityScorer()
   {
      m_threshold  = 0.0;
      m_wTendencia = 1.0;
      m_wHtf       = 1.0;
      m_wSetup     = 1.0;
      m_wSesion    = 0.0;

      m_pBuy        = 0.0;
      m_pSell       = 0.0;
      m_sesionFactor = 0.0;

      m_deltaActivo = false;
      m_wDelta      = 1.0;
      m_deltaFlow   = NULL;
   }

   //--------------------------------------------------
   // Configurar pesos y umbral
   //--------------------------------------------------

   void SetParams(
      double threshold,
      double wTendencia,
      double wHtf,
      double wSetup,
      double wSesion)
   {
      m_threshold  = threshold;
      m_wTendencia = wTendencia;
      m_wHtf       = wHtf;
      m_wSetup     = wSetup;
      m_wSesion    = wSesion;
   }

   //--------------------------------------------------
   // Configurar offset de sesiones del broker
   //--------------------------------------------------

   void SetSessions(int brokerUtcOffset)
   {
      // Solo Londres + NY activas para el factor
      m_sessions.Initialize(
         brokerUtcOffset,
         false,   // Sydney
         false,   // Tokyo
         true,    // London
         true);   // New York
   }

   //--------------------------------------------------
   // Feature de flujo/delta (opcional)
   //--------------------------------------------------

   void SetDeltaActivo(bool activo)
   {
      m_deltaActivo = activo;
   }

   void SetDeltaFlow(CTPDeltaFlow &delta)
   {
      m_deltaFlow = GetPointer(delta);
   }

   //--------------------------------------------------
   // Calcular probabilidades por direccion
   //--------------------------------------------------

   void Update(const CTPMarketState &marketState)
   {
      m_sessions.Update();

      m_sesionFactor = FactorSesion();

      double suma = SumaPesos();

      if(suma <= 0.0)
      {
         m_pBuy  = 0.0;
         m_pSell = 0.0;
         return;
      }

      double scoreBuy  = 0.0;
      double scoreSell = 0.0;

      //--------------------------------------------------
      // Tendencia local
      //--------------------------------------------------

      if(m_wTendencia > 0.0)
      {
         if(marketState.IsBullTrend()) scoreBuy  += m_wTendencia;
         if(marketState.IsBearTrend()) scoreSell += m_wTendencia;
      }

      //--------------------------------------------------
      // Sesgo del tf superior
      //--------------------------------------------------

      if(m_wHtf > 0.0)
      {
         if(marketState.IsHtfBull())   scoreBuy  += m_wHtf;
         if(marketState.IsHtfBear())   scoreSell += m_wHtf;
      }

      //--------------------------------------------------
      // Setup estructural
      //--------------------------------------------------

      if(m_wSetup > 0.0)
      {
         if(marketState.IsBuySetupValid())  scoreBuy  += m_wSetup;
         if(marketState.IsSellSetupValid()) scoreSell += m_wSetup;
      }

      //--------------------------------------------------
      // Sesion (factor continuo aplicado en ambas direcciones)
      //--------------------------------------------------

      if(m_wSesion > 0.0)
      {
         scoreBuy  += m_wSesion * m_sesionFactor;
         scoreSell += m_wSesion * m_sesionFactor;
      }

      //--------------------------------------------------
      // Flujo/delta (feature opcional)
      // Delta positivo favorece compra; negativo, venta
      //--------------------------------------------------

      if(m_deltaActivo && m_deltaFlow != NULL)
      {
         double fDelta = (m_deltaFlow.DeltaNorm() + 1.0) / 2.0;

         scoreBuy  += m_wDelta *    fDelta;
         scoreSell += m_wDelta * (1.0 - fDelta);
      }

      m_pBuy  = scoreBuy  / suma * 100.0;
      m_pSell = scoreSell / suma * 100.0;
   }

   //--------------------------------------------------
   // Getters
   //--------------------------------------------------

   bool Enabled() const
   {
      return m_threshold > 0.0;
   }

   double Threshold() const
   {
      return m_threshold;
   }

   double BuyProbability() const
   {
      return m_pBuy;
   }

   double SellProbability() const
   {
      return m_pSell;
   }

   double SesionFactor() const
   {
      return m_sesionFactor;
   }

   string SesionName() const
   {
      return m_sessions.CurrentSession();
   }

   //--------------------------------------------------
   // Verdictos (los usa SignalManager)
   //--------------------------------------------------

   bool Buy() const
   {
      if(!Enabled())
         return true;   // desactivado = no restringe

      return m_pBuy >= m_threshold;
   }

   bool Sell() const
   {
      if(!Enabled())
         return true;   // desactivado = no restringe

      return m_pSell >= m_threshold;
   }

};

#endif
