#ifndef __TP_DELTAFLOW_MQH__
#define __TP_DELTAFLOW_MQH__

#include "../Market/TP_PriceSeries.mqh"

//+------------------------------------------------------------------+
//| Flujo de liquidez aproximado sobre tick volume                   |
//|                                                                  |
//| delta = Suma( +vol si close > close_prev ; -vol si no )          |
//| sobre las ultimas N velas cerradas.                              |
//|                                                                  |
//| PROXY: sin datos de bid/ask por tick, la direccion de cierre de  |
//| cada vela aproxima el lado dominante. Sirve como feature de      |
//| divergencia (precio vs flujo) para el scorer.                    |
//+------------------------------------------------------------------+
class CTPDeltaFlow
{
private:

   double m_delta;
   double m_deltaPrev;
   double m_volumenTotal;

   double m_precioBajoAct;
   double m_precioBajoPrev;
   double m_precioAltoAct;
   double m_precioAltoPrev;

public:

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

   CTPDeltaFlow()
   {
      m_delta        = 0.0;
      m_deltaPrev    = 0.0;
      m_volumenTotal = 0.0;

      m_precioBajoAct  = DBL_MAX;
      m_precioBajoPrev = DBL_MAX;
      m_precioAltoAct  = 0.0;
      m_precioAltoPrev = 0.0;
   }

   //--------------------------------------------------
   // Actualizar delta sobre las ultimas N velas cerradas
   //--------------------------------------------------

   void Update(const CTPPriceSeries &prices, int periodo)
   {
      m_delta        = 0.0;
      m_deltaPrev    = 0.0;
      m_volumenTotal = 0.0;

      m_precioBajoAct  = DBL_MAX;
      m_precioBajoPrev = DBL_MAX;
      m_precioAltoAct  = 0.0;
      m_precioAltoPrev = 0.0;

      int bars = prices.Bars();

      if(bars < (periodo * 2 + 1))
         return;

      //--------------------------------------------------
      // Ventana actual (velas cerradas: shift 1..periodo)
      //--------------------------------------------------

      for(int i=1; i<=periodo; i++)
      {
         double close = prices.Close(i);
         double prevC = prices.Close(i+1);
         double vol   = (double)prices.TickVolume(i);

         if(close > prevC)
            m_delta += vol;
         else
            m_delta -= vol;

         m_volumenTotal += vol;

         if(prices.Low(i)  < m_precioBajoAct)
            m_precioBajoAct = prices.Low(i);

         if(prices.High(i) > m_precioAltoAct)
            m_precioAltoAct = prices.High(i);
      }

      //--------------------------------------------------
      // Ventana previa (para divergencia)
      //--------------------------------------------------

      for(int i=periodo+1; i<=periodo*2; i++)
      {
         double close = prices.Close(i);
         double prevC = prices.Close(i+1);
         double vol   = (double)prices.TickVolume(i);

         if(close > prevC)
            m_deltaPrev += vol;
         else
            m_deltaPrev -= vol;

         if(prices.Low(i)  < m_precioBajoPrev)
            m_precioBajoPrev = prices.Low(i);

         if(prices.High(i) > m_precioAltoPrev)
            m_precioAltoPrev = prices.High(i);
      }
   }

   //--------------------------------------------------
   // Delta bruto
   //--------------------------------------------------

   double Delta() const
   {
      return m_delta;
   }

   //--------------------------------------------------
   // Delta normalizado a [-1,1] por el volumen total
   //--------------------------------------------------

   double DeltaNorm() const
   {
      if(m_volumenTotal <= 0.0)
         return 0.0;

      return m_delta / m_volumenTotal;
   }

   //--------------------------------------------------
   // Precio hace minimo nuevo pero el flujo NO confirma
   // (agotamiento bajista)
   //--------------------------------------------------

   bool DivergenciaAlcista() const
   {
      return (m_precioBajoPrev < DBL_MAX &&
              m_precioBajoAct  < m_precioBajoPrev &&
              m_delta          > m_deltaPrev);
   }

   //--------------------------------------------------
   // Precio hace maximo nuevo pero el flujo NO confirma
   // (agotamiento alcista)
   //--------------------------------------------------

   bool DivergenciaBajista() const
   {
      return (m_precioAltoPrev > 0.0 &&
              m_precioAltoAct  > m_precioAltoPrev &&
              m_delta          < m_deltaPrev);
   }
};

#endif