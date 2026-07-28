#ifndef __TP_EMA_MQH__
#define __TP_EMA_MQH__

#include "TP_Indicator.mqh"

//+------------------------------------------------------------------+
//| EMA                                                              |
//+------------------------------------------------------------------+
class CTPEMA : public CTPIndicator
{
private:

   CTPIndicatorBuffer m_buffer;

public:

   bool Initialize(
      string symbol,
      ENUM_TIMEFRAMES timeframe,
      int period,
      int history=200) override
   {
      m_symbol=symbol;
      m_timeframe=timeframe;
      m_period=period;

      m_handle=iMA(
         m_symbol,
         m_timeframe,
         m_period,
         0,
         MODE_EMA,
         PRICE_CLOSE);

      if(m_handle==INVALID_HANDLE)
      {
         Print("ERROR creando EMA(",m_period,")");
         return false;
      }

      if(!m_buffer.Initialize(
            m_handle,
            0,
            history))
      {
         Print("ERROR inicializando buffer EMA.");
         return false;
      }

      m_initialized=true;

      Print("EMA(",m_period,") inicializada.");

      return true;
   }

   //--------------------------------------------------

   bool Update() override
   {
      if(!m_initialized)
         return false;

      return m_buffer.Update();
   }

   //--------------------------------------------------

   double Value(int shift=0) const override
   {
      return m_buffer.Value(shift);
   }

   //--------------------------------------------------

   void Shutdown() override
   {
      m_buffer.Shutdown();

      CTPIndicator::Shutdown();
   }

};

#endif