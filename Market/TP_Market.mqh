#ifndef __TP_MARKET_MQH__
#define __TP_MARKET_MQH__

#include "../Config/TP_Config.mqh"

class CTPMarket
{
private:

   //--------------------------------------------------
   // Información del mercado
   //--------------------------------------------------

   string            m_symbol;
   ENUM_TIMEFRAMES   m_timeframe;

   double            m_bid;
   double            m_ask;
   double            m_point;
   double            m_spread;

   int               m_digits;

public:

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

   CTPMarket()
      : m_symbol(""),
        m_timeframe(PERIOD_CURRENT),
        m_bid(0.0),
        m_ask(0.0),
        m_point(0.0),
        m_spread(0.0),
        m_digits(0)
   {
   }

   //--------------------------------------------------
   // Inicialización
   //--------------------------------------------------

   bool Initialize(const CTPConfig &config)
   {
      Print("--------------------------------------");
      Print("Inicializando módulo Market...");

      m_symbol = config.Symbol();

      if(config.Timeframe()==PERIOD_CURRENT)
         m_timeframe=(ENUM_TIMEFRAMES)_Period;
      else
         m_timeframe=config.Timeframe();

      m_bid     = SymbolInfoDouble(m_symbol,SYMBOL_BID);
      m_ask     = SymbolInfoDouble(m_symbol,SYMBOL_ASK);

      m_point   = SymbolInfoDouble(m_symbol,SYMBOL_POINT);

      m_digits  = (int)SymbolInfoInteger(m_symbol,SYMBOL_DIGITS);

      m_spread  = SymbolInfoInteger(m_symbol,SYMBOL_SPREAD) * m_point;

      Print("Símbolo      : ",m_symbol);
      Print("TimeFrame    : ",EnumToString(m_timeframe));
      Print("Bid          : ",DoubleToString(m_bid,m_digits));
      Print("Ask          : ",DoubleToString(m_ask,m_digits));
      Print("Spread       : ",DoubleToString(m_spread,m_digits));

      Print("Market inicializado correctamente.");
      Print("--------------------------------------");

      return true;
   }

   //--------------------------------------------------
   // Actualización
   //--------------------------------------------------

   void Update()
   {
      m_bid = SymbolInfoDouble(m_symbol,SYMBOL_BID);

      m_ask = SymbolInfoDouble(m_symbol,SYMBOL_ASK);

      m_spread =
         SymbolInfoInteger(m_symbol,SYMBOL_SPREAD) *
         m_point;
   }

   //--------------------------------------------------
   // Finalización
   //--------------------------------------------------

   void Shutdown()
   {
      Print("Finalizando módulo Market...");
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

   double Point() const
   {
      return m_point;
   }

   int Digits() const
   {
      return m_digits;
   }

};

#endif