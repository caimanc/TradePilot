#ifndef __TP_STOPLOSSCALCULATOR_MQH__
#define __TP_STOPLOSSCALCULATOR_MQH__

//+------------------------------------------------------------------+
//| Calculador de Stop Loss                                          |
//+------------------------------------------------------------------+
class CTPStopLossCalculator
{
private:

   double m_stopLoss;

public:

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

   CTPStopLossCalculator()
   {
      m_stopLoss = 0.0;
   }

   //--------------------------------------------------
   // Inicialización
   //--------------------------------------------------

   bool Initialize()
   {
      Print("StopLossCalculator inicializado.");

      return true;
   }

   //--------------------------------------------------
   // Calcular
   //--------------------------------------------------

   bool Calculate()
   {
      //--------------------------------------------------
      // Temporal
      //--------------------------------------------------

      m_stopLoss = 0.0;

      return true;
   }

   //--------------------------------------------------
   // Getter
   //--------------------------------------------------

   double Value() const
   {
      return m_stopLoss;
   }

   //--------------------------------------------------
   // Shutdown
   //--------------------------------------------------

   void Shutdown()
   {
      Print("StopLossCalculator detenido.");
   }

};

#endif