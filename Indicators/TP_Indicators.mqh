#ifndef __TP_INDICATORS_MQH__
#define __TP_INDICATORS_MQH__

#include "TP_EMA.mqh"
#include "TP_ATR.mqh"
#include "TP_ADX.mqh"

//+------------------------------------------------------------------+
//| Contenedor de indicadores                                        |
//+------------------------------------------------------------------+
class CTPIndicators
{
private:

   string            m_symbol;
   ENUM_TIMEFRAMES   m_timeframe;

   CTPEMA            m_ema20;
   CTPEMA            m_ema50;
   CTPATR            m_atr14;
   CTPADX            m_adx14;

public:

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

   CTPIndicators()
   {
      m_symbol    = "";
      m_timeframe = PERIOD_CURRENT;
   }

   //--------------------------------------------------
   // Inicializar
   //--------------------------------------------------

   bool Initialize(
      string symbol,
      ENUM_TIMEFRAMES timeframe)
   {
      m_symbol    = symbol;
      m_timeframe = timeframe;

      if(!m_ema20.Initialize(symbol,timeframe,20))
         return false;

      if(!m_ema50.Initialize(symbol,timeframe,50))
         return false;

      if(!m_atr14.Initialize(symbol,timeframe,14))
         return false;

      if(!m_adx14.Initialize(symbol,timeframe,14))
         return false;

      Print("Indicators inicializado.");

      return true;
   }

   //--------------------------------------------------
   // Actualizar
   //--------------------------------------------------

   bool Update()
   {
      bool ok=true;

      ok &= m_ema20.Update();
      ok &= m_ema50.Update();
      ok &= m_atr14.Update();
      ok &= m_adx14.Update();

      return ok;
   }

   //--------------------------------------------------
   // Shutdown
   //--------------------------------------------------

   void Shutdown()
   {
      m_ema20.Shutdown();
      m_ema50.Shutdown();
      m_atr14.Shutdown();
      m_adx14.Shutdown();
   }

   //--------------------------------------------------
   // EMA
   //--------------------------------------------------

   double EMA20() const
   {
      return m_ema20.Value();
   }

   double EMA50() const
   {
      return m_ema50.Value();
   }

   //--------------------------------------------------
   // ATR
   //--------------------------------------------------

   double ATR() const
   {
      return m_atr14.Value();
   }

   //--------------------------------------------------
   // ADX
   //--------------------------------------------------

   double ADX() const
   {
      return m_adx14.ADX();
   }

   double PlusDI() const
   {
      return m_adx14.PlusDI();
   }

   double MinusDI() const
   {
      return m_adx14.MinusDI();
   }

};

#endif