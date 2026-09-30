//+------------------------------------------------------------------+
//|                                                    TradePilot.mq5|
//|                        TradePilot Expert Advisor                 |
//+------------------------------------------------------------------+
#property strict
#property version   "1.00"

#include "Core/TP_Core.mqh"

//--------------------------------------------------
// VOLUMEN DE APERTURA
// Cantidad con la que abre cada operacion (en lotes).
// 0 = automatico: calcula el lote segun el riesgo diario.
//--------------------------------------------------

input double InpVolumenManual = 0.0;

//--------------------------------------------------
// RIESGO DIARIO
// Limites que protegen la cuenta dentro del dia.
//--------------------------------------------------

input int    InpMaxTrades    = 0;     // Maximo de operaciones al dia. 0 = sin limite
input double InpMaxPerdida   = 50.0;  // Perdida maxima diaria en USD (detiene el EA)

//--------------------------------------------------
// ALERTA SONORA
// Emite un sonido cuando el EA abre o cierra una operacion.
//--------------------------------------------------

input bool   InpAlertaSonido = true; // true = sonido activado, false = silencioso

//--------------------------------------------------
// TRAILING DE GANANCIA (en USD reales)
// El SL se mueve para asegurar ganancia cuando el beneficio crece.
// Todos estos valores van en USD, NO en puntos.
// MinProfit: ganancia minima para activar la proteccion.
//   4  -> se activa cuando el beneficio llega a +4 USD
// Offset: ganancia protegida al activarse.
//   SL sube hasta proteger 2 USD.
// Step: cada cuantos USD adicionales se reevalua.
//   5  -> re-evalua cada +5 USD extra
// Increase: cuanto sube el SL por cada escalon.
//   +9 USD -> SL protegeria 4.5 USD; +14 -> 7 USD.
//--------------------------------------------------

input double InpTrailMinProfit        = 0.0;  // Ganancia en USD para activar. 0 = desactivado
input double InpTrailBreakevenOffset  = 1.0;  // USD que protege el SL al activarse
input double InpTrailStep             = 5.0;  // Cada cuantos USD extra se reevalua
input double InpTrailStepIncrease     = 5.0;  // En cuantos USD sube el SL por escalon
input bool   InpTrailTP               = true; // true = extiende el TP con el SL, false = deja el TP fijo

//--------------------------------------------------
// LIMITE DE SL POR OPERACION
// Tope del stop loss en USD. El EA no dejara un SL mas amplio que esto.
// 0 = sin limite: usa el SL que calcula la estructura del mercado.
// >0 = limita el SL a ese maximo en USD (ej.: 30 = SL maximo 30 USD).
//--------------------------------------------------

input double InpMaxSL = 0.0;  // Maximo SL por operacion en USD. 0 = sin limite

//--------------------------------------------------
// FILTRO DE PROBABILIDAD (Naive Bayes entrenado)
// P(de senalar) lo calcula un modelo Naive Bayes entrenado
// con operaciones reales (tendencia, HTF, setup, sesion).
// InpNBActivo = false = sin filtro probabilistico (clasico).
// Threshold 0 = desactivado: usa el metodo clasico (si/no).
// Threshold >0 (ej.: 70) = solo senala si P(ganar) del modelo >= ese %.
//--------------------------------------------------

input double InpScoreThreshold = 0.0;  // Probabilidad minima % para senalar. 0 = desactivado
input bool   InpNBActivo       = false; // Usa Naive Bayes como calculo de probabilidad

//--------------------------------------------------
// PATRONES DE VELA (suficiencia, no necesidad)
// Segundo camino de señal + salida por agotamiento.
// Sin patrón = el EA opera EXACTAMENTE igual que hoy.
// InpPatronesActivo es el maestro: con false, el módulo
// completo queda desactivado y la señal es solo la clásica.
//--------------------------------------------------

input bool   InpPatronesActivo    = false; // Maestro: habilita el módulo de patrones de vela
input bool   InpPatronEntrada     = true;  // Modo 1: entrada por patrón confirmado
input bool   InpPatronAgotamiento = true;  // Modo 3: salida por agotamiento (patrón contrario confirmado)

//--------------------------------------------------
// MÓDULOS DE ANÁLISIS AVANZADO (opcionales)
// Cada uno se activa con su interruptor. Con todos en
// false el EA opera EXACTAMENTE igual que hoy.
//--------------------------------------------------

input bool   InpVWAPActivo    = false; // Filtro direccional VWAP + TP dinámico al VWAP
input bool   InpBarridoActivo = false; // Patrones reforzados por barrido de liquidez
input bool   InpDeltaActivo   = false; // Modulo de flujo/delta (informativo, no altera la probabilidad)
input bool   InpPerfilActivo  = false; // SL/TP conscientes del perfil de volumen

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
          InpNBActivo,
InpPatronesActivo,
           InpPatronEntrada,
           InpPatronAgotamiento,
           InpVWAPActivo,
           InpBarridoActivo,
           InpDeltaActivo,
           InpPerfilActivo))
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