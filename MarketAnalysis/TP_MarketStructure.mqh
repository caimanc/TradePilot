#ifndef __TP_MARKETSTRUCTURE_MQH__
#define __TP_MARKETSTRUCTURE_MQH__

#include "TP_SwingDetector.mqh"
//+------------------------------------------------------------------+
//| Estructura del mercado                                           |
//+------------------------------------------------------------------+
class CTPMarketStructure
{
private:

   //--------------------------------------------------
   // Highs
   //--------------------------------------------------

   double m_currentHigh;
   double m_previousHigh;

   //--------------------------------------------------
   // Lows
   //--------------------------------------------------

   double m_currentLow;
   double m_previousLow;

   //--------------------------------------------------
   // Clasificación
   //--------------------------------------------------

   bool m_higherHigh;
   bool m_higherLow;

   bool m_lowerHigh;
   bool m_lowerLow;

   //--------------------------------------------------
   // Estado
   //--------------------------------------------------

   bool m_initialized;

   //--------------------------------------------------
   // Volatilidad
   //--------------------------------------------------

   double m_atr;

   //--------------------------------------------------
   // Factor de significancia
   //--------------------------------------------------

   double m_atrFactor;

   //--------------------------------------------------
   // Tolerancia mínima
   //--------------------------------------------------

   double m_minDistance;

public:

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

   CTPMarketStructure()
   {
      m_currentHigh  = 0.0;
      m_previousHigh = 0.0;

      m_currentLow   = 0.0;
      m_previousLow  = 0.0;

      m_higherHigh = false;
      m_higherLow  = false;

      m_lowerHigh = false;
      m_lowerLow  = false;

      m_initialized = false;

      m_atr = 0.0;

      // 20% del ATR
      m_atrFactor = 0.20;

      // Protección adicional contra ruido
      m_minDistance = 0.01;
   }

   //--------------------------------------------------
   // Inicialización
   //--------------------------------------------------

   bool Initialize()
   {
      m_currentHigh  = 0.0;
      m_previousHigh = 0.0;

      m_currentLow   = 0.0;
      m_previousLow  = 0.0;

      m_higherHigh = false;
      m_higherLow  = false;

      m_lowerHigh = false;
      m_lowerLow  = false;

      m_atr = 0.0;

      m_initialized = true;

      Print("MarketStructure inicializado.");

      return true;
   }

   //--------------------------------------------------
   // Configurar ATR
   //--------------------------------------------------

   void SetATR(double atr)
   {
      if(atr > 0.0)
         m_atr = atr;
   }

   //--------------------------------------------------
   // Configurar factor ATR
   //--------------------------------------------------

   void SetATRFactor(double factor)
   {
      if(factor > 0.0)
         m_atrFactor = factor;
   }

   //--------------------------------------------------
   // Obtener distancia mínima estructural
   //--------------------------------------------------

   double SignificanceDistance() const
   {
      double atrDistance = 0.0;

      if(m_atr > 0.0)
         atrDistance = m_atr * m_atrFactor;

      //--------------------------------------------------
      // Utilizamos el mayor entre:
      //
      // ATR × factor
      // distancia mínima
      //--------------------------------------------------

      if(atrDistance > m_minDistance)
         return atrDistance;

      return m_minDistance;
   }

   //--------------------------------------------------
   // Determinar si un nuevo High es significativo
   //--------------------------------------------------

   bool IsSignificantHigh(double newHigh) const
   {
      if(newHigh <= 0.0)
         return false;

      if(m_currentHigh <= 0.0)
         return true;

      double distance =
         MathAbs(newHigh - m_currentHigh);

      return (
         distance >= SignificanceDistance()
      );
   }

   //--------------------------------------------------
   // Determinar si un nuevo Low es significativo
   //--------------------------------------------------

   bool IsSignificantLow(double newLow) const
   {
      if(newLow <= 0.0)
         return false;

      if(m_currentLow <= 0.0)
         return true;

      double distance =
         MathAbs(newLow - m_currentLow);

      return (
         distance >= SignificanceDistance()
      );
   }

   //--------------------------------------------------
   // Actualización
   //--------------------------------------------------

