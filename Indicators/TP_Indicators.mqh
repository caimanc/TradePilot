#ifndef __TP_INDICATORS_MQH__
#define __TP_INDICATORS_MQH__

#include "TP_EMA.mqh"
#include "TP_ATR.mqh"
#include "TP_ADX.mqh"

class CTPIndicators
{
private:

   //--------------------------------------------------
   // Configuración
   //--------------------------------------------------

   string            m_symbol;
   ENUM_TIMEFRAMES   m_timeframe;

   //--------------------------------------------------
   // Indicadores
   //--------------------------------------------------

   CTPEMA            m_ema20;
   CTPEMA            m_ema50;

   CTPATR            m_atr;

   CTPADX            m_adx;

public:

   CTPIndicators()
   {
      m_symbol="";
      m_timeframe=PERIOD_CURRENT;
   }

   //--------------------------------------------------
   // Inicialización
   //--------------------------------------------------

   bool Initialize(
      string symbol,
      ENUM_TIMEFRAMES timeframe)
   {
      Print("--------------------------------------");
      Print("Inicializando Indicators...");
      Print("--------------------------------------");

      m_symbol=symbol;
      m_timeframe=timeframe;

      //--------------------------------------------------
      // EMA20
      //--------------------------------------------------

      if(!m_ema20.Initialize(
            m_symbol,
            m_timeframe,
            20))
         return false;

      //--------------------------------------------------
      // EMA50
      //--------------------------------------------------

      if(!m_ema50.Initialize(
            m_symbol,
            m_timeframe,
            50))
         return false;

      //--------------------------------------------------
      // ATR14
      //--------------------------------------------------

      if(!m_atr.Initialize(
            m_symbol,
            m_timeframe,
            14))
         return false;

      //--------------------------------------------------
      // ADX14
      //--------------------------------------------------

      if(!m_adx.Initialize(
            m_symbol,
            m_timeframe,
            14))
         return false;

      Print("Indicators inicializado correctamente.");

      return true;
   }

   //--------------------------------------------------
   // Update
   //--------------------------------------------------

   void Update()
   {
      m_ema20.Update();
      m_ema50.Update();

      m_atr.Update();

      m_adx.Update();
   }

   //--------------------------------------------------
   // Shutdown
   //--------------------------------------------------

   void Shutdown()
   {
      m_ema20.Shutdown();
      m_ema50.Shutdown();

      m_atr.Shutdown();

      m_adx.Shutdown();

      Print("Indicators detenido.");
   }

   //--------------------------------------------------
   // EMA
   //--------------------------------------------------

   double EMA20(int shift=0)
   {
      return m_ema20.Value(shift);
   }

   double EMA50(int shift=0)
   {
      return m_ema50.Value(shift);
   }

   //--------------------------------------------------
   // ATR
   //--------------------------------------------------

   double ATR(int shift=0)
   {
      return m_atr.Value(shift);
   }

   //--------------------------------------------------
   // ADX
   //--------------------------------------------------

   double ADX(int shift=0)
   {
      return m_adx.ADX(shift);
   }

   double PlusDI(int shift=0)
   {
      return m_adx.PlusDI(shift);
   }

   double MinusDI(int shift=0)
   {
      return m_adx.MinusDI(shift);
   }

};

#endif