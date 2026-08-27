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

      if(tipo == POSITION_TYPE_BUY)
         newSL = entrada + locked;
      else
         newSL = entrada - locked;

      //--------------------------------------------------
      // Guard: solo mejorar, nunca retroceder
      //--------------------------------------------------

      if(tipo == POSITION_TYPE_BUY && newSL <= slActual)
         return;

      if(tipo == POSITION_TYPE_SELL && newSL >= slActual)
         return;

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
         return;

      //--------------------------------------------------
      // Ejecutar modificacion
      //--------------------------------------------------

      double tpActual = PositionGetDouble(POSITION_TP);

      if(m_execution.ModifySL(newSL, tpActual))
      {
         Print("TRAILING: SL movido a ",
               DoubleToString(newSL, 5),
               " (protege ",
               DoubleToString(locked, 2),
               " USD)");
      }
   }

public:

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

   CTPTradeManager()
   {
      m_alertaSonido        = true;
      m_trailMinProfit      = 0.0;
      m_trailBreakevenOffset = 1.0;
      m_trailStep           = 5.0;
   }

   //--------------------------------------------------
   // Inicialización
   //--------------------------------------------------

   bool Initialize(
      long   magicNumber,
      bool   alertaSonido       = true,
      double trailMinProfit     = 0.0,
      double trailBreakevenOffset = 1.0,
      double trailStep          = 5.0)
   {
      m_execution.SetMagicNumber(magicNumber);

      m_alertaSonido         = alertaSonido;
      m_trailMinProfit       = trailMinProfit;
      m_trailBreakevenOffset = trailBreakevenOffset;
      m_trailStep            = trailStep;

      Print("TradeManager inicializado.");

      if(m_trailMinProfit > 0.0)
      {
         Print("Trailing activo: min=",
               DoubleToString(m_trailMinProfit, 2),
               " offset=",
               DoubleToString(m_trailBreakevenOffset, 2),
               " step=",
               DoubleToString(m_trailStep, 2));
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