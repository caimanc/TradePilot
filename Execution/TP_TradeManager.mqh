#ifndef __TP_TRADEMANAGER_MQH__
#define __TP_TRADEMANAGER_MQH__

#include "TP_Execution.mqh"
#include "../Signals/TP_SignalManager.mqh"
#include "../Risk/TP_RiskManager.mqh"

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
   bool   m_trailTPEnabled;
   double m_maxSL;

   //--------------------------------------------------
   // TP original de la posicion actual
   //--------------------------------------------------

   double m_originalTP;
   bool   m_tpStored;

   //--------------------------------------------------
   // Trailing logic
   //--------------------------------------------------

   void TrailingGanancia()
   {
      if(m_trailMinProfit <= 0.0)
         return;

      if(!PositionSelect(_Symbol))
         return;

      long tipo = PositionGetInteger(POSITION_TYPE);

      double entrada  = PositionGetDouble(POSITION_PRICE_OPEN);
      double slActual = PositionGetDouble(POSITION_SL);
      double tpActual = PositionGetDouble(POSITION_TP);

      //--------------------------------------------------
      // Guardar TP original la primera vez
      //--------------------------------------------------

      if(!m_tpStored && tpActual > 0.0)
      {
         m_originalTP = tpActual;
         m_tpStored   = true;
      }

      double profitActual = 0.0;

      if(tipo == POSITION_TYPE_BUY)
         profitActual = SymbolInfoDouble(_Symbol, SYMBOL_BID) - entrada;
      else
         profitActual = entrada - SymbolInfoDouble(_Symbol, SYMBOL_ASK);

      if(profitActual < m_trailMinProfit)
         return;

      //--------------------------------------------------
      // Calcular ganancia protegida
      //--------------------------------------------------

      double locked = m_trailBreakevenOffset +
         MathFloor((profitActual - m_trailMinProfit) / m_trailStep) *
         m_trailStep;

      double newSL = 0.0;
      double newTP = 0.0;

      if(tipo == POSITION_TYPE_BUY)
      {
         newSL = entrada + locked;

         //--------------------------------------------------
         // TP se extiende si la tendencia continua
         //--------------------------------------------------

         if(m_trailTPEnabled && m_originalTP > 0.0)
         {
            double extension =
               MathFloor((profitActual - m_trailMinProfit) / m_trailStep) *
               m_trailStep;

            newTP = m_originalTP + extension;
         }
         else
         {
            newTP = tpActual;
         }
      }
      else
      {
         newSL = entrada - locked;

         //--------------------------------------------------
         // TP se extiende si la tendencia continua
         //--------------------------------------------------

         if(m_trailTPEnabled && m_originalTP > 0.0)
         {
            double extension =
               MathFloor((profitActual - m_trailMinProfit) / m_trailStep) *
               m_trailStep;

            newTP = m_originalTP - extension;
         }
         else
         {
            newTP = tpActual;
         }
      }

      //--------------------------------------------------
      // Guard: solo mejorar SL, nunca retroceder
      //--------------------------------------------------

      if(tipo == POSITION_TYPE_BUY && newSL <= slActual)
         newSL = slActual;

      if(tipo == POSITION_TYPE_SELL && newSL >= slActual)
         newSL = slActual;

      //--------------------------------------------------
      // Guard: solo extender TP, nunca reducir
      //--------------------------------------------------

      if(tipo == POSITION_TYPE_BUY && newTP <= tpActual)
         newTP = tpActual;

      if(tipo == POSITION_TYPE_SELL && newTP >= tpActual)
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

      double precioReferencia = (tipo == POSITION_TYPE_BUY)
         ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
         : SymbolInfoDouble(_Symbol, SYMBOL_ASK);

      if(MathAbs(precioReferencia - newSL) < minDist)
         newSL = slActual;

      if(MathAbs(precioReferencia - newTP) < minDist)
         newTP = tpActual;

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
                     DoubleToString(locked, 2),
                     " USD)");
            }

            if(newTP != tpActual)
            {
               Print("TRAILING TP: extendido a ",
                     DoubleToString(newTP, 5),
                     " (extension ",
                     DoubleToString(MathAbs(newTP - m_originalTP), 2),
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
      m_trailTPEnabled       = true;
      m_maxSL                = 0.0;
      m_originalTP           = 0.0;
      m_tpStored             = false;
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
      bool   trailTP            = true,
      double maxSL              = 0.0)
   {
      m_execution.SetMagicNumber(magicNumber);

      m_alertaSonido         = alertaSonido;
      m_trailMinProfit       = trailMinProfit;
      m_trailBreakevenOffset = trailBreakevenOffset;
      m_trailStep            = trailStep;
      m_trailTPEnabled       = trailTP;
      m_maxSL                = maxSL;

      m_originalTP = 0.0;
      m_tpStored   = false;

      Print("TradeManager inicializado.");

      if(m_trailMinProfit > 0.0)
      {
         Print("Trailing activo: min=",
               DoubleToString(m_trailMinProfit, 2),
               " offset=",
               DoubleToString(m_trailBreakevenOffset, 2),
               " step=",
               DoubleToString(m_trailStep, 2),
               " TP=",
               (m_trailTPEnabled ? "SI" : "NO"));
      }

      if(m_maxSL > 0.0)
      {
         Print("MaxSL activo: ",
               DoubleToString(m_maxSL, 0),
               " puntos");
      }

      return true;
   }

   //--------------------------------------------------
   // Actualización
   //--------------------------------------------------

   bool Update(
      const CTPSignalManager &signals,
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
         TrailingGanancia();
         return true;
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
         // MaxSL: cap del SL si excede el limite
         //--------------------------------------------------

         if(m_maxSL > 0.0)
         {
            double entrada = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            double punto   = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
            double distancia = (entrada - buySL) / punto;

            if(distancia > m_maxSL)
            {
               double slOriginal = buySL;

               buySL = entrada - m_maxSL * punto;

               Print("MaxSL BUY: ",
                     DoubleToString(distancia, 0),
                     " pts → ",
                     DoubleToString(m_maxSL, 0),
                     " pts (",
                     DoubleToString(slOriginal, 5),
                     " → ",
                     DoubleToString(buySL, 5),
                     ")");
            }
         }

         bool ok =
            m_execution.Buy(
               risk.Volume(),
               buySL,
               buyTP);

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
         // MaxSL: cap del SL si excede el limite
         //--------------------------------------------------

         if(m_maxSL > 0.0)
         {
            double entrada = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            double punto   = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
            double distancia = (sellSL - entrada) / punto;

            if(distancia > m_maxSL)
            {
               double slOriginal = sellSL;

               sellSL = entrada + m_maxSL * punto;

               Print("MaxSL SELL: ",
                     DoubleToString(distancia, 0),
                     " pts → ",
                     DoubleToString(m_maxSL, 0),
                     " pts (",
                     DoubleToString(slOriginal, 5),
                     " → ",
                     DoubleToString(sellSL, 5),
                     ")");
            }
         }

         bool ok =
            m_execution.Sell(
               risk.Volume(),
               sellSL,
               sellTP);

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
   // Finalización
   //--------------------------------------------------

   void Shutdown()
   {
      Print("TradeManager detenido.");
   }

};

#endif