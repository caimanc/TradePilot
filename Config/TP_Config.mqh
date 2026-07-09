#ifndef __TP_CONFIG_MQH__
#define __TP_CONFIG_MQH__

//==================================================
// TradePilot
// Configuración Global
//==================================================

class CTPConfig
{
private:

   //--------------------------------------------------
   // Mercado
   //--------------------------------------------------

   string            m_symbol;
   ENUM_TIMEFRAMES   m_timeframe;

   //--------------------------------------------------
   // Trading
   //--------------------------------------------------

   double            m_riskPercent;
   long              m_magicNumber;

   //--------------------------------------------------
   // Broker
   //--------------------------------------------------

   int               m_brokerUtcOffset;

   //--------------------------------------------------
   // Sesiones habilitadas
   //--------------------------------------------------

   bool              m_tradeSydney;
   bool              m_tradeTokyo;
   bool              m_tradeLondon;
   bool              m_tradeNewYork;

public:

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

   CTPConfig()
   {
      //-----------------------------
      // Mercado
      //-----------------------------

      m_symbol      = _Symbol;
      m_timeframe   = PERIOD_CURRENT;

      //-----------------------------
      // Trading
      //-----------------------------

      m_riskPercent = 1.0;
      m_magicNumber = 2026001;

      //-----------------------------
      // Broker
      //-----------------------------

      m_brokerUtcOffset = 0;

      //-----------------------------
      // Sesiones
      //-----------------------------

      m_tradeSydney  = false;
      m_tradeTokyo   = false;
      m_tradeLondon  = true;
      m_tradeNewYork = true;
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
      return m_riskPercent;
   }

   long MagicNumber() const
   {
      return m_magicNumber;
   }

   int BrokerUtcOffset() const
   {
      return m_brokerUtcOffset;
   }

   bool TradeSydney() const
   {
      return m_tradeSydney;
   }

   bool TradeTokyo() const
   {
      return m_tradeTokyo;
   }

   bool TradeLondon() const
   {
      return m_tradeLondon;
   }

   bool TradeNewYork() const
   {
      return m_tradeNewYork;
   }

};

#endif