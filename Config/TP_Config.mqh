#ifndef __TP_CONFIG_MQH__
#define __TP_CONFIG_MQH__

class CTPConfig
{
private:

   string            m_symbol;
   ENUM_TIMEFRAMES   m_timeframe;
   double            m_risk;
   long              m_magic;

public:

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

   CTPConfig()
      : m_symbol(_Symbol),
        m_timeframe(PERIOD_CURRENT),
        m_risk(1.0),
        m_magic(2026001)
   {
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

   double RiskPercent() const
   {
      return m_risk;
   }

   long MagicNumber() const
   {
      return m_magic;
   }

};

#endif