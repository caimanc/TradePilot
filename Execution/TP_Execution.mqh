#ifndef __TP_EXECUTION_MQH__
#define __TP_EXECUTION_MQH__

#include <Trade/Trade.mqh>
#include "TP_Order.mqh"

//+------------------------------------------------------------------+
//| Capa de ejecución de órdenes                                     |
//+------------------------------------------------------------------+
class CTPExecution
{
private:

   CTrade m_trade;

public:

   CTPExecution()
   {
   }

   //--------------------------------------------------
   // Configurar Magic Number
   //--------------------------------------------------

   void SetMagicNumber(long magic)
   {
      m_trade.SetExpertMagicNumber(magic);
   }

   //--------------------------------------------------
   // BUY
   //--------------------------------------------------

   bool Buy(
      double volume,
      double sl,
      double tp,
      string comment = "TradePilot BUY")
   {
      bool result =
         m_trade.Buy(
            volume,
            _Symbol,
            0.0,
            sl,
            tp,
            comment);

      if(result)
         Print("BUY ejecutado correctamente.");
      else
         Print("ERROR BUY: ", GetLastError());

      return result;
   }

   //--------------------------------------------------
   // SELL
   //--------------------------------------------------

   bool Sell(
      double volume,
      double sl,
      double tp,
      string comment = "TradePilot SELL")
   {
      bool result =
         m_trade.Sell(
            volume,
            _Symbol,
            0.0,
            sl,
            tp,
            comment);

      if(result)
         Print("SELL ejecutado correctamente.");
      else
         Print("ERROR SELL: ", GetLastError());

      return result;
   }

   //--------------------------------------------------
   // Cerrar posición actual
   //--------------------------------------------------

   bool Close()
   {
      if(!PositionSelect(_Symbol))
      {
         Print("No hay posición abierta.");
         return false;
      }

      bool result = m_trade.PositionClose(_Symbol);

      if(result)
         Print("Posición cerrada correctamente.");
      else
         Print("ERROR CLOSE: ", GetLastError());

      return result;
   }
};

#endif