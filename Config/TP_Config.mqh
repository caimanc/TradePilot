#ifndef __TP_CONFIG_MQH__
#define __TP_CONFIG_MQH__

//+------------------------------------------------------------------+
//| Configuración global del Expert                                 |
//+------------------------------------------------------------------+
class CTPConfig
{
private:

   string            m_symbol;
   ENUM_TIMEFRAMES   m_timeframe;

   long              m_magicNumber;

   double            m_riskPercent;

public:

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

   CTPConfig()
   {
      m_symbol       = _Symbol;
      m_timeframe    = PERIOD_CURRENT;

      m_magicNumber  = 20260724;

      m_riskPercent  = 1.0;
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

   long MagicNumber() const
   {
      return m_magicNumber;
   }

   double RiskPercent() const
   {
      return m_riskPercent;
   }

   //--------------------------------------------------
   // Setters
   //--------------------------------------------------

   void SetSymbol(string symbol)
   {
      m_symbol = symbol;
   }

   void SetTimeframe(ENUM_TIMEFRAMES tf)
   {
      m_timeframe = tf;
   }

   void SetMagicNumber(long magic)
   {
      m_magicNumber = magic;
   }

   void SetRiskPercent(double risk)
   {
      m_riskPercent = risk;
   }
};

#endif