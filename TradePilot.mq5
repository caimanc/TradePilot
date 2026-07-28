//+------------------------------------------------------------------+
//|                                                    TradePilot.mq5|
//|                        TradePilot Expert Advisor                 |
//+------------------------------------------------------------------+
#property strict
#property version   "1.00"

#include "Core/TP_Core.mqh"

//--------------------------------------------------
// Instancia global del núcleo
//--------------------------------------------------

CTPCore g_core;

//+------------------------------------------------------------------+
//| Inicialización                                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("======================================");
   Print("Iniciando TradePilot...");
   Print("======================================");

   if(!g_core.Initialize())
   {
      Print("ERROR: No fue posible inicializar TradePilot.");
      return INIT_FAILED;
   }

   Print("TradePilot iniciado correctamente.");

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Tick                                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   g_core.Update();
}

//+------------------------------------------------------------------+
//| Finalización                                                     |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("======================================");
   Print("Deteniendo TradePilot...");
   Print("======================================");

   g_core.Shutdown();

   Print("TradePilot detenido.");
}
//+------------------------------------------------------------------+