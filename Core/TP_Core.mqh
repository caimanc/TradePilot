#ifndef __TP_CORE_MQH__
#define __TP_CORE_MQH__

//+------------------------------------------------------------------+
//| Includes                                                         |
//+------------------------------------------------------------------+

#include "../Config/TP_Config.mqh"

#include "../Market/TP_Market.mqh"
#include "../Market/TP_PriceSeries.mqh"

#include "../Indicators/TP_Indicators.mqh"

#include "../MarketAnalysis/TP_SwingDetector.mqh"
#include "../MarketAnalysis/TP_MarketStructure.mqh"
#include "../MarketAnalysis/TP_StructureAnalyzer.mqh"
#include "../MarketAnalysis/TP_StopLossCalculator.mqh"
#include "../MarketAnalysis/TP_SetupValidator.mqh"
#include "../MarketAnalysis/TP_SetupProfiles.mqh"
#include "../MarketAnalysis/TP_TakeProfitCalculator.mqh"
#include "../MarketAnalysis/TP_HTFContext.mqh"

#include "../MarketState/TP_MarketState.mqh"

#include "../Scoring/TP_ProbabilityScorer.mqh"

#include "../Signals/TP_SignalManager.mqh"

#include "../Risk/TP_RiskManager.mqh"
#include "../UI/TP_Panel.mqh"

#include "../Execution/TP_TradeManager.mqh"

#include "../Market/TP_Monitor.mqh"


//+------------------------------------------------------------------+
//| Núcleo principal                                                 |
//+------------------------------------------------------------------+
class CTPCore
{
private:

   //==================================================
   // Estado
   //==================================================

   bool m_initialized;

   int  m_senalesEvaluadas;
   int  m_senalesEjecutadas;


   //==================================================
   // Configuración
   //==================================================

   CTPConfig m_config;


   //==================================================
   // Mercado
   //==================================================

   CTPMarket m_market;


   //==================================================
   // Serie de precios
   //==================================================

   CTPPriceSeries m_priceSeries;


   //==================================================
   // Indicadores
   //==================================================

   CTPIndicators m_indicators;


   //==================================================
   // Análisis de mercado
   //==================================================

   CTPSwingDetector      m_swingDetector;
   CTPMarketStructure    m_marketStructure;
   CTPStructureAnalyzer  m_structureAnalyzer;


   //==================================================
   // Stop Loss
   //==================================================

   CTPStopLossCalculator m_stopLossCalculator;


   //==================================================
   // Validador de setups
   //==================================================

   CTPSetupValidator m_setupValidator;


   //==================================================
   // Calculadora de take profit
   //==================================================

   CTPTakeProfitCalculator m_takeProfitCalculator;

   CTPHTFContext m_htfContext;

   CTPPanel m_panel;


   //==================================================
   // Estado del mercado
   //==================================================

   CTPMarketState m_marketState;


   //==================================================
   // Señales
   //==================================================

   CTPSignalManager m_signalManager;


   //==================================================
   // Riesgo
   //==================================================

   CTPRiskManager m_riskManager;


   //==================================================
   // Ejecución
   //==================================================

   CTPTradeManager m_tradeManager;


   //==================================================
   // Monitor (telemetría + noticias)
   //==================================================

   CTPMonitor m_monitor;


public:

   //==================================================
   // Constructor
   //==================================================

   CTPCore()
   {
      m_initialized = false;

      m_senalesEvaluadas  = 0;
      m_senalesEjecutadas = 0;
   }


   //==================================================
   // Inicialización
   //==================================================

