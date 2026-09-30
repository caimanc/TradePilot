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
// DRAWDOWN TOTAL Y HARD STOP
// Protegen la cuenta ante una racha adversa.
// MaxDrawdown 0 = desactivado.
// HardStop true = cierra todo y detiene el EA
// al alcanzar el limite (además bloquea entradas).
//--------------------------------------------------

input double InpMaxDrawdown = 0.0;  // Max drawdown total % sobre equity pico. 0 = desactivado
input bool   InpHardStop    = false; // Cierra todo y detiene el EA al llegar a MaxDrawdown

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
            InpPerfilActivo,
            InpMaxDrawdown,
            InpHardStop))
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
//| OnTester - Score 70/30 in-sample / out-of-sample                 |
//| Evalua la robustez de la estrategia solo sobre operaciones        |
//| CERRADAS propias (filtro magic + simbolo) y las divide 70%/30%    |
//| en el tiempo: el 70% inicial es in-sample, el 30% final es        |
//| out-of-sample. Penaliza sobreajuste: un resultado OOS malo        |
//| castiga fuerte el score (guards negativos).                       |
//| Solo se ejecuta en el Strategy Tester.                            |
//+------------------------------------------------------------------+
double OnTester()
{
   // Magic propio del proyecto: debe coincidir con Config/TP_Config.mqh
   const long MAGIC = 20260724;
   const double DEPOSIT_REF = 10000.0; // balance de referencia para la penalizacion de DD

   if(!HistorySelect(0, TimeCurrent()))
      return 0.0;

   int total = HistoryDealsTotal();
   if(total <= 0)
      return 0.0;

   // ---------- 1) Filtrar SOLO cierres propios (magic + simbolo) ----------
   // Se conserva exactamente un evento por operacion cerrada: OUT (cierre
   // parcial) e INOUT (cierre total). Las entradas y las operaciones ajenas
   // se descartan, asi el P&L acumulado no se cuenta dos veces.
   datetime tms[];
   double   pls[];
   ArrayResize(tms, total);
   ArrayResize(pls, total);

   int      nDeals = 0;
   datetime firstTime = 0, lastTime = 0;

   for(int i = 0; i < total; i++)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket == 0)
         continue;
      if(HistoryDealGetString(ticket, DEAL_SYMBOL) != _Symbol)
         continue;
      if(HistoryDealGetInteger(ticket, DEAL_MAGIC) != MAGIC)
         continue;
      long entry = HistoryDealGetInteger(ticket, DEAL_ENTRY);
      if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_INOUT)
         continue;

      datetime t  = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
      double   pl = HistoryDealGetDouble(ticket, DEAL_PROFIT)
                  + HistoryDealGetDouble(ticket, DEAL_COMMISSION)
                  + HistoryDealGetDouble(ticket, DEAL_SWAP);

      tms[nDeals] = t;
      pls[nDeals] = pl;

      if(nDeals == 0)
      {
         firstTime = t;
         lastTime  = t;
      }
      else
      {
         if(t < firstTime) firstTime = t;
         if(t > lastTime)  lastTime  = t;
      }
      nDeals++;
   }

   if(nDeals == 0)
      return 0.0;

   // ---------- 2) Dividir 70% in-sample / 30% out-of-sample ----------
   datetime IS_end  = firstTime + (datetime)((lastTime - firstTime) * 0.7);

   double balance = 0.0, maxBal = 0.0, dd = 0.0;

   double IS_profit = 0, IS_positive = 0, IS_negative = 0, IS_dd = 0;
   double OOS_profit = 0, OOS_positive = 0, OOS_negative = 0, OOS_dd = 0;
   int    IS_trades = 0, OOS_trades = 0;

   for(int i = 0; i < nDeals; i++)
   {
      balance += pls[i];
      if(balance > maxBal) maxBal = balance;
      dd = maxBal - balance; // drawdown sobre la curva de P&L acumulado

      if(tms[i] <= IS_end)
      {
         IS_trades++;
         IS_profit += pls[i];
         if(pls[i] > 0) IS_positive += pls[i]; else IS_negative -= pls[i];
         if(dd > IS_dd) IS_dd = dd;
      }
      else
      {
         OOS_trades++;
         OOS_profit += pls[i];
         if(pls[i] > 0) OOS_positive += pls[i]; else OOS_negative -= pls[i];
         if(dd > OOS_dd) OOS_dd = dd;
      }
   }

   // ---------- 3) Guards: una OOS pobre elimina al candidato ----------
   if(OOS_trades < 20) return -1e9;
   if(OOS_profit <= 0) return -1e8;
   if(IS_profit  <= 0) return -1e7;

   double OOS_rf = (OOS_dd > 0) ? OOS_profit / OOS_dd : OOS_profit * 100;
   if(OOS_rf < 1.0) return -1e6;

   // ---------- 4) Metricas por tramo ----------
   double IS_rf  = (IS_dd > 0) ? IS_profit / IS_dd : IS_profit * 100;
   double IS_win = (IS_positive + IS_negative > 0) ? IS_positive / (IS_positive + IS_negative) : 0;
   double IS_avg_win  = (IS_trades > 0 && IS_win > 0)     ? IS_positive / (IS_trades * IS_win) : 0;
   double IS_avg_loss = (IS_trades > 0 && (1 - IS_win) > 0) ? IS_negative / (IS_trades * (1 - IS_win)) : 0;
   double IS_payoff = (IS_avg_loss > 0) ? IS_avg_win / IS_avg_loss : 10;

   double OOS_pf  = (OOS_negative > 0) ? OOS_positive / OOS_negative : 100;
   double OOS_win = (OOS_positive + OOS_negative > 0) ? OOS_positive / (OOS_positive + OOS_negative) : 0;
   double OOS_avg_win  = (OOS_trades > 0 && OOS_win > 0)     ? OOS_positive / (OOS_trades * OOS_win) : 0;
   double OOS_avg_loss = (OOS_trades > 0 && (1 - OOS_win) > 0) ? OOS_negative / (OOS_trades * (1 - OOS_win)) : 0;
   double OOS_payoff = (OOS_avg_loss > 0) ? OOS_avg_win / OOS_avg_loss : 10;

   // ---------- 5) Score compuesto ----------
   double score = 0;
   score += 15.0 * MathLog(OOS_rf + 1);        // robustez OOS (recuperacion)
   score += 10.0 * MathLog(OOS_pf + 1);        // profit factor OOS
   score += 7.5  * MathLog(OOS_payoff + 1);    // payoff OOS

   // Consistencia IS vs OOS (0.7..1.0 por cada relacion)
   double consistency = 1.0;
   if(IS_win    > 0) consistency *= 0.7 + 0.3 * MathMin(OOS_win / IS_win, 1.5);
   if(IS_payoff > 0) consistency *= 0.7 + 0.3 * MathMin(OOS_payoff / IS_payoff, 1.5);
   if(IS_rf     > 0) consistency *= 0.7 + 0.3 * MathMin(OOS_rf / IS_rf, 1.5);
   score += 30.0 * consistency;

   // Estabilidad entre tramos (penaliza el sobreajuste)
   double stability = 1.0;
   stability -= 0.2 * MathAbs(IS_win    - OOS_win);
   stability -= 0.2 * MathAbs(IS_payoff - OOS_payoff);
   score += 20.0 * MathMax(0, stability);

   // Penalizacion por drawdown OOS (relativo al deposito de referencia)
   double risk_penalty = 1.0 - 0.3 * MathMin(1.0, OOS_dd / DEPOSIT_REF);
   score *= MathMax(0.5, risk_penalty);

   // Pequena bonificacion por mas operaciones OOS
   score *= 1.0 + 0.1 * MathLog(1 + OOS_trades);

   Print("OnTester: cierres totales=", nDeals, " OOS=", OOS_trades,
         " PF=", DoubleToString(OOS_pf, 2),
         " RF=", DoubleToString(OOS_rf, 2),
         " payoff=", DoubleToString(OOS_payoff, 2),
         " score=", DoubleToString(score, 2));

   return score;
}
//+------------------------------------------------------------------+