#ifndef __TP_PROBABILITYSCORER_MQH__
#define __TP_PROBABILITYSCORER_MQH__

#include "../MarketState/TP_MarketState.mqh"
#include "../Sessions/TP_Sessions.mqh"
#include "../MarketAnalysis/TP_DeltaFlow.mqh"
#include "TP_NaiveBayes.mqh"

//+------------------------------------------------------------------+
//| Scorer probabilistico (Naive Bayes opcional)                     |
//|                                                                  |
//| P(dir) = modelo.ProbabilidadGanar(dir, tend, htf,               |
//|                                   setup, sesion)        0..100  |
//|                                                                  |
//| El modelo de TP_NaiveBayes.mqh es VIVO: aprende de las          |
//| operaciones cerradas del propio EA (ventana deslizante) y se     |
//| persiste en MQL5/Files/TradePilot_NB.csv. Ya no hay pesos        |
//| manuales: las features son categoricas y el modelo aprende      |
//| P(feature | ganar / perder).                                     |
//|                                                                  |
//| InpNBActivo = false  -> el scorer no restringe nada              |
//| (pBuy/pSell quedan en 0; un threshold olvidado no bloquea).     |
//|                                                                  |
//| El threshold sigue siendo la PUERTA de confianza, y solo filtra  |
//| cuando NB está activo:                                           |
//|   InpNBActivo=true  y  threshold>0  -> filtro por probabilidad.  |
//|   threshold = 0  o  NB apagado      -> comportamiento clasico.   |
//+------------------------------------------------------------------+
class CTPProbabilityScorer
{
private:

   double m_threshold;

   bool m_nbActivo;

   //--------------------------------------------------
   // Modelo vivo (aprendizaje en linea)
   //--------------------------------------------------

   CTPNaiveBayes *m_model;

   double m_pBuy;
   double m_pSell;

   double m_sesionFactor;

   CTPSessions m_sessions;

   //--------------------------------------------------
   // Feature de flujo/delta (opcional)
   //--------------------------------------------------

   bool m_deltaActivo;

   CTPDeltaFlow *m_deltaFlow;

   //--------------------------------------------------
   // Factor continuo de sesion (0..1)
   // Solo informativo para el panel: no participa en
   // el calculo de probabilidad del modelo.
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

public:

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

   CTPProbabilityScorer()
   {
      m_threshold = 0.0;
      m_nbActivo  = false;

      m_model = NULL;

      m_pBuy        = 0.0;
      m_pSell       = 0.0;
      m_sesionFactor = 0.0;

      m_deltaActivo = false;
      m_deltaFlow   = NULL;
   }

   //--------------------------------------------------
   // Configurar umbral de confianza
   //--------------------------------------------------

   void SetParams(double threshold)
   {
      m_threshold = threshold;
   }

   //--------------------------------------------------
   // Activar/desactivar el calculo con Naive Bayes
   //--------------------------------------------------

   void SetNBActivo(bool activo)
   {
      m_nbActivo = activo;
   }

   //--------------------------------------------------
   // Conectar el modelo vivo (NB aprende en linea)
   //--------------------------------------------------

   void SetModel(CTPNaiveBayes &model)
   {
      m_model = GetPointer(model);
   }

   //--------------------------------------------------
   // Configurar offset de sesiones del broker
   //--------------------------------------------------

   void SetSessions(int brokerUtcOffset)
   {
      // Solo Londres + NY activas para el factor informativo
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

      // Solo informativo para el panel
      m_sesionFactor = FactorSesion();

      if(!m_nbActivo)
      {
         m_pBuy  = 0.0;
         m_pSell = 0.0;
         return;
      }

      // Sin modelo conectado no hay probabilidad que aplicar
      if(m_model == NULL)
      {
         m_pBuy  = 0.0;
         m_pSell = 0.0;
         return;
      }

      //--------------------------------------------------
      // Features categoricas (mismas que registra la
      // telemetria en TP_TEL|ENTRADA)
      //--------------------------------------------------

      string tend = marketState.IsBullTrend() ? "BULL" :
                    (marketState.IsBearTrend() ? "BEAR" : "RANGO");

      string htf = marketState.IsHtfBull() ? "BULL" :
                   (marketState.IsHtfBear() ? "BEAR" : "NEUTRO");

      string setup = marketState.IsBuySetupValid() ? "BUY" :
                     (marketState.IsSellSetupValid() ? "SELL" : "NINGUNO");

      string sesion = m_sessions.CurrentSession();

      //--------------------------------------------------
      // Modelo Naive Bayes
      //--------------------------------------------------

      double pBuy  = m_model.ProbabilidadGanar(
                        "BUY",  tend, htf, setup, sesion);

      double pSell = m_model.ProbabilidadGanar(
                        "SELL", tend, htf, setup, sesion);

      // Modelo no disponible: no restringe con probabilidades invalidas
      if(pBuy < 0.0)
         pBuy = 0.0;

      if(pSell < 0.0)
         pSell = 0.0;

      m_pBuy  = pBuy;
      m_pSell = pSell;
   }

   //--------------------------------------------------
   // Getters
   //--------------------------------------------------

   bool Enabled() const
   {
      // El filtro solo aplica cuando el modelo NB esta activo
      // y el umbral de confianza es > 0. Con NB apagado, un
      // threshold olvidado NO debe bloquear las senales clasicas.
      return m_nbActivo && m_threshold > 0.0;
   }

   bool NBActivo() const
   {
      return m_nbActivo;
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
