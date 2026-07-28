#ifndef __TP_CORE_MQH__
#define __TP_CORE_MQH__

#include "../Config/TP_Config.mqh"
#include "../Market/TP_Market.mqh"
#include "../Indicators/TP_Indicators.mqh"
#include "../MarketState/TP_MarketState.mqh"
#include "../Signals/TP_SignalManager.mqh"
#include "../Execution/TP_TradeManager.mqh"
#include "../Risk/TP_RiskManager.mqh"

//+------------------------------------------------------------------+
//| Núcleo principal                                                 |
//+------------------------------------------------------------------+
class CTPCore
{
private:

   bool m_initialized;

   //--------------------------------------------------
   // Módulos
   //--------------------------------------------------

   CTPConfig        m_config;
   CTPMarket        m_market;
   CTPIndicators    m_indicators;
   CTPMarketState   m_marketState;
   CTPSignalManager m_signalManager;
   CTPRiskManager   m_riskManager;
   CTPTradeManager  m_tradeManager;

public:

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

   CTPCore()
   {
      m_initialized = false;
   }

   //--------------------------------------------------
   // Inicialización
   //--------------------------------------------------

   bool Initialize()
   {
      Print("====================================");
      Print("Inicializando TradePilot...");
      Print("====================================");

      if(!m_market.Initialize(
            m_config.Symbol(),
            m_config.Timeframe()))
         return false;

      if(!m_indicators.Initialize(
            m_config.Symbol(),
            m_config.Timeframe()))
         return false;

      if(!m_riskManager.Initialize())
         return false;

      if(!m_tradeManager.Initialize(
            m_config.MagicNumber()))
         return false;

      m_initialized = true;

      Print("TradePilot inicializado correctamente.");

      return true;
   }

   //--------------------------------------------------
   // Actualización
   //--------------------------------------------------

   void Update()
   {
      if(!m_initialized)
         return;

      m_market.Update();

      if(!m_market.IsNewBar())
         return;

      if(!m_indicators.Update())
         return;

      m_marketState.Update(
         m_indicators.EMA20(),
         m_indicators.EMA50(),
         m_indicators.ADX(),
         m_indicators.PlusDI(),
         m_indicators.MinusDI(),
         m_indicators.ATR());

      m_signalManager.Update(
         m_marketState);

      m_riskManager.Update();

      m_tradeManager.Update(
         m_signalManager,m_riskManager);

      Print("------------------------------------");
      Print("EMA20 : ",DoubleToString(m_indicators.EMA20(),5));
      Print("EMA50 : ",DoubleToString(m_indicators.EMA50(),5));
      Print("ADX   : ",DoubleToString(m_indicators.ADX(),2));
      Print("ATR   : ",DoubleToString(m_indicators.ATR(),5));
      Print("Bull  : ",m_marketState.IsBullTrend());
      Print("Bear  : ",m_marketState.IsBearTrend());
      Print("BUY   : ",m_signalManager.Buy());
      Print("SELL  : ",m_signalManager.Sell());
      Print("------------------------------------");
   }

   //--------------------------------------------------
   // Finalización
   //--------------------------------------------------

   void Shutdown()
   {
      if(!m_initialized)
         return;

      Print("====================================");
      Print("Cerrando TradePilot...");
      Print("====================================");

      m_tradeManager.Shutdown();
      m_riskManager.Shutdown();
      m_indicators.Shutdown();

      m_initialized = false;

      Print("TradePilot detenido.");
   }

   //--------------------------------------------------
   // Estado
   //--------------------------------------------------

   bool IsInitialized() const
   {
      return m_initialized;
   }

};

#endif