   bool Update(const CTPSwingDetector &swings)
   {
      if(!m_initialized)
         return false;

      //--------------------------------------------------
      // Obtener swings
      //--------------------------------------------------

      double detectedHigh =
         swings.LastSwingHigh();

      double detectedLow =
         swings.LastSwingLow();

      //--------------------------------------------------
      // Actualizar High
      //--------------------------------------------------

      if(IsSignificantHigh(detectedHigh))
      {
         //--------------------------------------------------
         // Primer High
         //--------------------------------------------------

         if(m_currentHigh <= 0.0)
         {
            m_currentHigh = detectedHigh;
         }

         //--------------------------------------------------
         // Nuevo High significativo
         //--------------------------------------------------

         else
         {
            m_previousHigh = m_currentHigh;

            m_currentHigh = detectedHigh;
         }
      }

      //--------------------------------------------------
      // Actualizar Low
      //--------------------------------------------------

      if(IsSignificantLow(detectedLow))
      {
         //--------------------------------------------------
         // Primer Low
         //--------------------------------------------------

         if(m_currentLow <= 0.0)
         {
            m_currentLow = detectedLow;
         }

         //--------------------------------------------------
         // Nuevo Low significativo
         //--------------------------------------------------

         else
         {
            m_previousLow = m_currentLow;

            m_currentLow = detectedLow;
         }
      }

      //--------------------------------------------------
      // Reset clasificación
      //--------------------------------------------------

      m_higherHigh = false;
      m_higherLow  = false;

      m_lowerHigh = false;
      m_lowerLow  = false;

      //--------------------------------------------------
      // Clasificar High
      //--------------------------------------------------

      if(m_previousHigh > 0.0 &&
         m_currentHigh > m_previousHigh)
      {
         m_higherHigh = true;
      }
      else if(m_previousHigh > 0.0 &&
              m_currentHigh < m_previousHigh)
      {
         m_lowerHigh = true;
      }

      //--------------------------------------------------
      // Clasificar Low
      //--------------------------------------------------

      if(m_previousLow > 0.0 &&
         m_currentLow > m_previousLow)
      {
         m_higherLow = true;
      }
      else if(m_previousLow > 0.0 &&
              m_currentLow < m_previousLow)
      {
         m_lowerLow = true;
      }

      return true;
   }

   //--------------------------------------------------
   // Higher High
   //--------------------------------------------------

   bool IsHigherHigh() const
   {
      return m_higherHigh;
   }

   //--------------------------------------------------
   // Higher Low
   //--------------------------------------------------

   bool IsHigherLow() const
   {
      return m_higherLow;
   }

   //--------------------------------------------------
   // Lower High
   //--------------------------------------------------

   bool IsLowerHigh() const
   {
      return m_lowerHigh;
   }

   //--------------------------------------------------
   // Lower Low
   //--------------------------------------------------

   bool IsLowerLow() const
   {
      return m_lowerLow;
   }

   //--------------------------------------------------
   // High actual
   //--------------------------------------------------

   double CurrentHigh() const
   {
      return m_currentHigh;
   }

   //--------------------------------------------------
   // High anterior
   //--------------------------------------------------

   double PreviousHigh() const
   {
      return m_previousHigh;
   }

   //--------------------------------------------------
   // Low actual
   //--------------------------------------------------

   double CurrentLow() const
   {
      return m_currentLow;
   }

   //--------------------------------------------------
   // Low anterior
   //--------------------------------------------------

   double PreviousLow() const
   {
      return m_previousLow;
   }

   //--------------------------------------------------
   // ATR
   //--------------------------------------------------

   double ATR() const
   {
      return m_atr;
   }

   //--------------------------------------------------
   // Factor ATR
   //--------------------------------------------------

   double ATRFactor() const
   {
      return m_atrFactor;
   }

   //--------------------------------------------------
   // Shutdown
   //--------------------------------------------------

   void Shutdown()
   {
      m_currentHigh  = 0.0;
      m_previousHigh = 0.0;

      m_currentLow   = 0.0;
      m_previousLow  = 0.0;

      m_higherHigh = false;
      m_higherLow  = false;

      m_lowerHigh = false;
      m_lowerLow  = false;

      m_atr = 0.0;

      m_initialized = false;

      Print("MarketStructure detenido.");
   }
};

#endif