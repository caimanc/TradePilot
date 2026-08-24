#ifndef __TP_HTFCONTEXT_MQH__
#define __TP_HTFCONTEXT_MQH__

#include "../Indicators/TP_Indicators.mqh"

//+------------------------------------------------------------------+
//| Contexto de temporalidad superior                                |
//+------------------------------------------------------------------+
class CTPHTFContext
{
private:

   string          m_symbol;

   ENUM_TIMEFRAMES m_htf;

   CTPIndicators   m_indicators;

   datetime        m_lastBarTime;

   bool            m_bull;
   bool            m_bear;

public:

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

   CTPHTFContext()
   {
      m_symbol      = "";
      m_htf         = PERIOD_CURRENT;
      m_lastBarTime = 0;
      m_bull        = false;
      m_bear        = false;
   }

   //--------------------------------------------------
   // Inicializar
   //--------------------------------------------------

   bool Initialize(
      string          symbol,
      ENUM_TIMEFRAMES htf)
   {
      m_symbol = symbol;
      m_htf    = htf;

      m_lastBarTime = 0;

      m_bull = false;
      m_bear = false;

      if(!m_indicators.Initialize(symbol, htf))
         return false;

      Print("HTF Context inicializado.");

      Print(
         "HTF Timeframe   : ",
         EnumToString(htf)
      );

      return true;
   }

   //--------------------------------------------------
   // Actualizar (una vez por barra HTF)
   //--------------------------------------------------

   bool Update()
   {
      datetime barTime =
         iTime(m_symbol, m_htf, 0);

      //--------------------------------------------------
      // Datos HTF aun no disponibles
      //--------------------------------------------------

      if(barTime == 0)
         return true;

      if(barTime == m_lastBarTime)
         return true;

      if(!m_indicators.Update())
         return false;

      double ema20   = m_indicators.EMA20();
      double ema50   = m_indicators.EMA50();
      double adx     = m_indicators.ADX();
      double plusDI  = m_indicators.PlusDI();
      double minusDI = m_indicators.MinusDI();

      bool bullAntes = m_bull;
      bool bearAntes = m_bear;

      //--------------------------------------------------
      // Misma semantica de tendencia que MarketState
      //--------------------------------------------------

      m_bull = ema20 > ema50 &&
               plusDI > minusDI &&
               adx >= 20.0;

      m_bear = ema20 < ema50 &&
               minusDI > plusDI &&
               adx >= 20.0;

      //--------------------------------------------------
      // Log solo cuando cambia el veredicto
      //--------------------------------------------------

      if(m_bull != bullAntes ||
         m_bear != bearAntes)
      {
         if(m_bull)
            Print("HTF Context : BULL");

         else if(m_bear)
            Print("HTF Context : BEAR");

         else
            Print("HTF Context : NEUTRAL");
      }

      m_lastBarTime = barTime;

      return true;
   }

   //--------------------------------------------------
   // Shutdown
   //--------------------------------------------------

   void Shutdown()
   {
      m_indicators.Shutdown();
   }

   //--------------------------------------------------
   // Getters
   //--------------------------------------------------

   bool IsBull() const
   {
      return m_bull;
   }

   bool IsBear() const
   {
      return m_bear;
   }

};

//+------------------------------------------------------------------+
//| Temporalidad superior segun grafico                              |
//+------------------------------------------------------------------+
ENUM_TIMEFRAMES ObtenerHTF(ENUM_TIMEFRAMES timeframe)
{
   if(timeframe >= PERIOD_D1)
      return PERIOD_W1;

   if(timeframe >= PERIOD_H4)
      return PERIOD_D1;

   if(timeframe >= PERIOD_H1)
      return PERIOD_H4;

   if(timeframe >= PERIOD_M15)
      return PERIOD_H1;

   if(timeframe >= PERIOD_M5)
      return PERIOD_M30;

   return PERIOD_M15;
}

#endif
