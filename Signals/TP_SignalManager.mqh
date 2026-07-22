#ifndef __TP_SIGNALMANAGER_MQH__
#define __TP_SIGNALMANAGER_MQH__

#include "TP_TrendSignal.mqh"

class CTPSignalManager
{
private:

   CTPTrendSignal m_trendSignal;

public:

   bool Initialize(CTPMarketState &marketState)
   {
      return m_trendSignal.Initialize(marketState);
   }

   void Update()
   {
      m_trendSignal.Update();
   }

   bool Buy() const
   {
      return m_trendSignal.Buy();
   }

   bool Sell() const
   {
      return m_trendSignal.Sell();
   }

   void Shutdown()
   {
      m_trendSignal.Shutdown();
   }

};

#endif