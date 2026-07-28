#ifndef __TP_POSITIONSIZER_MQH__
#define __TP_POSITIONSIZER_MQH__

//+------------------------------------------------------------------+
//| Calculador de tamaño de posición                                 |
//+------------------------------------------------------------------+
class CTPPositionSizer
{
private:

   double m_riskPercent;
   double m_volume;

public:

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

   CTPPositionSizer()
   {
      m_riskPercent = 1.0;
      m_volume = 0.01;
   }

   //--------------------------------------------------
   // Inicialización
   //--------------------------------------------------

   bool Initialize()
   {
      Print("PositionSizer inicializado.");

      return true;
   }

   //--------------------------------------------------
   // Configurar riesgo
   //--------------------------------------------------

   void SetRiskPercent(double risk)
   {
      m_riskPercent = risk;
   }

   //--------------------------------------------------
   // Calcular volumen
   //--------------------------------------------------

   bool Calculate()
   {
      //--------------------------------------------------
      // Temporal
      //--------------------------------------------------

      m_volume = 0.01;

      return true;
   }

   //--------------------------------------------------
   // Obtener volumen
   //--------------------------------------------------

   double Volume() const
   {
      return m_volume;
   }

   //--------------------------------------------------
   // Shutdown
   //--------------------------------------------------

   void Shutdown()
   {
      Print("PositionSizer detenido.");
   }

};

#endif