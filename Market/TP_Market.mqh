#ifndef __TP_MARKET_MQH__
#define __TP_MARKET_MQH__

class CTPMarket
{
private:

   //--------------------------------------------------
   // Configuración
   //--------------------------------------------------

   string            m_symbol;
   ENUM_TIMEFRAMES   m_timeframe;

   //--------------------------------------------------
   // Estado
   //--------------------------------------------------

   datetime          m_lastBarTime;

public:

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

   CTPMarket()
   {
      m_symbol      = "";
      m_timeframe   = PERIOD_CURRENT;
      m_lastBarTime = 0;
   }

   //--------------------------------------------------
   // Inicialización
   //--------------------------------------------------

   bool Initialize(string symbol,
                   ENUM_TIMEFRAMES timeframe)
   {
      Print("--------------------------------------");
      Print("Inicializando módulo Market...");
      Print("--------------------------------------");

      m_symbol = symbol;

      if(timeframe == PERIOD_CURRENT)
         m_timeframe = (ENUM_TIMEFRAMES)_Period;
      else
         m_timeframe = timeframe;

      m_lastBarTime = iTime(m_symbol,m_timeframe,0);

      Print("Símbolo      : ",m_symbol);
      Print("TimeFrame    : ",EnumToString(m_timeframe));
      Print("Bid          : ",DoubleToString(Bid(),Digits()));
      Print("Ask          : ",DoubleToString(Ask(),Digits()));
      Print("Spread       : ",DoubleToString(Spread(),Digits()));

      Print("Market inicializado correctamente.");

      return true;
   }

   //--------------------------------------------------
   // Update
   //--------------------------------------------------

   void Update()
   {

   }

   //--------------------------------------------------
   // Shutdown
   //--------------------------------------------------

   void Shutdown()
   {
      Print("Market detenido.");
   }

   //--------------------------------------------------
   // Información símbolo
   //--------------------------------------------------

   string Symbol() const
   {
      return m_symbol;
   }

   ENUM_TIMEFRAMES Timeframe() const
   {
      return m_timeframe;
   }

   //--------------------------------------------------
   // Tick actual
   //--------------------------------------------------

   double Bid() const
   {
      return SymbolInfoDouble(m_symbol,SYMBOL_BID);
   }

   double Ask() const
   {
      return SymbolInfoDouble(m_symbol,SYMBOL_ASK);
   }

   double Spread() const
   {
      return Ask()-Bid();
   }

   double Point() const
   {
      return SymbolInfoDouble(m_symbol,SYMBOL_POINT);
   }

   int Digits() const
   {
      return (int)SymbolInfoInteger(m_symbol,SYMBOL_DIGITS);
   }

   //--------------------------------------------------
   // OHLC
   //--------------------------------------------------

   double Open(int shift) const
   {
      return iOpen(m_symbol,m_timeframe,shift);
   }

   double High(int shift) const
   {
      return iHigh(m_symbol,m_timeframe,shift);
   }

   double Low(int shift) const
   {
      return iLow(m_symbol,m_timeframe,shift);
   }

   double Close(int shift) const
   {
      return iClose(m_symbol,m_timeframe,shift);
   }

   long Volume(int shift) const
   {
      return iVolume(m_symbol,m_timeframe,shift);
   }

   datetime Time(int shift) const
   {
      return iTime(m_symbol,m_timeframe,shift);
   }

   //--------------------------------------------------
   // Nueva vela
   //--------------------------------------------------

   bool IsNewBar()
   {
      datetime currentBar = iTime(m_symbol,m_timeframe,0);

      if(currentBar != m_lastBarTime)
      {
         m_lastBarTime = currentBar;
         return true;
      }

      return false;
   }

};

#endif