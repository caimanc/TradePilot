#ifndef __TP_TRENDSIGNAL_MQH__
#define __TP_TRENDSIGNAL_MQH__

#include "TP_Signal.mqh"
#include "../MarketState/TP_MarketState.mqh"

//+------------------------------------------------------------------+
//| Señal basada en tendencia                                        |
//+------------------------------------------------------------------+
class CTPTrendSignal : public CTPSignal
{
public:

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

   CTPTrendSignal()
      : CTPSignal()
   {
   }

   //--------------------------------------------------
   // Actualizar
   //--------------------------------------------------

   bool Update(const CTPMarketState &marketState)
   {
      Reset();

      if(marketState.IsBullTrend() &&
         marketState.IsBuySetupValid())
      {
         m_buy = true;
      }

      if(marketState.IsBearTrend() &&
         marketState.IsSellSetupValid())
      {
         m_sell = true;
      }

      return true;
   }

};

#endif