//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#ifndef __TP_MARKETSTATE_MQH__
#define __TP_MARKETSTATE_MQH__

#include "../Indicators/TP_Indicators.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CTPMarketState
  {
private:

   //--------------------------------------------------
   // Dependencias
   //--------------------------------------------------

   CTPIndicators     *m_indicators;

   //--------------------------------------------------
   // Estado del mercado
   //--------------------------------------------------

   bool              m_bullTrend;
   bool              m_bearTrend;
   bool              m_range;

   bool              m_highVolatility;

   double            m_trendStrength;
   double            m_volatility;

public:

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

                     CTPMarketState()
     {
      m_indicators = NULL;

      m_bullTrend = false;
      m_bearTrend = false;
      m_range = true;

      m_highVolatility = false;

      m_trendStrength = 0.0;
      m_volatility = 0.0;
     }

   //--------------------------------------------------
   // Inicialización
   //--------------------------------------------------

   bool              Initialize(CTPIndicators &indicators)
     {
      m_indicators = &indicators;

      Print("MarketState inicializado.");

      return true;
     }

   //--------------------------------------------------
   // Actualización
   //--------------------------------------------------

   void              Update()
     {
      if(m_indicators == NULL)
         return;

      m_trendStrength = m_indicators.ADX();
      m_volatility    = m_indicators.ATR();

      m_bullTrend = false;
      m_bearTrend = false;
      m_range     = false;

      //--------------------------------------------------
      // Mercado lateral
      //--------------------------------------------------

      if(m_trendStrength < 20)
        {
         m_range = true;
         return;
        }

      //--------------------------------------------------
      // Tendencia alcista
      //--------------------------------------------------

      if(m_indicators.EMA20() > m_indicators.EMA50() &&
         m_indicators.PlusDI() > m_indicators.MinusDI())
        {
         m_bullTrend = true;
        }

      //--------------------------------------------------
      // Tendencia bajista
      //--------------------------------------------------

      if(m_indicators.EMA20() < m_indicators.EMA50() &&
         m_indicators.MinusDI() > m_indicators.PlusDI())
        {
         m_bearTrend = true;
        }

      //--------------------------------------------------
      // Volatilidad
      //--------------------------------------------------

      m_highVolatility = (m_volatility >= 10.0);
     }

   //--------------------------------------------------
   // Shutdown
   //--------------------------------------------------

   void              Shutdown()
     {
      Print("MarketState detenido.");
     }

   //--------------------------------------------------
   // Getters
   //--------------------------------------------------

   bool              IsBullTrend() const
     {
      return m_bullTrend;
     }

   bool              IsBearTrend() const
     {
      return m_bearTrend;
     }

   bool              IsRange() const
     {
      return m_range;
     }

   bool              IsHighVolatility() const
     {
      return m_highVolatility;
     }

   double            TrendStrength() const
     {
      return m_trendStrength;
     }

   double            Volatility() const
     {
      return m_volatility;
     }

  };

#endif
//+------------------------------------------------------------------+
