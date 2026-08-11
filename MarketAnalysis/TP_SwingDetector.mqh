#ifndef __TP_SWINGDETECTOR_MQH__
#define __TP_SWINGDETECTOR_MQH__

#include "../Market/TP_PriceSeries.mqh"

//+------------------------------------------------------------------+
//| Detector de estructura de precio                                 |
//+------------------------------------------------------------------+
class CTPSwingDetector
{
private:

   double m_lastSwingHigh;
   double m_lastSwingLow;

   int    m_highShift;
   int    m_lowShift;

   int    m_lookback;

public:

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

   CTPSwingDetector()
   {
      m_lastSwingHigh = 0.0;
      m_lastSwingLow  = 0.0;

      m_highShift = -1;
      m_lowShift  = -1;

      m_lookback = 2;
   }

   //--------------------------------------------------
   // Inicialización
   //--------------------------------------------------

   bool Initialize(int lookback=2)
   {
      if(lookback < 1)
         return false;

      m_lookback = lookback;

      m_lastSwingHigh = 0.0;
      m_lastSwingLow  = 0.0;

      m_highShift = -1;
      m_lowShift  = -1;

      Print("SwingDetector inicializado.");

      return true;
   }

   //--------------------------------------------------
   // Actualización
   //--------------------------------------------------

   bool Update(const CTPPriceSeries &prices)
   {
      int bars = prices.Bars();

      if(bars < (m_lookback * 2 + 3))
         return false;

      m_lastSwingHigh = 0.0;
      m_lastSwingLow  = 0.0;

      m_highShift = -1;
      m_lowShift  = -1;

      //--------------------------------------------------
      // Buscar desde la vela cerrada más reciente
      //--------------------------------------------------

      int start = m_lookback + 1;
      int end   = bars - m_lookback - 1;

      for(int shift=start; shift<=end; shift++)
      {
         //--------------------------------------------------
         // Swing High
         //--------------------------------------------------

         bool swingHigh = true;

         double currentHigh = prices.High(shift);

         for(int i=1; i<=m_lookback; i++)
         {
            if(currentHigh <= prices.High(shift-i))
            {
               swingHigh = false;
               break;
            }

            if(currentHigh <= prices.High(shift+i))
            {
               swingHigh = false;
               break;
            }
         }

         if(swingHigh)
         {
            if(m_highShift == -1 ||
               shift < m_highShift)
            {
               m_lastSwingHigh = currentHigh;
               m_highShift = shift;
            }
         }

         //--------------------------------------------------
         // Swing Low
         //--------------------------------------------------

         bool swingLow = true;

         double currentLow = prices.Low(shift);

         for(int i=1; i<=m_lookback; i++)
         {
            if(currentLow >= prices.Low(shift-i))
            {
               swingLow = false;
               break;
            }

            if(currentLow >= prices.Low(shift+i))
            {
               swingLow = false;
               break;
            }
         }

         if(swingLow)
         {
            if(m_lowShift == -1 ||
               shift < m_lowShift)
            {
               m_lastSwingLow = currentLow;
               m_lowShift = shift;
            }
         }
      }

      return true;
   }

   //--------------------------------------------------
   // Último Swing High
   //--------------------------------------------------

   double LastSwingHigh() const
   {
      return m_lastSwingHigh;
   }

   //--------------------------------------------------
   // Último Swing Low
   //--------------------------------------------------

   double LastSwingLow() const
   {
      return m_lastSwingLow;
   }

   //--------------------------------------------------
   // Shift del Swing High
   //--------------------------------------------------

   int SwingHighShift() const
   {
      return m_highShift;
   }

   //--------------------------------------------------
   // Shift del Swing Low
   //--------------------------------------------------

   int SwingLowShift() const
   {
      return m_lowShift;
   }

   //--------------------------------------------------
   // Lookback
   //--------------------------------------------------

   int Lookback() const
   {
      return m_lookback;
   }

   //--------------------------------------------------
   // Shutdown
   //--------------------------------------------------

   void Shutdown()
   {
      m_lastSwingHigh = 0.0;
      m_lastSwingLow  = 0.0;

      m_highShift = -1;
      m_lowShift  = -1;

      Print("SwingDetector detenido.");
   }
};

#endif