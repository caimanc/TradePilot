//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#ifndef __TP_CORE_MQH__
#define __TP_CORE_MQH__

#include "../Config/TP_Config.mqh"
#include "../Market/TP_Market.mqh"
#include "../Sessions/TP_Sessions.mqh"
#include "../Indicators/TP_Indicators.mqh"

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
     }

   //--------------------------------------------------
   // Inicialización
   //--------------------------------------------------

   bool              Initialize()
     {
      Print("");
      Print("======================================");
      Print("        TradePilot v0.1");
      Print("======================================");

      Print("");
      Print("Configuración");

      Print("Símbolo      : ", m_config.Symbol());
      Print("TimeFrame    : ", EnumToString(m_config.Timeframe()));
      Print("Riesgo       : ", DoubleToString(m_config.RiskPercent(),2), "%");
      Print("MagicNumber  : ", m_config.MagicNumber());

      Print("");

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

      if(!m_indicators.Initialize(m_market))
        {
         Print("ERROR inicializando Indicators.");
         return false;
        }

      //--------------------------------------------------

      m_initialized = true;

      Print("");
      Print("TradePilot iniciado correctamente.");
      Print("");

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
      // Orden de actualización
      //--------------------------------------------------

      m_market.Update();

      m_sessions.Update();

      m_indicators.Update();

      //--------------------------------------------------
      // Próximos módulos
      //--------------------------------------------------

      // m_signals.Update();
      // m_probability.Update();
      // m_strategy.Update();
      // m_risk.Update();
      // m_trade.Update();
      // m_statistics.Update();
      // m_ui.Update();
     }

   //--------------------------------------------------
   // Finalización
   //--------------------------------------------------

   void              Shutdown()
     {
      if(!m_initialized)
         return;

      m_indicators.Shutdown();

      m_sessions.Shutdown();

      m_market.Shutdown();

      m_initialized = false;

      Print("");
      Print("TradePilot detenido.");
      Print("");
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
