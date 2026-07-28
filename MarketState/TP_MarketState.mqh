#ifndef __TP_MARKETSTATE_MQH__
#define __TP_MARKETSTATE_MQH__

//+------------------------------------------------------------------+
//| Estado del mercado                                               |
//+------------------------------------------------------------------+
class CTPMarketState
{
private:

   bool   m_bullTrend;
   bool   m_bearTrend;
   bool   m_range;
   bool   m_highVolatility;

   double m_trendStrength;
   double m_volatility;

public:

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

   CTPMarketState()
   {
      Reset();
   }

   //--------------------------------------------------
   // Reset
   //--------------------------------------------------

   void Reset()
   {
      m_bullTrend      = false;
      m_bearTrend      = false;
      m_range          = true;
      m_highVolatility = false;

      m_trendStrength  = 0.0;
      m_volatility     = 0.0;
   }

   //--------------------------------------------------
   // Actualizar estado del mercado
   //--------------------------------------------------

   bool Update(
      double ema20,
      double ema50,
      double adx,
      double plusDI,
      double minusDI,
      double atr)
   {
      Reset();

      m_trendStrength = adx;
      m_volatility    = atr;

      //--------------------------------------------------
      // Volatilidad
      //--------------------------------------------------

      m_highVolatility = (atr >= 10.0);

      //--------------------------------------------------
      // Mercado lateral
      //--------------------------------------------------

      if(adx < 20.0)
      {
         m_range = true;
         return true;
      }

      //--------------------------------------------------
      // Tendencia alcista
      //--------------------------------------------------

      if(ema20 > ema50 &&
         plusDI > minusDI)
      {
         m_bullTrend = true;
         m_range     = false;
      }

      //--------------------------------------------------
      // Tendencia bajista
      //--------------------------------------------------

      if(ema20 < ema50 &&
         minusDI > plusDI)
      {
         m_bearTrend = true;
         m_range     = false;
      }

      return true;
   }

   //--------------------------------------------------
   // Getters
   //--------------------------------------------------

   bool IsBullTrend() const
   {
      return m_bullTrend;
   }

   bool IsBearTrend() const
   {
      return m_bearTrend;
   }

   bool IsRange() const
   {
      return m_range;
   }

   bool IsHighVolatility() const
   {
      return m_highVolatility;
   }

   double TrendStrength() const
   {
      return m_trendStrength;
   }

   double Volatility() const
   {
      return m_volatility;
   }

};

#endif