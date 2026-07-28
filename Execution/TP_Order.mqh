#ifndef __TP_ORDER_MQH__
#define __TP_ORDER_MQH__

//+------------------------------------------------------------------+
//| Tipos de orden                                                   |
//+------------------------------------------------------------------+
enum ENUM_TP_ORDER_TYPE
{
   TP_ORDER_BUY = 0,
   TP_ORDER_SELL
};

//+------------------------------------------------------------------+
//| Estructura de orden                                              |
//+------------------------------------------------------------------+
struct STPOrder
{
   ENUM_TP_ORDER_TYPE type;

   double volume;
   double stopLoss;
   double takeProfit;
   string comment;
};

#endif