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
   long   m_magic;

public:

   CTPExecution()
   {
      m_magic = 0;
   }

   //--------------------------------------------------
   // Configurar Magic Number
   //--------------------------------------------------

   void SetMagicNumber(long magic)
   {
      m_magic = magic;
      m_trade.SetExpertMagicNumber(magic);
   }

   //--------------------------------------------------
   // Validar SL contra restricciones del bróker
   // antes de abrir la posición (o colocar la pendiente)
   //--------------------------------------------------

   bool ValidarSLParaApertura(bool esCompra, double sl,
                              double precioReferencia = 0.0)
   {
      if(sl <= 0.0)
      {
         Print("ORDEN BLOQUEADA: SL inválido (", sl, ").");

         return false;
      }

      double punto =
         SymbolInfoDouble(_Symbol, SYMBOL_POINT);

      if(precioReferencia <= 0.0)
         precioReferencia = esCompra ?
            SymbolInfoDouble(_Symbol, SYMBOL_BID) :
            SymbolInfoDouble(_Symbol, SYMBOL_ASK);

      double stopsLevel =
         (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * punto;
      double freezeLevel =
         (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL) * punto;

      double distancia = MathAbs(precioReferencia - sl);

      if(distancia < stopsLevel || distancia < freezeLevel)
      {
         Print(
            "ORDEN BLOQUEADA: SL a ", distancia / punto,
            " puntos del precio de referencia (mínimo del bróker: ",
            MathMax(stopsLevel, freezeLevel) / punto, " puntos).");

         return false;
      }

      return true;
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
      if(!ValidarSLParaApertura(true, sl))
         return false;

      bool result =
         m_trade.Buy(
            volume,
            _Symbol,
            0.0,
            sl,
            tp,
            comment);

      if(result)
         Print("BUY ejecutado. Ticket=", m_trade.ResultOrder(),
               " Retcode=", m_trade.ResultRetcode());
      else
         Print("ERROR BUY: Retcode=", m_trade.ResultRetcode(),
               " (", m_trade.ResultRetcodeDescription(), ")");

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
      if(!ValidarSLParaApertura(false, sl))
         return false;

      bool result =
         m_trade.Sell(
            volume,
            _Symbol,
            0.0,
            sl,
            tp,
            comment);

      if(result)
         Print("SELL ejecutado. Ticket=", m_trade.ResultOrder(),
               " Retcode=", m_trade.ResultRetcode());
      else
         Print("ERROR SELL: Retcode=", m_trade.ResultRetcode(),
               " (", m_trade.ResultRetcodeDescription(), ")");

      return result;
   }

   //--------------------------------------------------
   // BUY LIMIT (orden pendiente: entra cuando el precio BAJA)
   //--------------------------------------------------

   bool BuyLimit(
      double volume,
      double price,
      double sl,
      double tp,
      string comment = "TradePilot BUY LIMIT")
   {
      if(!ValidarSLParaApertura(true, sl, price))
         return false;

      bool result =
         m_trade.BuyLimit(
            volume,
            price,
            _Symbol,
            sl,
            tp,
            ORDER_TIME_GTC,
            0,
            comment);

      if(result)
         Print("BUY LIMIT colocada en ", DoubleToString(price, 5),
               ". Ticket=", m_trade.ResultOrder(),
               " Retcode=", m_trade.ResultRetcode());
      else
         Print("ERROR BUY LIMIT: Retcode=", m_trade.ResultRetcode(),
               " (", m_trade.ResultRetcodeDescription(), ")");

      return result;
   }

   //--------------------------------------------------
   // SELL LIMIT (orden pendiente: entra cuando el precio SUBE)
   //--------------------------------------------------

   bool SellLimit(
      double volume,
      double price,
      double sl,
      double tp,
      string comment = "TradePilot SELL LIMIT")
   {
      if(!ValidarSLParaApertura(false, sl, price))
         return false;

      bool result =
         m_trade.SellLimit(
            volume,
            price,
            _Symbol,
            sl,
            tp,
            ORDER_TIME_GTC,
            0,
            comment);

      if(result)
         Print("SELL LIMIT colocada en ", DoubleToString(price, 5),
               ". Ticket=", m_trade.ResultOrder(),
               " Retcode=", m_trade.ResultRetcode());
      else
         Print("ERROR SELL LIMIT: Retcode=", m_trade.ResultRetcode(),
               " (", m_trade.ResultRetcodeDescription(), ")");

      return result;
   }

   //--------------------------------------------------
   // BUY STOP (orden pendiente: entra cuando el precio SUBE - ruptura)
   //--------------------------------------------------

   bool BuyStop(
      double volume,
      double price,
      double sl,
      double tp,
      string comment = "TradePilot BUY STOP")
   {
      if(!ValidarSLParaApertura(true, sl, price))
         return false;

      bool result =
         m_trade.BuyStop(
            volume,
            price,
            _Symbol,
            sl,
            tp,
            ORDER_TIME_GTC,
            0,
            comment);

      if(result)
         Print("BUY STOP colocada en ", DoubleToString(price, 5),
               ". Ticket=", m_trade.ResultOrder(),
               " Retcode=", m_trade.ResultRetcode());
      else
         Print("ERROR BUY STOP: Retcode=", m_trade.ResultRetcode(),
               " (", m_trade.ResultRetcodeDescription(), ")");

      return result;
   }

   //--------------------------------------------------
   // SELL STOP (orden pendiente: entra cuando el precio BAJA - ruptura)
   //--------------------------------------------------

   bool SellStop(
      double volume,
      double price,
      double sl,
      double tp,
      string comment = "TradePilot SELL STOP")
   {
      if(!ValidarSLParaApertura(false, sl, price))
         return false;

      bool result =
         m_trade.SellStop(
            volume,
            price,
            _Symbol,
            sl,
            tp,
            ORDER_TIME_GTC,
            0,
            comment);

      if(result)
         Print("SELL STOP colocada en ", DoubleToString(price, 5),
               ". Ticket=", m_trade.ResultOrder(),
               " Retcode=", m_trade.ResultRetcode());
      else
         Print("ERROR SELL STOP: Retcode=", m_trade.ResultRetcode(),
               " (", m_trade.ResultRetcodeDescription(), ")");

      return result;
   }

   //--------------------------------------------------
   // Cancelar orden pendiente por ticket (solo propia)
   //--------------------------------------------------

   bool CancelOrder(ulong ticket)
   {
      if(!OrderSelect(ticket))
      {
         Print("CANCEL: orden ", ticket, " no encontrada.");
         return false;
      }

      long  orderMagic   = OrderGetInteger(ORDER_MAGIC);
      string orderSymbol = OrderGetString(ORDER_SYMBOL);

      if(orderMagic != m_magic || orderSymbol != _Symbol)
      {
         Print("CANCEL BLOQUEADO: orden ", ticket,
               " no es propia (magic=", orderMagic,
               " símbolo=", orderSymbol, ").");
         return false;
      }

      bool result = m_trade.OrderDelete(ticket);

      if(result)
         Print("ORDEN cancelada: ", ticket);
      else
         Print("ERROR CANCEL orden ", ticket,
               ": Retcode=", m_trade.ResultRetcode(),
               " (", m_trade.ResultRetcodeDescription(), ")");

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

   //--------------------------------------------------
   // Cerrar posición por ticket (solo posición propia)
   // Re-verifica magic y símbolo ANTES de cerrar:
   // nunca asumir la correspondencia del ticket.
   //--------------------------------------------------

   bool CloseByTicket(ulong ticket)
   {
      if(!PositionSelectByTicket(ticket))
      {
         Print("CLOSE: posición ticket ", ticket, " no encontrada.");
         return false;
      }

      long  posMagic   = PositionGetInteger(POSITION_MAGIC);
      string posSymbol = PositionGetString(POSITION_SYMBOL);

      if(posMagic != m_magic || posSymbol != _Symbol)
      {
         Print("CLOSE BLOQUEADO: ticket ", ticket,
               " no es posición propia (magic=", posMagic,
               " símbolo=", posSymbol, ").");
         return false;
      }

      bool result = m_trade.PositionClose(ticket);

      if(result)
         Print("CLOSE ticket ", ticket, " cerrado correctamente.");
      else
         Print("ERROR CLOSE ticket ", ticket,
               ": Retcode=", m_trade.ResultRetcode(),
               " (", m_trade.ResultRetcodeDescription(), ")");

      return result;
   }

   //--------------------------------------------------
   // Modificar SL de posición existente
   //--------------------------------------------------

   bool ModifySL(double newSL, double tp)
   {
      if(!PositionSelect(_Symbol))
      {
         Print("MODIFY: No hay posición abierta.");
         return false;
      }

      bool result = m_trade.PositionModify(_Symbol, newSL, tp);

      if(result)
         Print("MODIFY SL: ", DoubleToString(newSL, 5), " OK");
      else
         Print("ERROR MODIFY: Retcode=", m_trade.ResultRetcode(),
               " (", m_trade.ResultRetcodeDescription(), ")");

      return result;
   }
};

#endif