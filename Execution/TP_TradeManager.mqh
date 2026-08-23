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

public:

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

   CTPTradeManager()
   {
   }

   //--------------------------------------------------
   // Inicialización
   //--------------------------------------------------

   bool Initialize(long magicNumber)
   {
      m_execution.SetMagicNumber(magicNumber);

      Print("TradeManager inicializado.");

      return true;
   }

   //--------------------------------------------------
   // Actualización
   //--------------------------------------------------

   bool Update(
      const CTPSignalManager &signals,
      CTPRiskManager &risk,
      double buySL,
      double sellSL)
   {
      //--------------------------------------------------
      // Ya existe una posición
      //--------------------------------------------------

      if(PositionSelect(_Symbol))
         return true;

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

         bool ok =
            m_execution.Buy(
               risk.Volume(),
               buySL,
               0.0);

         if(ok)
            risk.RegisterTrade();

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

         bool ok =
            m_execution.Sell(
               risk.Volume(),
               sellSL,
               0.0);

         if(ok)
            risk.RegisterTrade();

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