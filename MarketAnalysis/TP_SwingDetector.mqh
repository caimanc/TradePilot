#ifndef __TP_SWINGDETECTOR_MQH__
#define __TP_SWINGDETECTOR_MQH__

//+------------------------------------------------------------------+
//| Detector de Swings                                               |
//+------------------------------------------------------------------+
class CTPSwingDetector
{
private:

   double m_lastHigh;
   double m_lastLow;

public:

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

   CTPSwingDetector()
   {
      m_lastHigh = 0.0;
      m_lastLow  = 0.0;
   }

   //--------------------------------------------------
   // Inicialización
   //--------------------------------------------------

   bool Initialize()
   {
      Print("SwingDetector inicializado.");

      return true;
   }

   //--------------------------------------------------
   // Actualizar
   //--------------------------------------------------

   bool Update()
   {
      m_lastHigh = iHigh(_Symbol,_Period,1);
      m_lastLow  = iLow(_Symbol,_Period,1);

      return true;
   }

   //--------------------------------------------------
   // Getters
   //--------------------------------------------------

   double LastHigh() const
   {
      return m_lastHigh;
   }

   double LastLow() const
   {
      return m_lastLow;
   }

   //--------------------------------------------------
   // Shutdown
   //--------------------------------------------------

   void Shutdown()
   {
      Print("SwingDetector detenido.");
   }

};

#endif