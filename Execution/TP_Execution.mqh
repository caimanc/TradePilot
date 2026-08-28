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
   // antes de abrir la posición
   //--------------------------------------------------

   bool ValidarSLParaApertura(bool esCompra, double sl)
   {
      if(sl <= 0.0)
      {
         Print("ORDEN BLOQUEADA: SL inválido (", sl, ").");

         return false;
      }

      double punto =
         SymbolInfoDouble(_Symbol, SYMBOL_POINT);

      double precioReferencia = esCompra ?
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
            " puntos del mercado (mínimo del bróker: ",
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