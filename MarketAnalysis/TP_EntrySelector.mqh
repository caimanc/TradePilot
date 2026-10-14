//===========================================================
// TP_EntrySelector.mqh
// Selecciona el modo de entrada (MERCADO / LIMIT / STOP)
// según la estructura del mercado, para que el EA elija
// cómo y cuándo entrar en cada señal.
//
// Heurística (dirección BUY; SELL es el espejo):
//   1. Ruptura en curso (cierre superó el swing alto)
//      -> MERCADO (entrar ya, no tiene sentido esperar).
//   2. Rango comprimido y precio pegado a la resistencia
//      -> STOP (esperar la ruptura confirmada).
//   3. Precio muy extendido del soporte
//      -> LIMIT (esperar el retroceso / mejor precio).
//   4. Sin condiciones claras -> MERCADO (clásico).
//===========================================================

#ifndef TP_ENTRYSELECTOR_MQH
#define TP_ENTRYSELECTOR_MQH

#include "../Config/TP_Config.mqh"

class CTPEntrySelector
{
public:

   //--------------------------------------------------
   // Decide el modo de entrada para la señal actual.
   // esCompra  : true = BUY, false = SELL
   // ask/bid   : precios actuales
   // close     : cierre de la última vela cerrada
   // swingHigh : último swing alto relevante (resistencia)
   // swingLow  : último swing bajo relevante (soporte)
   // atr       : volatilidad actual
   // bull/bear : tendencia confirmada por MarketState
   //--------------------------------------------------

   ENUM_TP_ENTRADA SeleccionarEntrada(
      bool   esCompra,
      double ask,
      double bid,
      double close,
      double swingHigh,
      double swingLow,
      double atr,
      bool   bullTrend,
      bool   bearTrend) const
   {
      // Estructura inválida: sin referencia no se decide,
      // se mantiene el modo clásico (mercado).
      if(swingHigh <= 0.0 || swingLow <= 0.0 ||
         swingHigh <= swingLow || atr <= 0.0)
      {
         return ENTRADA_MERCADO;
      }

      double rango = swingHigh - swingLow;

      if(esCompra)
         return SeleccionarBuy(ask, close, swingHigh, swingLow,
                               rango, atr, bullTrend);
      else
         return SeleccionarSell(bid, close, swingHigh, swingLow,
                                rango, atr, bearTrend);
   }

   //--------------------------------------------------
   // Calcula modo + precio de entrada de AMBAS direcciones.
   // Entradas: ask/bid actuales, cierre de vela, estructura,
   // ATR y tendencias. Salidas: modo y precio objetivo por
   // dirección (precios por defecto = mercado actual).
   //--------------------------------------------------

   void CalcularEntradas(
      double ask,
      double bid,
      double close,
      double swingHigh,
      double swingLow,
      double atr,
      bool   bullTrend,
      bool   bearTrend,
      ENUM_TP_ENTRADA &modoBuy,
      double &buyEntry,
      ENUM_TP_ENTRADA &modoSell,
      double &sellEntry) const
   {
      modoBuy  = SeleccionarEntrada(true, ask, bid, close,
                                    swingHigh, swingLow, atr,
                                    bullTrend, bearTrend);

      modoSell = SeleccionarEntrada(false, ask, bid, close,
                                    swingHigh, swingLow, atr,
                                    bullTrend, bearTrend);

      buyEntry  = ask;
      sellEntry = bid;

      if(modoBuy == ENTRADA_LIMIT)
         buyEntry = ask - 0.5 * atr;
      else if(modoBuy == ENTRADA_STOP)
         buyEntry = ask + 0.5 * atr;

      if(modoSell == ENTRADA_LIMIT)
         sellEntry = bid + 0.5 * atr;
      else if(modoSell == ENTRADA_STOP)
         sellEntry = bid - 0.5 * atr;
   }

private:

   //--------------------------------------------------
   // Dirección BUY
   //--------------------------------------------------

   ENUM_TP_ENTRADA SeleccionarBuy(
      double ask,
      double close,
      double swingHigh,
      double swingLow,
      double rango,
      double atr,
      bool   bullTrend) const
   {
      // 1. Ruptura al alza en curso: entrar ya
      if(close > swingHigh)
         return ENTRADA_MERCADO;

      // 2. Rango comprimido + precio contra la resistencia:
      //    la ruptura confirmada es la entrada
      bool comprimido =
         rango < 1.5 * atr;

      if(comprimido &&
         ask > swingHigh - 0.3 * rango)
      {
         return ENTRADA_STOP;
      }

      // 3. Precio muy extendido del soporte:
      //    esperar el retroceso para mejor relación R/R
      bool extendido =
         (ask - swingLow) > 1.5 * atr;

      if(extendido && bullTrend)
         return ENTRADA_LIMIT;

      // 4. Sin escenario claro: mercado (clásico)
      return ENTRADA_MERCADO;
   }

   //--------------------------------------------------
   // Dirección SELL (espejo de BUY)
   //--------------------------------------------------

   ENUM_TP_ENTRADA SeleccionarSell(
      double bid,
      double close,
      double swingHigh,
      double swingLow,
      double rango,
      double atr,
      bool   bearTrend) const
   {
      // 1. Ruptura a la baja en curso: entrar ya
      if(close < swingLow)
         return ENTRADA_MERCADO;

      // 2. Rango comprimido + precio contra el soporte:
      //    la ruptura confirmada es la entrada
      bool comprimido =
         rango < 1.5 * atr;

      if(comprimido &&
         bid < swingLow + 0.3 * rango)
      {
         return ENTRADA_STOP;
      }

      // 3. Precio muy extendido de la resistencia:
      //    esperar el retroceso para mejor relación R/R
      bool extendido =
         (swingHigh - bid) > 1.5 * atr;

      if(extendido && bearTrend)
         return ENTRADA_LIMIT;

      // 4. Sin escenario claro: mercado (clásico)
      return ENTRADA_MERCADO;
   }
};

#endif // TP_ENTRYSELECTOR_MQH