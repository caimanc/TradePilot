//+------------------------------------------------------------------+
//|                                                    TradePilot.mq5|
//|                        TradePilot Expert Advisor                 |
//+------------------------------------------------------------------+
#property strict
#property version   "1.00"

#include "Core/TP_Core.mqh"

//--------------------------------------------------
// Volumen manual (0 = automatico por riesgo)
//--------------------------------------------------

input double InpVolumenManual = 0.0;

//--------------------------------------------------
// Riesgo diario
//--------------------------------------------------

input int    InpMaxTrades    = 0;     // 0 = ilimitado
input double InpMaxPerdida   = 50.0;  // perdida maxima diaria USD

//--------------------------------------------------
// Alerta sonora
//--------------------------------------------------

input bool   InpAlertaSonido = true;

//--------------------------------------------------
// Trailing de proteccion por ganancia
//--------------------------------------------------

input double InpTrailMinProfit        = 0.0;  // 0 = desactivado
input double InpTrailBreakevenOffset  = 1.0;  // ganancia minima a proteger
input double InpTrailStep             = 5.0;  // cada N dls, evaluar trail
input double InpTrailStepIncrease     = 5.0;  // subir SL N dls por step
input bool   InpTrailTP               = true; // extender TP si tendencia continua

//--------------------------------------------------
// Limite de SL por operacion
//--------------------------------------------------

input double InpMaxSL = 0.0;  // 0 = valor calculado, >0 = maximo en USD

//--------------------------------------------------
// Capa de probabilidad (scoring ponderado)
// 0.0 = desactivado (comportamiento clasico booleano)
//--------------------------------------------------

input double InpScoreThreshold = 0.0;  // probabilidad minima % para senalar
input double InpW_Tendencia    = 1.0;  // peso de la tendencia local
input double InpW_Htf          = 1.0;  // peso del sesgo del tf superior
input double InpW_Setup        = 1.0;  // peso del setup estructural
input double InpW_Sesion       = 0.0;  // peso de la ventana de sesion

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

   if(!g_core.Initialize(
         InpVolumenManual,
         InpMaxTrades,
         InpMaxPerdida,
         InpAlertaSonido,
         InpTrailMinProfit,
         InpTrailBreakevenOffset,
         InpTrailStep,
         InpTrailStepIncrease,
         InpTrailTP,
         InpMaxSL,
         InpScoreThreshold,
         InpW_Tendencia,
         InpW_Htf,
         InpW_Setup,
         InpW_Sesion))
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