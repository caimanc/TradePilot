#ifndef __TP_MARKET_MQH__
#define __TP_MARKET_MQH__

//+------------------------------------------------------------------+
//| Información del mercado                                          |
//+------------------------------------------------------------------+
class CTPMarket
{
private:

   string            m_symbol;
   ENUM_TIMEFRAMES   m_timeframe;

   double            m_bid;
   double            m_ask;
   double            m_spread;

   datetime          m_lastBarTime;

public:

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

   CTPMarket()
   {
      m_symbol      = _Symbol;
      m_timeframe   = PERIOD_CURRENT;

      m_bid         = 0.0;
      m_ask         = 0.0;
      m_spread      = 0.0;

      m_lastBarTime = 0;
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

      Update();

      Print("Market inicializado.");

      return true;
   }

   //--------------------------------------------------
   // Actualizar datos
   //--------------------------------------------------

   bool Update()
   {
      m_bid = SymbolInfoDouble(m_symbol,SYMBOL_BID);
      m_ask = SymbolInfoDouble(m_symbol,SYMBOL_ASK);

      m_spread =
         (m_ask-m_bid)/
         SymbolInfoDouble(m_symbol,SYMBOL_POINT);

      m_lastBarTime =
         iTime(
            m_symbol,
            m_timeframe,
            0);

      return true;
   }

   //--------------------------------------------------
   // Nueva vela
   //--------------------------------------------------

   bool IsNewBar()
   {
      static datetime previousBar=0;

      if(m_lastBarTime!=previousBar)
      {
         previousBar=m_lastBarTime;
         return true;
      }

      return false;
   }

   //--------------------------------------------------
   // Getters
   //--------------------------------------------------

   string Symbol() const
   {
      return m_symbol;
   }

   ENUM_TIMEFRAMES Timeframe() const
   {
      return m_timeframe;
   }

   double Bid() const
   {
      return m_bid;
   }

   double Ask() const
   {
      return m_ask;
   }

   double Spread() const
   {
      return m_spread;
   }

   datetime LastBar() const
   {
      return m_lastBarTime;
   }

};

#endif