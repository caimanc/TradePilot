#ifndef __TP_TRADEMANAGER_MQH__
#define __TP_TRADEMANAGER_MQH__

#include "TP_Execution.mqh"
#include "../Signals/TP_SignalManager.mqh"
#include "../Risk/TP_RiskManager.mqh"
#include "../MarketState/TP_MarketState.mqh"

//+------------------------------------------------------------------+
//| Gestor de operaciones                                            |
//+------------------------------------------------------------------+
class CTPTradeManager
{
private:

   CTPExecution m_execution;

   //--------------------------------------------------
   // Trailing de proteccion por ganancia
   //--------------------------------------------------

   bool   m_alertaSonido;
   double m_trailMinProfit;
   double m_trailBreakevenOffset;
   double m_trailStep;
   double m_trailStepIncrease;
   bool   m_trailTPEnabled;
   double m_maxSL;

   //--------------------------------------------------
   // TP original de la posicion actual
   //--------------------------------------------------

   double m_originalTP;
   bool   m_tpStored;

   //--------------------------------------------------
   // Diagnostico: ultimo escalon logueado (evita spam)
   //--------------------------------------------------

   double m_ultimoEscalonLog;
   bool   m_logueadoUmbral;

   //--------------------------------------------------
   // Magic de las posiciones propias del EA
   //--------------------------------------------------

   long   m_magicNumber;

   //--------------------------------------------------
   // Ticket de la posición propia en _Symbol
   // (mismo patrón que Monitor: filtrar por magic + símbolo)
   //--------------------------------------------------

   ulong TicketPosicionPropia() const
   {
      int total = PositionsTotal();

      for(int i = 0; i < total; i++)
      {
         ulong ticket = PositionGetTicket(i);

         if(ticket == 0)
            continue;

         if(!PositionSelectByTicket(ticket))
            continue;

         long  posMagic   = PositionGetInteger(POSITION_MAGIC);
         string posSymbol = PositionGetString(POSITION_SYMBOL);

         if(posMagic == m_magicNumber &&
            posSymbol == _Symbol)
         {
            return ticket;
         }
      }

      return 0;
   }

   //--------------------------------------------------
   // Conversión USD <-> distancia de precio
   //--------------------------------------------------

   double USDToPrecio(double usd, double volumen)
   {
      double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);

      if(tickSize <= 0.0 || tickValue <= 0.0 || volumen <= 0.0)
         return 0.0;

