#ifndef __TP_SIGNALMANAGER_MQH__
#define __TP_SIGNALMANAGER_MQH__

#include "TP_TrendSignal.mqh"
#include "../MarketState/TP_MarketState.mqh"
#include "../Scoring/TP_ProbabilityScorer.mqh"

//+------------------------------------------------------------------+
//| Administrador de señales                                         |
//+------------------------------------------------------------------+
class CTPSignalManager
{
private:

   CTPTrendSignal m_trendSignal;

   CTPProbabilityScorer m_probabilityScorer;

public:

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

   CTPSignalManager()
   {
   }

   //--------------------------------------------------
   // Configurar capa de probabilidad
   //--------------------------------------------------

   void SetScoreParams(
      double threshold,
      double wTendencia,
      double wHtf,
      double wSetup,
      double wSesion)
   {
      m_probabilityScorer.SetParams(
         threshold,
         wTendencia,
         wHtf,
         wSetup,
         wSesion
      );
   }

   //--------------------------------------------------
   // Actualizar señales
   //--------------------------------------------------

   bool Update(const CTPMarketState &marketState)
   {
      bool ok = m_trendSignal.Update(marketState);

      m_probabilityScorer.Update(marketState);

      return ok;
   }

   //--------------------------------------------------
   // Getters
   //--------------------------------------------------

   bool Buy() const
   {
      return m_trendSignal.Buy() &&
             m_probabilityScorer.Buy();
   }

   bool Sell() const
   {
      return m_trendSignal.Sell() &&
             m_probabilityScorer.Sell();
   }

   //--------------------------------------------------
   // Probabilidades para el panel
   //--------------------------------------------------

   double BuyProbability() const
   {
      return m_probabilityScorer.BuyProbability();
   }

   double SellProbability() const
   {
      return m_probabilityScorer.SellProbability();
   }

   double ScoreThreshold() const
   {
      return m_probabilityScorer.Threshold();
   }

   bool ScoreEnabled() const
   {
      return m_probabilityScorer.Enabled();
   }

   //--------------------------------------------------
   // Reset
   //--------------------------------------------------

   void Reset()
   {
      // Reservado para futuras señales
   }

};

#endif