   bool Initialize(
      double volumenManual     = 0.0,
      int    maxTrades         = 0,
      double maxPerdida        = 50.0,
      bool   alertaSonido      = true,
      double trailMinProfit    = 0.0,
      double trailBreakevenOffset = 1.0,
      double trailStep         = 5.0,
      double trailStepIncrease = 5.0,
      bool   trailTP           = true,
      double maxSL             = 0.0,
       double scoreThreshold    = 0.0,
       double wTendencia        = 1.0,
       double wHtf              = 1.0,
       double wSetup            = 1.0,
       double wSesion           = 0.0,
       bool   patronActivo      = false,
       bool   patronEntrada     = true,
       bool   patronAgotamiento = true)
   {
      Print("====================================");
      Print("Inicializando TradePilot...");
      Print("====================================");


      //--------------------------------------------------
      // Guard anti duplicados (multi-instancia)
      //--------------------------------------------------

      string nombreGlobal = NombreGlobal();

      if(GlobalVariableCheck(nombreGlobal))
      {
         Print("BLOQUEADO: ya existe otra instancia de TradePilot ",
               "para ", m_config.Symbol(),
               " con magic ", m_config.MagicNumber(),
               ". Cierra la instancia duplicada.");

         return false;
      }

      GlobalVariableSet(nombreGlobal, 0.0);


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
      // Price Series
      //--------------------------------------------------

      if(!m_priceSeries.Initialize(
            m_config.Symbol(),
            m_config.Timeframe()))
      {
         Print("ERROR inicializando PriceSeries.");
         return false;
      }


      //--------------------------------------------------
      // Primera carga de precios
      //--------------------------------------------------

      if(!m_priceSeries.Update())
      {
         Print("ERROR actualizando PriceSeries.");
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
      // HTF Context
      //--------------------------------------------------

      if(!m_htfContext.Initialize(
            m_config.Symbol(),
            ObtenerHTF(m_config.Timeframe())))
      {
         Print("ERROR inicializando HTF Context.");
         return false;
      }


      //--------------------------------------------------
      // Swing Detector
      //--------------------------------------------------

      if(!m_swingDetector.Initialize(2))
      {
         Print("ERROR inicializando SwingDetector.");
         return false;
      }


      //--------------------------------------------------
      // Market Structure
      //--------------------------------------------------

      if(!m_marketStructure.Initialize())
      {
         Print("ERROR inicializando MarketStructure.");
         return false;
      }


      //--------------------------------------------------
      // Structure Analyzer
      //--------------------------------------------------

      if(!m_structureAnalyzer.Initialize())
      {
         Print("ERROR inicializando StructureAnalyzer.");
         return false;
      }


      //--------------------------------------------------
      // Stop Loss Calculator
      //--------------------------------------------------

      if(!m_stopLossCalculator.Initialize(
            0.20,
            2.0))
      {
         Print("ERROR inicializando StopLossCalculator.");
         return false;
      }


      //--------------------------------------------------
      // Setup Validator
      //--------------------------------------------------

      TPSetupProfile perfilSetup;

      ObtenerPerfil(
         m_config.Timeframe(),
         perfilSetup);

      if(!m_setupValidator.Initialize(
            perfilSetup.minSLPoints,
            perfilSetup.maxSLPoints))
      {
         Print("ERROR inicializando SetupValidator.");
         return false;
      }

      if(!m_panel.Initialize(
            m_config.Symbol(),
            EnumToString(m_config.Timeframe()),
            StringFormat("%.0f/%.0f",
               perfilSetup.minSLPoints,
               perfilSetup.maxSLPoints),
            EnumToString(ObtenerHTF(m_config.Timeframe()))))
      {
         Print("ERROR inicializando Panel.");
         return false;
      }


      if(!m_takeProfitCalculator.Initialize())
      {
         Print("ERROR inicializando TakeProfitCalculator.");
         return false;
      }


      //--------------------------------------------------
      // Risk Manager
      //--------------------------------------------------

      if(!m_riskManager.Initialize(
            m_config.MagicNumber(),
            volumenManual,
            maxTrades,
            maxPerdida))
      {
         Print("ERROR inicializando RiskManager.");
         return false;
      }


      //--------------------------------------------------
      // Trade Manager
      //--------------------------------------------------

      if(!m_tradeManager.Initialize(
            m_config.MagicNumber(),
            alertaSonido,
            trailMinProfit,
            trailBreakevenOffset,
            trailStep,
            trailStepIncrease,
            trailTP,
            maxSL))
      {
         Print("ERROR inicializando TradeManager.");
         return false;
      }


      //--------------------------------------------------
      // Parámetros del módulo de patrones de vela
      //--------------------------------------------------

      m_signalManager.SetPatronParams(
         patronActivo,
         patronEntrada,
         patronAgotamiento
      );


      //--------------------------------------------------
      // Monitor (telemetría + noticias)
      //--------------------------------------------------

      m_monitor.Initialize(
         m_config.MagicNumber()
      );


      //--------------------------------------------------
      // Capa de probabilidad (scoring)
      //--------------------------------------------------

      m_signalManager.SetScoreParams(
         scoreThreshold,
         wTendencia,
         wHtf,
         wSetup,
         wSesion
      );

      //--------------------------------------------------
      // Offset UTC del broker (horas) para sesiones
      //--------------------------------------------------

      MqlDateTime tBroker;
      MqlDateTime tGMT;

      TimeToStruct(TimeCurrent(), tBroker);
      TimeToStruct(TimeGMT(),     tGMT);

      int brokerUtcOffset =
         tBroker.hour - tGMT.hour;

      if(brokerUtcOffset < -12) brokerUtcOffset += 24;
      if(brokerUtcOffset >  12) brokerUtcOffset -= 24;

      m_signalManager.SetScoreSessions(brokerUtcOffset);


      //--------------------------------------------------
      // Estado
      //--------------------------------------------------

      m_initialized = true;


      Print("TradePilot inicializado correctamente.");

      return true;
   }


   //==================================================
   // Actualización
   //==================================================

   void Update()
   {
      if(!m_initialized)
         return;

      m_panel.Update(
         m_marketState,
         m_riskManager,
         m_signalManager.BuyProbability(),
         m_signalManager.SellProbability(),
         m_signalManager.ScoreThreshold(),
         m_signalManager.ScoreEnabled(),
         m_signalManager.SesionName(),
         m_signalManager.SesionFactor(),
         m_senalesEvaluadas,
         m_senalesEjecutadas,
         m_signalManager.UltimoPatron(),
         m_signalManager.PatronDireccion(),
         m_signalManager.PatronConfirmado()
      );


      //==================================================
      // MARKET
      //==================================================

      if(!m_market.Update())
         return;


      //==================================================
      // RISK MANAGER
      //==================================================

      m_riskManager.Update();


      //==================================================
      // NUEVA VELA
      //==================================================

      if(!m_market.IsNewBar())
         return;


      //==================================================
      // PRICE SERIES
      //==================================================

      if(!m_priceSeries.Update())
         return;


      //==================================================
      // INDICATORS
      //==================================================

      if(!m_indicators.Update())
         return;


      //==================================================
      // SWING DETECTOR
      //==================================================

      if(!m_swingDetector.Update(
            m_priceSeries))
      {
         return;
      }


      //==================================================
      // MARKET STRUCTURE
      //==================================================

      m_marketStructure.SetATR(
         m_indicators.ATR()
      );


      if(!m_marketStructure.Update(
            m_swingDetector))
      {
         return;
      }


      //==================================================
      // STRUCTURE ANALYZER
      //==================================================

      double structurePrice =
         m_market.Bid();


      if(!m_structureAnalyzer.Update(
            m_marketStructure,
            structurePrice))
      {
         return;
      }


      //==================================================
      // STOP LOSS
      //==================================================

      double point =
         SymbolInfoDouble(
            m_config.Symbol(),
            SYMBOL_POINT);


      if(point <= 0.0)
         return;


      //--------------------------------------------------
      // Precios de entrada
      //--------------------------------------------------

      double buyEntry =
         m_market.Ask();

      double sellEntry =
         m_market.Bid();


      //--------------------------------------------------
      // Datos estructurales
      //--------------------------------------------------

      double swingLow =
         m_swingDetector.LastSwingLow();

      double swingHigh =
         m_swingDetector.LastSwingHigh();


      //--------------------------------------------------
      // ATR
      //--------------------------------------------------

      double atr =
         m_indicators.ATR();


      //==================================================
      // BUY SL
      //==================================================

      bool buySLCalculated =
         m_stopLossCalculator.CalculateBuy(
            buyEntry,
            swingLow,
            atr,
            point);


      double buySL       = 0.0;
      double buyDistance = 0.0;
      double buyPoints   = 0.0;


      if(buySLCalculated)
      {
         buySL =
            m_stopLossCalculator.StopLoss();

         buyDistance =
            m_stopLossCalculator.Distance();

         buyPoints =
            m_stopLossCalculator.DistancePoints(
               point);
      }


      //==================================================
      // SELL SL
      //==================================================

      bool sellSLCalculated =
         m_stopLossCalculator.CalculateSell(
            sellEntry,
            swingHigh,
            atr,
            point);


      double sellSL       = 0.0;
      double sellDistance = 0.0;
      double sellPoints   = 0.0;


      if(sellSLCalculated)
      {
         sellSL =
            m_stopLossCalculator.StopLoss();

         sellDistance =
            m_stopLossCalculator.Distance();

         sellPoints =
            m_stopLossCalculator.DistancePoints(
               point);
      }


      //==================================================
      // TAKE PROFIT
      //==================================================

      m_takeProfitCalculator.Calculate(
         buySLCalculated,
         buyEntry,
         buyDistance,
         sellSLCalculated,
         sellEntry,
         sellDistance
      );

      double buyTP =
         m_takeProfitCalculator.BuyTakeProfit();

      double sellTP =
         m_takeProfitCalculator.SellTakeProfit();


      //==================================================
      // SETUP VALIDATION
      //==================================================

      m_setupValidator.Evaluate(
         buySLCalculated,
         buyPoints,
         sellSLCalculated,
         sellPoints,
         atr / point,
         m_market.Spread(),
         SymbolInfoInteger(m_config.Symbol(), SYMBOL_TRADE_STOPS_LEVEL)
      );

      //==================================================
      // MARKET STATE
      //==================================================

      m_marketState.Update(
         m_indicators.EMA20(),
         m_indicators.EMA50(),
         m_indicators.ADX(),
         m_indicators.PlusDI(),
         m_indicators.MinusDI(),
         m_indicators.ATR()
      );

      if(!m_htfContext.Update())
         return;

      m_marketState.SetHtfBull(
         m_htfContext.IsBull());

      m_marketState.SetHtfBear(
         m_htfContext.IsBear());

      m_marketState.SetBuySetupValid(
         m_setupValidator.BuySetupValid()
      );

      m_marketState.SetSellSetupValid(
         m_setupValidator.SellSetupValid()
      );


      //==================================================
      // SIGNAL MANAGER
      //==================================================

      m_signalManager.Update(
         m_marketState,
         m_priceSeries
      );

      //--------------------------------------------------
      // Telemetria: causa del bloqueo de senales
      //--------------------------------------------------

      if(m_marketState.IsBuySetupValid() &&
         !m_signalManager.Buy())
      {
         if(!m_marketState.IsBullTrend())
            Print("SEÑAL BUY BLOQUEADA [TENDENCIA LTF]");

         else if(!m_marketState.IsHtfBull())
            Print("SEÑAL BUY BLOQUEADA [SESGO HTF]");
      }

      if(m_marketState.IsSellSetupValid() &&
         !m_signalManager.Sell())
      {
         if(!m_marketState.IsBearTrend())
            Print("SEÑAL SELL BLOQUEADA [TENDENCIA LTF]");

         else if(!m_marketState.IsHtfBear())
            Print("SEÑAL SELL BLOQUEADA [SESGO HTF]");
      }


      //--------------------------------------------------
      // Contadores de evaluacion (funnel)
      //--------------------------------------------------

      if(m_signalManager.Buy() || m_signalManager.Sell())
         m_senalesEvaluadas++;

      m_senalesEjecutadas = m_monitor.Ejecutadas();


      //==================================================
      // TRADE MANAGER
      //==================================================

      //--------------------------------------------------
      // Volumen final (auto requiere distancia real del SL)
      //--------------------------------------------------

      if(m_signalManager.Sell())
         m_riskManager.CalcularVolumen(
            sellSL - SymbolInfoDouble(m_config.Symbol(), SYMBOL_BID));

      else if(m_signalManager.Buy())
         m_riskManager.CalcularVolumen(
            SymbolInfoDouble(m_config.Symbol(), SYMBOL_ASK) - buySL);

      m_tradeManager.Update(
         m_signalManager,
         m_riskManager,
         buySL,
         sellSL,
         buyTP,
         sellTP
      );


      //--------------------------------------------------
      // Monitor de operaciones (telemetría + noticias)
      //--------------------------------------------------

      m_monitor.Update();


      //==================================================
      // LOGS
      //==================================================

      Print("------------------------------------");

      //==================================================
      // MARKET
      //==================================================

      Print(
         "Bid            : ",
         DoubleToString(
            m_market.Bid(),
            5)
      );

      Print(
         "Ask            : ",
         DoubleToString(
            m_market.Ask(),
            5)
      );

      Print(
         "Spread         : ",
         DoubleToString(
            m_market.Spread(),
            2)
      );


      //==================================================
      // PRICE SERIES
      //==================================================

      Print(
         "Bars           : ",
         m_priceSeries.Bars()
      );


      //==================================================
      // SWINGS
      //==================================================

      Print(
         "Swing High     : ",
         DoubleToString(
            swingHigh,
            5)
      );

      Print(
         "Swing Low      : ",
         DoubleToString(
            swingLow,
            5)
      );

      Print(
         "High Shift     : ",
         m_swingDetector.SwingHighShift()
      );

      Print(
         "Low Shift      : ",
         m_swingDetector.SwingLowShift()
      );


      //==================================================
      // MARKET STRUCTURE
      //==================================================

      Print(
         "Current High   : ",
         DoubleToString(
            m_marketStructure.CurrentHigh(),
            5)
      );

      Print(
         "Previous High  : ",
         DoubleToString(
            m_marketStructure.PreviousHigh(),
            5)
      );

      Print(
         "Current Low    : ",
         DoubleToString(
            m_marketStructure.CurrentLow(),
            5)
      );

      Print(
         "Previous Low   : ",
         DoubleToString(
            m_marketStructure.PreviousLow(),
            5)
      );


      Print(
         "HH             : ",
         m_marketStructure.IsHigherHigh()
      );

      Print(
         "HL             : ",
         m_marketStructure.IsHigherLow()
      );

      Print(
         "LH             : ",
         m_marketStructure.IsLowerHigh()
      );

      Print(
         "LL             : ",
         m_marketStructure.IsLowerLow()
      );


      //==================================================
      // STRUCTURE ANALYZER
      //==================================================

      Print(
         "Structure      : ",
         m_structureAnalyzer.StatusName()
      );

      Print(
         "Structure Bullish : ",
         m_structureAnalyzer.IsBullish()
      );

      Print(
         "Structure Bearish : ",
         m_structureAnalyzer.IsBearish()
      );

      Print(
         "Breakout       : ",
         m_structureAnalyzer.IsBreakout()
      );

      Print(
         "Breakdown      : ",
         m_structureAnalyzer.IsBreakdown()
      );

      Print(
         "Range          : ",
         m_structureAnalyzer.IsRange()
      );

      Print(
         "Retracement    : ",
         m_structureAnalyzer.IsRetracement()
      );


      //==================================================
      // INDICATORS
      //==================================================

      Print(
         "EMA20          : ",
         DoubleToString(
            m_indicators.EMA20(),
            5)
      );

      Print(
         "EMA50          : ",
         DoubleToString(
            m_indicators.EMA50(),
            5)
      );

      Print(
         "ADX            : ",
         DoubleToString(
            m_indicators.ADX(),
            2)
      );

      Print(
         "ATR            : ",
         DoubleToString(
            atr,
            5)
      );


      //==================================================
      // MARKET STATE
      //==================================================

      Print(
         "Bull           : ",
         m_marketState.IsBullTrend()
      );

      Print(
         "Bear           : ",
         m_marketState.IsBearTrend()
      );


      //==================================================
      // STOP LOSS ANALYSIS
      //==================================================

      Print("------------------------------------");

      Print(
         "STOP LOSS ANALYSIS"
      );


      //--------------------------------------------------
      // BUY
      //--------------------------------------------------

      Print(
         "BUY Entry      : ",
         DoubleToString(
            buyEntry,
            5)
      );

      Print(
         "BUY SL Valid   : ",
         buySLCalculated
      );

      Print(
         "BUY SL         : ",
         DoubleToString(
            buySL,
            5)
      );

      Print(
         "BUY Distance   : ",
         DoubleToString(
            buyDistance,
            5)
      );

      Print(
         "BUY Points     : ",
         DoubleToString(
            buyPoints,
            2)
      );


      //--------------------------------------------------
      // SELL
      //--------------------------------------------------

      Print(
         "SELL Entry     : ",
         DoubleToString(
            sellEntry,
            5)
      );

      Print(
         "SELL SL Valid  : ",
         sellSLCalculated
      );

      Print(
         "SELL SL        : ",
         DoubleToString(
            sellSL,
            5)
      );

      Print(
         "SELL Distance  : ",
         DoubleToString(
            sellDistance,
            5)
      );

      Print(
         "SELL Points    : ",
         DoubleToString(
            sellPoints,
            2)
      );


      //==================================================
      // SIGNALS
      //==================================================

      Print("------------------------------------");

      Print(
         "BUY            : ",
         m_signalManager.Buy()
      );

      Print(
         "SELL           : ",
         m_signalManager.Sell()
      );


      Print("------------------------------------");
   }


   //==================================================
   // Shutdown
   //==================================================

   //--------------------------------------------------
   // Nombre de la variable global anti duplicados
   //--------------------------------------------------

   string NombreGlobal() const
   {
      return StringFormat(
         "TP_%s_%I64d",
         m_config.Symbol(),
         m_config.MagicNumber()
      );
   }

   void Shutdown()
   {
      if(!m_initialized)
         return;
      Print("====================================");
      Print("Cerrando TradePilot...");
      Print("====================================");


      //--------------------------------------------------
      // Liberar variable global anti duplicados
      //--------------------------------------------------

      GlobalVariableDel(NombreGlobal());


      //--------------------------------------------------
      // Monitor (telemetría)
      //--------------------------------------------------

      m_monitor.Shutdown();


      //--------------------------------------------------
      // Trade Manager
      //--------------------------------------------------

      m_tradeManager.Shutdown();


      //--------------------------------------------------
      // Risk Manager
      //--------------------------------------------------

      m_riskManager.Shutdown();


      //--------------------------------------------------
      // Stop Loss Calculator
      //--------------------------------------------------

      m_stopLossCalculator.Shutdown();

      //--------------------------------------------------
      // Setup Validator
      //--------------------------------------------------

      m_setupValidator.Shutdown();

      m_takeProfitCalculator.Shutdown();


      //--------------------------------------------------
      // Structure Analyzer
      //--------------------------------------------------

      m_structureAnalyzer.Shutdown();


      //--------------------------------------------------
      // Market Structure
      //--------------------------------------------------

      m_marketStructure.Shutdown();


      //--------------------------------------------------
      // Swing Detector
      //--------------------------------------------------

      m_swingDetector.Shutdown();


      //--------------------------------------------------
      // Indicators
      //--------------------------------------------------

      m_indicators.Shutdown();

      m_htfContext.Shutdown();

      m_panel.Shutdown();


      //--------------------------------------------------
      // Price Series
      //--------------------------------------------------

      m_priceSeries.Shutdown();


      //--------------------------------------------------
      // Market
      //--------------------------------------------------

      m_market.Shutdown();


      //--------------------------------------------------
      // Estado
      //--------------------------------------------------

      m_initialized = false;


      Print("TradePilot detenido.");
   }


   //==================================================
   // Estado
   //==================================================

   bool IsInitialized() const
   {
      return m_initialized;
   }
};

#endif