#ifndef __TP_TRENDSIGNAL_MQH__
#define __TP_TRENDSIGNAL_MQH__

#include "TP_Signal.mqh"
#include "../MarketState/TP_MarketState.mqh"

//+------------------------------------------------------------------+
//| Señal basada en la tendencia del mercado                         |
//+------------------------------------------------------------------+
class CTPTrendSignal : public CTPSignal
{
private:

   CTPMarketState *m_marketState;

public:

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

   CTPTrendSignal()
   {
      m_marketState = NULL;
   }

   //--------------------------------------------------
   // Inicialización
   //--------------------------------------------------

   bool Initialize(CTPMarketState &marketState)
   {
      m_marketState = &marketState;

      Print("TrendSignal inicializado.");

      return true;
   }

   //--------------------------------------------------
   // Actualización
   //--------------------------------------------------

   void Update() override
   {
      Reset();

      if(m_marketState == NULL)
         return;

      if(m_marketState.IsBullTrend())
         m_buy = true;
      else
      if(m_marketState.IsBearTrend())
         m_sell = true;
   }

   //--------------------------------------------------
   // Finalización
   //--------------------------------------------------

   void Shutdown()
   {
      Print("TrendSignal detenido.");
   }
};

#endif