      // distancia(precio) = usd * tickSize / (volumen * tickValue)
      return usd * tickSize / (volumen * tickValue);
   }

   //--------------------------------------------------
   // Ganancias en USD reales de la posición
   //--------------------------------------------------

   double ProfitEnUSD(bool esCompra)
   {
      // POSITION_PROFIT ya lo entrega el broker en USD de la divisa del depósito
      return PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
   }

   //--------------------------------------------------
   // Trailing logic (trabaja en USD, no en puntos)
   //--------------------------------------------------

   void TrailingGanancia()
   {
      if(m_trailMinProfit <= 0.0)
         return;

      if(!PositionSelect(_Symbol))
         return;

      long tipo = PositionGetInteger(POSITION_TYPE);
      bool esCompra = (tipo == POSITION_TYPE_BUY);

      double entrada  = PositionGetDouble(POSITION_PRICE_OPEN);
      double slActual = PositionGetDouble(POSITION_SL);
      double tpActual = PositionGetDouble(POSITION_TP);
      double volumen  = PositionGetDouble(POSITION_VOLUME);

      //--------------------------------------------------
      // Guardar TP original la primera vez
      //--------------------------------------------------

      if(!m_tpStored && tpActual > 0.0)
      {
         m_originalTP = tpActual;
         m_tpStored   = true;
      }

      //--------------------------------------------------
      // Ganancia real en USD de la posición
      //--------------------------------------------------

      double profitUSD = ProfitEnUSD(esCompra);

      if(profitUSD < m_trailMinProfit)
      {
         // Log solo la primera vez que deja de alcanzar el umbral
         if(m_logueadoUmbral)
         {
            Print("TRAILING: ganancia ", DoubleToString(profitUSD, 2),
                  " USD < min ", DoubleToString(m_trailMinProfit, 2),
                  " USD -> proteccion desactivada (SL no movido)");
            m_logueadoUmbral = false;
         }

         return;
      }

      m_logueadoUmbral = true;

      //--------------------------------------------------
      // Ganancia adicional sobre el mínimo (en USD)
      //--------------------------------------------------

      double extraUSD = profitUSD - m_trailMinProfit;

      // Cuántos escalones completos de "step" se han superado
      double escalones = MathFloor(extraUSD / m_trailStep);

      //--------------------------------------------------
      // Log de diagnostico: solo cuando cambia el escalon
      //--------------------------------------------------

      if(escalones != m_ultimoEscalonLog)
      {
         Print("TRAILING: ganancia ", DoubleToString(profitUSD, 2),
               " USD (extra ", DoubleToString(extraUSD, 2),
               ") -> escalon ", DoubleToString(escalones, 0),
               ", protege ", DoubleToString(
                  m_trailBreakevenOffset + escalones * m_trailStepIncrease, 2),
               " USD");
         m_ultimoEscalonLog = escalones;
      }

      // Ganancia protegida en USD:
      //   offset + escalones * increase
      double lockedUSD = m_trailBreakevenOffset +
         escalones * m_trailStepIncrease;

      //--------------------------------------------------
      // Convertir la ganancia protegida (USD) a distancia de precio
      //--------------------------------------------------

      double lockedPrecio = USDToPrecio(lockedUSD, volumen);

      if(lockedPrecio <= 0.0)
         return;

      double newSL = 0.0;
      double newTP = 0.0;

      if(esCompra)
      {
         newSL = entrada + lockedPrecio;

         //--------------------------------------------------
         // TP se extiende si la tendencia continua
         //--------------------------------------------------

         if(m_trailTPEnabled && m_originalTP > 0.0)
         {
            double extensionUSD = escalones * m_trailStepIncrease;
            double extensionPrecio = USDToPrecio(extensionUSD, volumen);

            newTP = m_originalTP + extensionPrecio;
         }
         else
         {
            newTP = tpActual;
         }
      }
      else
      {
         newSL = entrada - lockedPrecio;

         //--------------------------------------------------
         // TP se extiende si la tendencia continua
         //--------------------------------------------------

         if(m_trailTPEnabled && m_originalTP > 0.0)
         {
            double extensionUSD = escalones * m_trailStepIncrease;
            double extensionPrecio = USDToPrecio(extensionUSD, volumen);

            newTP = m_originalTP - extensionPrecio;
         }
         else
         {
            newTP = tpActual;
         }
      }

      //--------------------------------------------------
      // Guard: solo mejorar SL, nunca retroceder
      //--------------------------------------------------

      if(esCompra && newSL <= slActual)
      {
         Print("TRAILING: nuevo SL ", DoubleToString(newSL, 5),
               " no mejora el actual ", DoubleToString(slActual, 5),
               " -> sin movimiento (solo mejora)");
         newSL = slActual;
      }

      if(!esCompra && newSL >= slActual)
      {
         Print("TRAILING: nuevo SL ", DoubleToString(newSL, 5),
               " no mejora el actual ", DoubleToString(slActual, 5),
               " -> sin movimiento (solo mejora)");
         newSL = slActual;
      }

      //--------------------------------------------------
      // Guard: solo extender TP, nunca reducir
      //--------------------------------------------------

      if(esCompra && newTP <= tpActual)
         newTP = tpActual;

      if(!esCompra && newTP >= tpActual)
         newTP = tpActual;

      //--------------------------------------------------
      // Guard: respetar stops level del broker
      //--------------------------------------------------

      double punto = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

      double stopsLevel =
         (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * punto;
      double freezeLevel =
         (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL) * punto;

      double minDist = MathMax(stopsLevel, freezeLevel);

      double precioReferencia = esCompra
         ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
         : SymbolInfoDouble(_Symbol, SYMBOL_ASK);

      if(MathAbs(precioReferencia - newSL) < minDist)
      {
         Print("TRAILING: nuevo SL ", DoubleToString(newSL, 5),
               " a menos de ", DoubleToString(minDist / punto, 2),
               " puntos del mercado -> sin movimiento (stops level)");
         newSL = slActual;
      }

      if(MathAbs(precioReferencia - newTP) < minDist)
      {
         Print("TRAILING: nuevo TP ", DoubleToString(newTP, 5),
               " a menos de ", DoubleToString(minDist / punto, 2),
               " puntos del mercado -> sin movimiento (stops level)");
         newTP = tpActual;
      }

      //--------------------------------------------------
      // Ejecutar modificacion solo si algo cambio
      //--------------------------------------------------

      if(newSL != slActual || newTP != tpActual)
      {
         if(m_execution.ModifySL(newSL, newTP))
         {
            if(newSL != slActual)
            {
               Print("TRAILING SL: movido a ",
                     DoubleToString(newSL, 5),
                     " (protege ",
                     DoubleToString(MathAbs(newSL - entrada), 5),
                     " precio / ",
                     DoubleToString(lockedUSD, 2),
                     " USD)");
            }

            if(newTP != tpActual)
            {
               Print("TRAILING TP: extendido a ",
                     DoubleToString(newTP, 5),
                     " (extension ",
                     DoubleToString(MathAbs(newTP - m_originalTP), 5),
                     " precio / ",
                     DoubleToString(escalones * m_trailStepIncrease, 2),
                     " USD)");
            }
         }
      }
   }

public:

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

   CTPTradeManager()
   {
      m_alertaSonido         = true;
      m_trailMinProfit       = 0.0;
      m_trailBreakevenOffset = 1.0;
      m_trailStep            = 5.0;
      m_trailStepIncrease    = 5.0;
      m_trailTPEnabled       = true;
      m_maxSL                = 0.0;
      m_originalTP           = 0.0;
      m_tpStored             = false;
       m_ultimoEscalonLog     = -1.0;
       m_logueadoUmbral       = false;
       m_magicNumber          = 0;
   }

   //--------------------------------------------------
   // Inicialización
   //--------------------------------------------------

   bool Initialize(
      long   magicNumber,
      bool   alertaSonido       = true,
      double trailMinProfit     = 0.0,
      double trailBreakevenOffset = 1.0,
      double trailStep          = 5.0,
      double trailStepIncrease  = 5.0,
      bool   trailTP            = true,
      double maxSL              = 0.0)
   {
      m_execution.SetMagicNumber(magicNumber);
      m_magicNumber = magicNumber;

      m_alertaSonido         = alertaSonido;
      m_trailMinProfit       = trailMinProfit;
      m_trailBreakevenOffset = trailBreakevenOffset;
      m_trailStep            = trailStep;
      m_trailStepIncrease    = trailStepIncrease;
      m_trailTPEnabled       = trailTP;
      m_maxSL                = maxSL;

      m_originalTP = 0.0;
      m_tpStored   = false;
      m_ultimoEscalonLog = -1.0;
      m_logueadoUmbral   = false;

      Print("TradeManager inicializado.");

      if(m_trailMinProfit > 0.0)
      {
         Print("Trailing activo: min=",
               DoubleToString(m_trailMinProfit, 2),
               " offset=",
               DoubleToString(m_trailBreakevenOffset, 2),
               " step=",
               DoubleToString(m_trailStep, 2),
               " increase=",
               DoubleToString(m_trailStepIncrease, 2),
               " TP=",
               (m_trailTPEnabled ? "SI" : "NO"));
      }

      if(m_maxSL > 0.0)
      {
         Print("MaxSL activo: $",
               DoubleToString(m_maxSL, 2),
               " USD");
      }

      return true;
   }

   //--------------------------------------------------
   // Trailing por tick: evalua y protege ganancia en CADA tick
   // (independiente del cierre de vela; solo actua sobre posicion existente)
   //--------------------------------------------------

   void ActualizarTrailing()
   {
      if(!PositionSelect(_Symbol))
         return;

      if(m_trailMinProfit <= 0.0)
         return;

      TrailingGanancia();
   }

   //--------------------------------------------------
   // Actualización
   //--------------------------------------------------

   bool Update(
      const CTPSignalManager &signals,
      const CTPMarketState &marketState,
      CTPRiskManager &risk,
      double buySL,
      double sellSL,
      double buyTP,
      double sellTP)
   {
       //--------------------------------------------------
      // Ya existe una posición
      //--------------------------------------------------

       if(PositionSelect(_Symbol))
       {
          //--------------------------------------------------
          // Salida por agotamiento (modo 3):
          // posición propia + patrón CONTRARIO confirmado
          //--------------------------------------------------

          ulong propio = TicketPosicionPropia();

          if(propio != 0 && PositionSelectByTicket(propio))
          {
             long tipo = PositionGetInteger(POSITION_TYPE);

              bool agotamiento =
                 (tipo == POSITION_TYPE_BUY  && signals.PatronBajistaConfirmado()) ||
                 (tipo == POSITION_TYPE_SELL && signals.PatronAlcistaConfirmado());

              if(agotamiento)
              {
                 Print("SALIDA POR AGOTAMIENTO: patrón de ",
                       signals.UltimoPatron(),
                       " clausura dirección");

                 if(m_execution.CloseByTicket(propio))
                 {
                    if(m_alertaSonido)
                       Alert("TradePilot: posición cerrada por agotamiento (",
                             signals.UltimoPatron(), ")");
                 }

                 return true;   // sin trailing esta vela
              }

              //--------------------------------------------------
              // Freno mixto: inversión de dirección confirmada de la
              // tendencia (modo 3). Complementa al agotamiento por patrón:
              // detecta giros que NO forman patrón de vela contrario.
              // Asume que el MarketState solo afirma tendencia con
              // ADX>=20 + EMA20/50 + DMI alineados (filtro anti-whiplash),
              // y exige que el TF superior no sostenga la dirección original.
              //--------------------------------------------------

              if(signals.SalidaPatronActiva())
              {
                 bool inversion =
                    (tipo == POSITION_TYPE_BUY  && marketState.IsBearTrend() && !marketState.IsHtfBull()) ||
                    (tipo == POSITION_TYPE_SELL && marketState.IsBullTrend() && !marketState.IsHtfBear());

                 if(inversion)
                 {
                    Print("SALIDA POR INVERSIÓN: la tendencia giró en contra de la posición");

                    if(m_execution.CloseByTicket(propio))
                    {
                       if(m_alertaSonido)
                          Alert("TradePilot: posición cerrada por inversión de tendencia");
                    }

                    return true;   // sin trailing esta vela
                 }
              }
           }



           return true;   // posicion gestionada: trailing ya se evalua por tick
        }

      //--------------------------------------------------
      // No hay posición: resetear estado del trailing TP
      //--------------------------------------------------

      m_tpStored  = false;
      m_originalTP = 0.0;

      //--------------------------------------------------
      // Validar riesgo
      //--------------------------------------------------

      if(!risk.CanOpenTrade())
      {
         Print("Trade bloqueado por RiskManager.");
         return true;
      }

      //--------------------------------------------------
      // BUY
      //--------------------------------------------------

      if(signals.Buy())
      {
         Print(">>> BUY SIGNAL");

         //--------------------------------------------------
         // Fail-safe: sin SL estructural no se envía la orden
         //--------------------------------------------------

         if(buySL <= 0.0)
         {
            Print("ORDEN BLOQUEADA: SL estructural inválido para BUY (", buySL, ").");

            return false;
         }

         //--------------------------------------------------
         // Fail-safe: sin TP estructural no se envía la orden
         //--------------------------------------------------

         if(buyTP <= 0.0)
         {
            Print("ORDEN BLOQUEADA: TP estructural inválido para BUY (", buyTP, ").");

            return false;
         }

         //--------------------------------------------------
         // MaxSL: cap del SL si excede el limite (USD)
         //--------------------------------------------------

         if(m_maxSL > 0.0)
         {
            double entrada  = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            double punto    = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
            double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
            double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
            double volumen  = risk.Volume();

            if(tickSize > 0.0 && tickValue > 0.0 && volumen > 0.0)
            {
               double distanciaPrecio = entrada - buySL;

               double perdidaUSD =
                  distanciaPrecio / tickSize * volumen * tickValue;

               if(perdidaUSD > m_maxSL)
               {
                  double nuevaDistancia =
                     m_maxSL * tickSize / (volumen * tickValue);

                  double slOriginal = buySL;

                  buySL = entrada - nuevaDistancia;

                  Print("MaxSL BUY: $",
                        DoubleToString(perdidaUSD, 2),
                        " → $",
                        DoubleToString(m_maxSL, 2),
                        " (",
                        DoubleToString(slOriginal, 5),
                        " → ",
                        DoubleToString(buySL, 5),
                        ")");
               }
            }
         }

          bool ok =
             m_execution.Buy(
                risk.Volume(),
                buySL,
                buyTP,
                signals.CommentBuy());

         if(ok)
         {
            risk.RegisterTrade();

            if(m_alertaSonido)
            {
               PlaySound("alert.wav");
               Alert("TradePilot: orden BUY ejecutada");
            }
         }

         return ok;
      }

      //--------------------------------------------------
      // SELL
      //--------------------------------------------------

      if(signals.Sell())
      {
         Print(">>> SELL SIGNAL");

         //--------------------------------------------------
         // Fail-safe: sin SL estructural no se envía la orden
         //--------------------------------------------------

         if(sellSL <= 0.0)
         {
            Print("ORDEN BLOQUEADA: SL estructural inválido para SELL (", sellSL, ").");

            return false;
         }

         //--------------------------------------------------
         // Fail-safe: sin TP estructural no se envía la orden
         //--------------------------------------------------

         if(sellTP <= 0.0)
         {
            Print("ORDEN BLOQUEADA: TP estructural inválido para SELL (", sellTP, ").");

            return false;
         }

         //--------------------------------------------------
         // MaxSL: cap del SL si excede el limite (USD)
         //--------------------------------------------------

         if(m_maxSL > 0.0)
         {
            double entrada  = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            double punto    = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
            double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
            double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
            double volumen  = risk.Volume();

            if(tickSize > 0.0 && tickValue > 0.0 && volumen > 0.0)
            {
               double distanciaPrecio = sellSL - entrada;

               double perdidaUSD =
                  distanciaPrecio / tickSize * volumen * tickValue;

               if(perdidaUSD > m_maxSL)
               {
                  double nuevaDistancia =
                     m_maxSL * tickSize / (volumen * tickValue);

                  double slOriginal = sellSL;

                  sellSL = entrada + nuevaDistancia;

                  Print("MaxSL SELL: $",
                        DoubleToString(perdidaUSD, 2),
                        " → $",
                        DoubleToString(m_maxSL, 2),
                        " (",
                        DoubleToString(slOriginal, 5),
                        " → ",
                        DoubleToString(sellSL, 5),
                        ")");
               }
            }
         }

          bool ok =
             m_execution.Sell(
                risk.Volume(),
                sellSL,
                sellTP,
                signals.CommentSell());

         if(ok)
         {
            risk.RegisterTrade();

            if(m_alertaSonido)
            {
               PlaySound("alert.wav");
               Alert("TradePilot: orden SELL ejecutada");
            }
         }

         return ok;
      }

      return true;
   }

   //--------------------------------------------------
   // Cierre total de posiciones propias (HARD STOP)
   // Itera en orden inverso: al cerrar se reindexan las restantes
   //--------------------------------------------------

   void CerrarTodasPropias()
   {
      int total = PositionsTotal();
      int cerradas = 0;

      for(int i = total - 1; i >= 0; i--)
      {
         ulong ticket = PositionGetTicket(i);

         if(ticket == 0)
            continue;

         if(!PositionSelectByTicket(ticket))
            continue;

         long  posMagic   = PositionGetInteger(POSITION_MAGIC);
         string posSymbol = PositionGetString(POSITION_SYMBOL);

         if(posMagic != m_magicNumber || posSymbol != _Symbol)
            continue;

         if(m_execution.CloseByTicket(ticket))
            cerradas++;
      }

      Print("HARD STOP: posiciones cerradas: ",
            cerradas, " (de ", total, " en el simbolo).");
   }

   //--------------------------------------------------
   // Finalización
   //--------------------------------------------------

   void Shutdown()
   {
      Print("TradeManager detenido.");
   }

};

#endif