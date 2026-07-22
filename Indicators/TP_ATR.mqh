//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#ifndef __TP_ATR_MQH__
#define __TP_ATR_MQH__

#include "TP_Indicator.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CTPATR : public CTPIndicator
  {
private:

   CTPIndicatorBuffer m_buffer;

public:

   bool              Initialize(
      string symbol,
      ENUM_TIMEFRAMES timeframe,
      int period,
      int history=200) override
     {
      m_symbol    = symbol;
      m_timeframe = timeframe;
      m_period    = period;

      m_handle = iATR(
                    m_symbol,
                    m_timeframe,
                    m_period);

      if(m_handle==INVALID_HANDLE)
        {
         Print("ERROR creando ATR.");
         return false;
        }

      if(!m_buffer.Initialize(
            m_handle,
            0,
            history))
        {
         Print("ERROR inicializando buffer ATR.");
         return false;
        }

      m_initialized=true;

      Print("ATR(",m_period,") inicializado.");

      return true;
     }

   //--------------------------------------------------
   // Actualizar
   //--------------------------------------------------

   bool              Update() override
     {
      if(!m_initialized)
         return false;

      return m_buffer.Update();
     }
   double            Value(int shift=0) const override
     {
      return m_buffer.Value(shift);
     }

   void              Shutdown() override
     {
      m_buffer.Shutdown();
      CTPIndicator::Shutdown();
     }

  };

#endif
//+------------------------------------------------------------------+
