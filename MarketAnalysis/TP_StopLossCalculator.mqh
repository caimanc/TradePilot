#ifndef __TP_STOPLOSSCALCULATOR_MQH__
#define __TP_STOPLOSSCALCULATOR_MQH__

//+------------------------------------------------------------------+
//| Stop Loss Calculator                                             |
//|                                                                  |
//| Calcula el SL utilizando estructura de precio + ATR.             |
//|                                                                  |
//| IMPORTANTE:                                                       |
//| El balance de la cuenta NO determina la distancia del SL.        |
//+------------------------------------------------------------------+
class CTPStopLossCalculator
{
private:

   //--------------------------------------------------
   // Configuración
   //--------------------------------------------------

   double m_atrMultiplier;

   double m_bufferPoints;

   //--------------------------------------------------
   // Estado
   //--------------------------------------------------

   double m_stopLoss;

   double m_distance;

   bool m_initialized;


public:

   //==================================================
   // Constructor
   //==================================================

   CTPStopLossCalculator()
   {
      m_atrMultiplier = 0.20;

      m_bufferPoints = 2.0;

      m_stopLoss = 0.0;

      m_distance = 0.0;

      m_initialized = false;
   }


   //==================================================
   // Inicialización
   //==================================================

   bool Initialize(
      double atrMultiplier = 0.20,
      double bufferPoints = 2.0)
   {
      if(atrMultiplier < 0.0)
         return false;

      if(bufferPoints < 0.0)
         return false;


      m_atrMultiplier = atrMultiplier;

      m_bufferPoints = bufferPoints;


      m_stopLoss = 0.0;

      m_distance = 0.0;

      m_initialized = true;


      Print("StopLossCalculator inicializado.");

      Print(
         "ATR Multiplier : ",
         DoubleToString(
            m_atrMultiplier,
            2)
      );

      Print(
         "Buffer Points  : ",
         DoubleToString(
            m_bufferPoints,
            2)
      );


      return true;
   }


   //==================================================
   // Calcular SL BUY
   //==================================================

   bool CalculateBuy(
      double entryPrice,
      double swingLow,
      double atr,
      double point)
   {
      if(!m_initialized)
         return false;

      if(entryPrice <= 0.0)
         return false;

      if(swingLow <= 0.0)
         return false;

      if(atr <= 0.0)
         return false;

      if(point <= 0.0)
         return false;


      //--------------------------------------------------
      // Buffer basado en ATR
      //--------------------------------------------------

      double atrBuffer =
         atr * m_atrMultiplier;


      //--------------------------------------------------
      // Buffer mínimo adicional
      //--------------------------------------------------

      double minimumBuffer =
         m_bufferPoints * point;


      //--------------------------------------------------
      // Utilizar el mayor buffer
      //--------------------------------------------------

      double buffer =
         MathMax(
            atrBuffer,
            minimumBuffer
         );


      //--------------------------------------------------
      // SL debajo del Swing Low
      //--------------------------------------------------

      double calculatedSL =
         swingLow - buffer;


      //--------------------------------------------------
      // Validar posición del SL
      //--------------------------------------------------

      if(calculatedSL >= entryPrice)
      {
         m_stopLoss = 0.0;
         m_distance = 0.0;

         return false;
      }


      //--------------------------------------------------
      // Distancia real
      //--------------------------------------------------

      double distance =
         entryPrice - calculatedSL;


      if(distance <= 0.0)
      {
         m_stopLoss = 0.0;
         m_distance = 0.0;

         return false;
      }


      //--------------------------------------------------
      // Guardar resultado
      //--------------------------------------------------

      m_stopLoss = calculatedSL;

      m_distance = distance;


      return true;
   }


   //==================================================
   // Calcular SL SELL
   //==================================================

   bool CalculateSell(
      double entryPrice,
      double swingHigh,
      double atr,
      double point)
   {
      if(!m_initialized)
         return false;

      if(entryPrice <= 0.0)
         return false;

      if(swingHigh <= 0.0)
         return false;

      if(atr <= 0.0)
         return false;

      if(point <= 0.0)
         return false;


      //--------------------------------------------------
      // Buffer basado en ATR
      //--------------------------------------------------

      double atrBuffer =
         atr * m_atrMultiplier;


      //--------------------------------------------------
      // Buffer mínimo
      //--------------------------------------------------

      double minimumBuffer =
         m_bufferPoints * point;


      //--------------------------------------------------
      // Mayor buffer
      //--------------------------------------------------

      double buffer =
         MathMax(
            atrBuffer,
            minimumBuffer
         );


      //--------------------------------------------------
      // SL encima del Swing High
      //--------------------------------------------------

      double calculatedSL =
         swingHigh + buffer;


      //--------------------------------------------------
      // Validar posición del SL
      //--------------------------------------------------

      if(calculatedSL <= entryPrice)
      {
         m_stopLoss = 0.0;
         m_distance = 0.0;

         return false;
      }


      //--------------------------------------------------
      // Distancia real
      //--------------------------------------------------

      double distance =
         calculatedSL - entryPrice;


      if(distance <= 0.0)
      {
         m_stopLoss = 0.0;
         m_distance = 0.0;

         return false;
      }


      //--------------------------------------------------
      // Guardar resultado
      //--------------------------------------------------

      m_stopLoss = calculatedSL;

      m_distance = distance;


      return true;
   }


   //==================================================
   // Stop Loss
   //==================================================

   double StopLoss() const
   {
      return m_stopLoss;
   }


   //==================================================
   // Distancia del SL
   //==================================================

   double Distance() const
   {
      return m_distance;
   }


   //==================================================
   // Distancia en puntos
   //==================================================

   double DistancePoints(
      double point) const
   {
      if(point <= 0.0)
         return 0.0;

      return m_distance / point;
   }


   //==================================================
   // ATR Multiplier
   //==================================================

   double ATRMultiplier() const
   {
      return m_atrMultiplier;
   }


   //==================================================
   // Buffer
   //==================================================

   double BufferPoints() const
   {
      return m_bufferPoints;
   }


   //==================================================
   // Shutdown
   //==================================================

   void Shutdown()
   {
      m_stopLoss = 0.0;

      m_distance = 0.0;

      m_initialized = false;

      Print("StopLossCalculator detenido.");
   }
};

#endif