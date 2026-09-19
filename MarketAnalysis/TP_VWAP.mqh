#ifndef __TP_VWAP_MQH__
#define __TP_VWAP_MQH__

#include "../Market/TP_PriceSeries.mqh"

//+------------------------------------------------------------------+
//| VWAP anclado al inicio del dia                                   |
//|                                                                  |
//| Promedio de precio tipico ponderado por volumen desde la primera |
//| vela de la sesion (dia del broker). Sirve como filtro            |
//| direccional (precio sobre/debajo) y como objetivo dinamico para  |
//| el take profit.                                                  |
//+------------------------------------------------------------------+
class CTPVWAP
{
private:

   CTPPriceSeries *m_prices;

   double m_precio;
   double m_volumenTotal;
   bool   m_datosSuficientes;

   //--------------------------------------------------
   // Misma sesion (dia del broker)
   //--------------------------------------------------

   bool MismaSesion(datetime t1, datetime t2) const
   {
      MqlDateTime d1;
      MqlDateTime d2;

      TimeToStruct(t1, d1);
      TimeToStruct(t2, d2);

      return (d1.year == d2.year &&
              d1.mon  == d2.mon  &&
              d1.day  == d2.day);
   }

public:

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

   CTPVWAP()
   {
      m_prices = NULL;

      m_precio = 0.0;

      m_volumenTotal = 0.0;

      m_datosSuficientes = false;
   }

   //--------------------------------------------------
   // Referencia a la serie de precios
   //--------------------------------------------------

   void SetPriceSeries(CTPPriceSeries &prices)
   {
      m_prices = GetPointer(prices);
   }

   //--------------------------------------------------
   // Actualizar VWAP de la sesion
   //--------------------------------------------------

   void Update()
   {
      m_precio = 0.0;

      m_volumenTotal = 0.0;

      m_datosSuficientes = false;

      if(m_prices == NULL)
         return;

      int bars = m_prices.Bars();

      if(bars < 2)
         return;

      //--------------------------------------------------
      // Ancla: vela mas antigua del dia actual
      //--------------------------------------------------

      datetime sesion = m_prices.Time(0);

      double sumPV = 0.0;
      double sumV  = 0.0;
      int    contadas = 0;

      for(int shift=0; shift<bars; shift++)
      {
         if(!MismaSesion(m_prices.Time(shift), sesion))
            break;   // fuera del dia actual

         double precioTipico =
            (m_prices.High(shift) +
             m_prices.Low(shift)  +
             m_prices.Close(shift)) / 3.0;

         double vol = (double)m_prices.TickVolume(shift);

         sumPV += precioTipico * vol;

         sumV += vol;

         contadas++;
      }

      if(contadas < 2 || sumV <= 0.0)
         return;   // sin suficientes datos de la sesion

      m_precio = sumPV / sumV;

      m_volumenTotal = sumV;

      m_datosSuficientes = true;
   }

   //--------------------------------------------------
   // Precio del VWAP
   //--------------------------------------------------

   double Precio() const
   {
      return m_precio;
   }

   //--------------------------------------------------
   // Distancia Ask - VWAP
   //--------------------------------------------------

   double DistanciaPrecio() const
   {
      return SymbolInfoDouble(_Symbol, SYMBOL_ASK) - m_precio;
   }

   //--------------------------------------------------
   // Permitir compra: Ask por encima del VWAP
   // Sin datos no bloquea
   //--------------------------------------------------

   bool PermiteCompra(double ask) const
   {
      if(!m_datosSuficientes)
         return true;

      return ask > m_precio;
   }

   //--------------------------------------------------
   // Permitir venta: Bid por debajo del VWAP
   // Sin datos no bloquea
   //--------------------------------------------------

   bool PermiteVenta(double bid) const
   {
      if(!m_datosSuficientes)
         return true;

      return bid < m_precio;
   }
};

#endif