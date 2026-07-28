#ifndef __TP_PRICESERIES_MQH__
#define __TP_PRICESERIES_MQH__

//+------------------------------------------------------------------+
//| Serie de precios                                                 |
//+------------------------------------------------------------------+
class CTPPriceSeries
{
private:

   string            m_symbol;
   ENUM_TIMEFRAMES   m_timeframe;

   int               m_history;

   MqlRates          m_rates[];

public:

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

   CTPPriceSeries()
   {
      m_symbol = "";
      m_timeframe = PERIOD_CURRENT;
      m_history = 500;
   }

   //--------------------------------------------------
   // Inicialización
   //--------------------------------------------------

   bool Initialize(
      string symbol,
      ENUM_TIMEFRAMES timeframe,
      int history=500)
   {
      m_symbol = symbol;
      m_timeframe = timeframe;
      m_history = history;

      ArraySetAsSeries(m_rates,true);

      Print("PriceSeries inicializada.");

      return true;
   }

   //--------------------------------------------------
   // Actualizar datos
   //--------------------------------------------------

   bool Update()
   {
      int copied =
         CopyRates(
            m_symbol,
            m_timeframe,
            0,
            m_history,
            m_rates);

      if(copied<=0)
         return false;

      return true;
   }

   //--------------------------------------------------
   // OHLC
   //--------------------------------------------------

   double Open(int shift) const
   {
      return m_rates[shift].open;
   }

   double High(int shift) const
   {
      return m_rates[shift].high;
   }

   double Low(int shift) const
   {
      return m_rates[shift].low;
   }

   double Close(int shift) const
   {
      return m_rates[shift].close;
   }

   //--------------------------------------------------
   // Tiempo
   //--------------------------------------------------

   datetime Time(int shift) const
   {
      return m_rates[shift].time;
   }

   //--------------------------------------------------
   // Volumen
   //--------------------------------------------------

   long TickVolume(int shift) const
   {
      return m_rates[shift].tick_volume;
   }

   //--------------------------------------------------
   // Spread
   //--------------------------------------------------

   int Spread(int shift) const
   {
      return m_rates[shift].spread;
   }

   //--------------------------------------------------
   // Cantidad de velas cargadas
   //--------------------------------------------------

   int Bars() const
   {
      return ArraySize(m_rates);
   }

   //--------------------------------------------------
   // Shutdown
   //--------------------------------------------------

   void Shutdown()
   {
      ArrayFree(m_rates);

      Print("PriceSeries detenida.");
   }

};

#endif