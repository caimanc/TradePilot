#ifndef __TP_ADX_MQH__
#define __TP_ADX_MQH__

#include "TP_Indicator.mqh"

//+------------------------------------------------------------------+
//| ADX                                                              |
//+------------------------------------------------------------------+
class CTPADX : public CTPIndicator
{
private:

   CTPIndicatorBuffer m_adx;
   CTPIndicatorBuffer m_plusDI;
   CTPIndicatorBuffer m_minusDI;

public:

   //--------------------------------------------------
   // Inicialización
   //--------------------------------------------------

   bool Initialize(
      string symbol,
      ENUM_TIMEFRAMES timeframe,
      int period,
      int history=200) override
   {
      m_symbol    = symbol;
      m_timeframe = timeframe;
      m_period    = period;

      m_handle = iADX(
         m_symbol,
         m_timeframe,
         m_period);

      if(m_handle==INVALID_HANDLE)
      {
         Print("ERROR creando ADX.");
         return false;
      }

      if(!m_adx.Initialize(m_handle,0,history))
         return false;

      if(!m_plusDI.Initialize(m_handle,1,history))
         return false;

      if(!m_minusDI.Initialize(m_handle,2,history))
         return false;

      m_initialized=true;

      Print("ADX(",m_period,") inicializado.");

      return true;
   }

   //--------------------------------------------------
   // Actualización
   //--------------------------------------------------

   bool Update() override
   {
      if(!m_initialized)
         return false;

      bool ok=true;

      ok = ok && m_adx.Update();
      ok = ok && m_plusDI.Update();
      ok = ok && m_minusDI.Update();

      return ok;
   }

   //--------------------------------------------------
   // Valor principal
   //--------------------------------------------------

   double Value(int shift=0) const override
   {
      return m_adx.Value(shift);
   }

   double ADX(int shift=0) const
   {
      return m_adx.Value(shift);
   }

   double PlusDI(int shift=0) const
   {
      return m_plusDI.Value(shift);
   }

   double MinusDI(int shift=0) const
   {
      return m_minusDI.Value(shift);
   }

   //--------------------------------------------------
   // Shutdown
   //--------------------------------------------------

   void Shutdown() override
   {
      m_adx.Shutdown();
      m_plusDI.Shutdown();
      m_minusDI.Shutdown();

      CTPIndicator::Shutdown();
   }

};

#endif