#ifndef __TP_SIGNALMANAGER_MQH__
#define __TP_SIGNALMANAGER_MQH__

#include "TP_TrendSignal.mqh"
#include "../MarketState/TP_MarketState.mqh"

//+------------------------------------------------------------------+
//| Administrador de señales                                         |
//+------------------------------------------------------------------+
class CTPSignalManager
{
private:

   CTPTrendSignal m_trendSignal;

public:

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

   CTPSignalManager()
   {
   }

   //--------------------------------------------------
   // Actualizar señales
   //--------------------------------------------------

   bool Update(const CTPMarketState &marketState)
   {
      return m_trendSignal.Update(marketState);
   }

   //--------------------------------------------------
   // Getters
   //--------------------------------------------------

   bool Buy() const
   {
      return m_trendSignal.Buy();
   }

   bool Sell() const
   {
      return m_trendSignal.Sell();
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