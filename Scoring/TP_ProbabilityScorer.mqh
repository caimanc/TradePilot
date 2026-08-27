#ifndef __TP_PROBABILITYSCORER_MQH__
#define __TP_PROBABILITYSCORER_MQH__

#include "../MarketState/TP_MarketState.mqh"

//+------------------------------------------------------------------+
//| Scorer probabilistico (scoring ponderado)                        |
//|                                                                  |
//| P(dir) = Suma(w_i x f_i(dir)) / Suma(w_i)                        |
//|                                                                  |
//| Cada feature (tendencia, HTF, setup, sesion) aporta un peso.     |
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

   //--------------------------------------------------
   // Suma de pesos activos
   //--------------------------------------------------

   double SumaPesos()
   {
      double suma = 0.0;

      if(m_wTendencia > 0.0) suma += m_wTendencia;
      if(m_wHtf       > 0.0) suma += m_wHtf;
      if(m_wSetup     > 0.0) suma += m_wSetup;
      if(m_wSesion    > 0.0) suma += m_wSesion;

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

      m_pBuy  = 0.0;
      m_pSell = 0.0;
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
   // Calcular probabilidades por direccion
   //--------------------------------------------------

   void Update(const CTPMarketState &marketState)
   {
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
      // Sesion (por ahora sin ventana; peso 0=off)
      //--------------------------------------------------

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
