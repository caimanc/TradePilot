#ifndef __TP_CORE_MQH__
#define __TP_CORE_MQH__

#include "../Config/TP_Config.mqh"
#include "../Market/TP_Market.mqh"

class CTPCore
{
private:

   //--------------------------------------------------
   // Estado
   //--------------------------------------------------

   bool m_initialized;

   //--------------------------------------------------
   // Módulos
   //--------------------------------------------------

   CTPConfig m_config;
   CTPMarket m_market;

public:

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

   CTPCore()
      : m_initialized(false)
   {
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

   bool Initialize()
   {
      Print("");
      Print("======================================");
      Print("TradePilot Core");
      Print("Inicializando núcleo...");
      Print("======================================");
      Print("");

      Print("Configuración:");

      Print("   Símbolo      : ",m_config.Symbol());
      Print("   Riesgo       : ",DoubleToString(m_config.RiskPercent(),2)," %");
      Print("   MagicNumber  : ",m_config.MagicNumber());

      Print("");

      //--------------------------------------------------
      // Inicializar Market
      //--------------------------------------------------

      if(!m_market.Initialize(m_config))
      {
         Print("ERROR: No fue posible inicializar el módulo Market.");
         return false;
      }

      Print("");

      m_initialized=true;

      Print("Core inicializado correctamente.");

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

      //--------------------------------------------------
      // Próximos módulos
      //--------------------------------------------------

      // m_sessions.Update();
      // m_probability.Update();
      // m_signals.Update();
      // m_strategy.Update();
      // m_risk.Update();
      // m_trade.Update();
      // m_statistics.Update();
      // m_ui.Update();
   }

   //--------------------------------------------------
   // Finalización
   //--------------------------------------------------

   void Shutdown()
   {
      if(!m_initialized)
         return;

      m_market.Shutdown();

      Print("Core detenido.");

      m_initialized=false;
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