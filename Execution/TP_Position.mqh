#ifndef __TP_POSITION_MQH__
#define __TP_POSITION_MQH__

//+------------------------------------------------------------------+
//| Representa una posición abierta                                  |
//+------------------------------------------------------------------+
class CTPPosition
{
private:

   ulong  m_ticket;
   double m_volume;
   double m_openPrice;
   double m_stopLoss;
   double m_takeProfit;
   double m_profit;

public:

   CTPPosition()
   {
      m_ticket     = 0;
      m_volume     = 0.0;
      m_openPrice  = 0.0;
      m_stopLoss   = 0.0;
      m_takeProfit = 0.0;
      m_profit     = 0.0;
   }

   void LoadCurrent()
   {
      if(!PositionSelect(_Symbol))
         return;

      m_ticket     = (ulong)PositionGetInteger(POSITION_TICKET);
      m_volume     = PositionGetDouble(POSITION_VOLUME);
      m_openPrice  = PositionGetDouble(POSITION_PRICE_OPEN);
      m_stopLoss   = PositionGetDouble(POSITION_SL);
      m_takeProfit = PositionGetDouble(POSITION_TP);
      m_profit     = PositionGetDouble(POSITION_PROFIT);
   }

   bool Exists() const
   {
      return (m_ticket != 0);
   }

   ulong Ticket() const      { return m_ticket;      }
   double Volume() const     { return m_volume;      }
   double OpenPrice() const  { return m_openPrice;   }
   double StopLoss() const   { return m_stopLoss;    }
   double TakeProfit() const { return m_takeProfit;  }
   double Profit() const     { return m_profit;      }
};

#endif