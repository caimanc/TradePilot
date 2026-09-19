#ifndef __TP_SWEEPDETECTOR_MQH__
#define __TP_SWEEPDETECTOR_MQH__

//+------------------------------------------------------------------+
//| Detector de barrido de liquidez                                  |
//|                                                                  |
//| Un barrido ocurre cuando el precio atraviesa un swing reciente   |
//| (mecha mas alla del nivel) y CIERRA de vuelta dentro del rango,  |
//| dejando liquidez capturada en el otro lado. Se evalua sobre la   |
//| vela actual y la anterior.                                       |
//|   BarridoBajista()  = barred el maximo y cerro debajo: invalida  |
//|                       patrones alcistas.                         |
//|   BarridoAlcista()  = barred el minimo y cerro arriba: invalida  |
//|                       patrones bajistas.                         |
//+------------------------------------------------------------------+
class CTPSweepDetector
{
private:

   double m_prevHigh;
   double m_prevLow;
   double m_prevClose;
   double m_prevOpen;

   bool   m_barridoAlcista;
   bool   m_barridoBajista;

   //--------------------------------------------------
   // Mecha bajo el minimo + cierre restaurado arriba
   //--------------------------------------------------

   bool EsBarridoAlcista(
      double high,
      double low,
      double close,
      double open,
      double lastSwingLow) const
   {
      return (low < lastSwingLow) &&
             (close > lastSwingLow);
   }

   //--------------------------------------------------
   // Mecha sobre el maximo + cierre restaurado abajo
   //--------------------------------------------------

   bool EsBarridoBajista(
      double high,
      double low,
      double close,
      double open,
      double lastSwingHigh) const
   {
      return (high > lastSwingHigh) &&
             (close < lastSwingHigh);
   }

public:

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

   CTPSweepDetector()
   {
      Reset();
   }

   //--------------------------------------------------
   // Actualizar con la vela cerrada en curso
   //--------------------------------------------------

   void Update(
      double high,
      double low,
      double close,
      double open,
      double lastSwingHigh,
      double lastSwingLow)
   {
      m_barridoAlcista = false;
      m_barridoBajista = false;

      if(lastSwingHigh <= 0.0 || lastSwingLow <= 0.0)
         return;

      //--------------------------------------------------
      // Vela actual
      //--------------------------------------------------

      if(EsBarridoAlcista(
            high,
            low,
            close,
            open,
            lastSwingLow))
      {
         m_barridoAlcista = true;
      }

      if(EsBarridoBajista(
            high,
            low,
            close,
            open,
            lastSwingHigh))
      {
         m_barridoBajista = true;
      }

      //--------------------------------------------------
      // Vela anterior (cache)
      //--------------------------------------------------

      if(m_prevLow > 0.0 &&
         m_prevHigh > 0.0 &&
         m_prevClose > 0.0)
      {
         if(EsBarridoAlcista(
               m_prevHigh,
               m_prevLow,
               m_prevClose,
               m_prevOpen,
               lastSwingLow))
         {
            m_barridoAlcista = true;
         }

         if(EsBarridoBajista(
               m_prevHigh,
               m_prevLow,
               m_prevClose,
               m_prevOpen,
               lastSwingHigh))
         {
            m_barridoBajista = true;
         }
      }

      //--------------------------------------------------
      // Cachear la vela actual como anterior
      //--------------------------------------------------

      m_prevHigh  = high;
      m_prevLow   = low;
      m_prevClose = close;
      m_prevOpen  = open;
   }

   //--------------------------------------------------
   // Barrió el minimo y revirtió arriba
   //--------------------------------------------------

   bool BarridoAlcista() const
   {
      return m_barridoAlcista;
   }

   //--------------------------------------------------
   // Barrió el maximo y revirtió abajo
   //--------------------------------------------------

   bool BarridoBajista() const
   {
      return m_barridoBajista;
   }

   //--------------------------------------------------
   // Reset (por vela)
   //--------------------------------------------------

   void Reset()
   {
      m_prevHigh  = 0.0;
      m_prevLow   = 0.0;
      m_prevClose = 0.0;
      m_prevOpen  = 0.0;

      m_barridoAlcista = false;
      m_barridoBajista = false;
   }
};

#endif