//+------------------------------------------------------------------+
//|                                                      TradePilot  |
//+------------------------------------------------------------------+
#ifndef __TP_CORE_MQH__
#define __TP_CORE_MQH__

#include "../Config/TP_Config.mqh"
#include "../Market/TP_Market.mqh"
#include "../Sessions/TP_Sessions.mqh"
#include "../Indicators/TP_Indicators.mqh"
#include "../MarketState/TP_MarketState.mqh"
#include "../Signals/TP_SignalManager.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CTPCore
  {
private:

   //--------------------------------------------------
   // Estado
   //--------------------------------------------------

   bool              m_initialized;

   //--------------------------------------------------
   // Módulos
   //--------------------------------------------------

   CTPConfig         m_config;
   CTPMarket         m_market;
   CTPSessions       m_sessions;
   CTPIndicators     m_indicators;
   CTPMarketState    m_marketState;
   CTPSignalManager  m_signalManager;

public:

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

                     CTPCore()
     {
      m_initialized = false;
     }

   //--------------------------------------------------
   // Destructor
   //--------------------------------------------------

                    ~CTPCore()
     {
      Shutdown();
     }

   //--------------------------------------------------
   // Inicialización
   //--------------------------------------------------

   bool              Initialize()
     {
      Print("");
      Print("======================================");
      Print("TradePilot Core");
      Print("Inicializando núcleo...");
      Print("======================================");

      //--------------------------------------------------
      // Configuración
      //--------------------------------------------------

      Print("");
      Print("Configuración");

      Print("Símbolo      : ", m_config.Symbol());
      Print("TimeFrame    : ", EnumToString(m_config.Timeframe()));
      Print("Riesgo       : ", DoubleToString(m_config.RiskPercent(),2), "%");
      Print("MagicNumber  : ", m_config.MagicNumber());

      //--------------------------------------------------
      // Market
      //--------------------------------------------------

      if(!m_market.Initialize(
            m_config.Symbol(),
            m_config.Timeframe()))
        {
         Print("ERROR inicializando Market.");
         return false;
        }

      //--------------------------------------------------
      // Sessions
      //--------------------------------------------------

      if(!m_sessions.Initialize(
            m_config.BrokerUtcOffset(),
            m_config.TradeSydney(),
            m_config.TradeTokyo(),
            m_config.TradeLondon(),
            m_config.TradeNewYork()))
        {
         Print("ERROR inicializando Sessions.");
         return false;
        }

      //--------------------------------------------------
      // Indicators
      //--------------------------------------------------

      if(!m_indicators.Initialize(
            m_config.Symbol(),
            m_config.Timeframe()))
        {
         Print("ERROR inicializando Indicators.");
         return false;
        }

      //--------------------------------------------------
      // MarketState
      //--------------------------------------------------

      if(!m_marketState.Initialize(m_indicators))
        {
         Print("ERROR inicializando MarketState.");
         return false;
        }

      //--------------------------------------------------
      // SignalManager
      //--------------------------------------------------

      if(!m_signalManager.Initialize(m_marketState))
        {
         Print("ERROR inicializando SignalManager.");
         return false;
        }

      m_initialized = true;

      Print("");
      Print("Core inicializado correctamente.");
      Print("======================================");

      return true;
     }

   //--------------------------------------------------
   // Actualización
   //--------------------------------------------------

   void              Update()
     {
      if(!m_initialized)
         return;

      //--------------------------------------------------
      // Actualizar módulos
      //--------------------------------------------------

      m_market.Update();
      m_sessions.Update();
      m_indicators.Update();
      m_marketState.Update();
      m_signalManager.Update();

      //--------------------------------------------------
      // Mostrar una vez por vela
      //--------------------------------------------------

      static datetime lastBar = 0;

      datetime currentBar =
         iTime(
            m_config.Symbol(),
            m_config.Timeframe(),
            0);

      if(currentBar == lastBar)
         return;

      lastBar = currentBar;

      Print("");
      Print("======================================");
      Print("TradePilot");
      Print("--------------------------------------");

      //--------------------------------------------------
      // Indicadores
      //--------------------------------------------------

      Print("EMA20 : ",
            DoubleToString(m_indicators.EMA20(),5));

      Print("EMA50 : ",
            DoubleToString(m_indicators.EMA50(),5));

      Print("ATR14 : ",
            DoubleToString(m_indicators.ATR(),5));

      Print("ADX14 : ",
            DoubleToString(m_indicators.ADX(),2));

      Print("+DI   : ",
            DoubleToString(m_indicators.PlusDI(),2));

      Print("-DI   : ",
            DoubleToString(m_indicators.MinusDI(),2));

      //--------------------------------------------------
      // Estado del mercado
      //--------------------------------------------------

      Print("--------------------------------------");

      Print("Bull Trend      : ",
            m_marketState.IsBullTrend() ? "SI" : "NO");

      Print("Bear Trend      : ",
            m_marketState.IsBearTrend() ? "SI" : "NO");

      Print("Range           : ",
            m_marketState.IsRange() ? "SI" : "NO");

      Print("High Volatility : ",
            m_marketState.IsHighVolatility() ? "SI" : "NO");

      Print("Trend Strength  : ",
            DoubleToString(
               m_marketState.TrendStrength(),
               2));

      Print("Volatility      : ",
            DoubleToString(
               m_marketState.Volatility(),
               2));

      //--------------------------------------------------
      // Señales
      //--------------------------------------------------

      Print("--------------------------------------");

      Print("BUY Signal  : ",
            m_signalManager.Buy() ? "SI" : "NO");

      Print("SELL Signal : ",
            m_signalManager.Sell() ? "SI" : "NO");

      Print("======================================");
     }

   //--------------------------------------------------
   // Finalización
   //--------------------------------------------------

   void              Shutdown()
     {
      if(!m_initialized)
         return;

      m_signalManager.Shutdown();
      m_marketState.Shutdown();
      m_indicators.Shutdown();
      m_sessions.Shutdown();
      m_market.Shutdown();

      Print("Core detenido.");

      m_initialized = false;
     }

   //--------------------------------------------------
   // Estado
   //--------------------------------------------------

   bool              IsInitialized() const
     {
      return m_initialized;
     }

  };

#endif
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
