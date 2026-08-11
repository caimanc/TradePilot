#ifndef __TP_STRUCTUREANALYZER_MQH__
#define __TP_STRUCTUREANALYZER_MQH__

#include "TP_MarketStructure.mqh"

//+------------------------------------------------------------------+
//| Estados de estructura del mercado                                |
//+------------------------------------------------------------------+
enum ENUM_TP_STRUCTURE_STATUS
{
   TP_STRUCTURE_UNKNOWN = 0,
   TP_STRUCTURE_BULLISH,
   TP_STRUCTURE_BEARISH,
   TP_STRUCTURE_RANGE,
   TP_STRUCTURE_BULLISH_BREAK,
   TP_STRUCTURE_BEARISH_BREAK
};

//+------------------------------------------------------------------+
//| Analizador de estructura                                         |
//+------------------------------------------------------------------+
class CTPStructureAnalyzer
{
private:

   //--------------------------------------------------
   // Estado
   //--------------------------------------------------

   ENUM_TP_STRUCTURE_STATUS m_status;

   bool m_initialized;

   //--------------------------------------------------
   // Precio actual
   //--------------------------------------------------

   double m_price;

   //--------------------------------------------------
   // Estructura
   //--------------------------------------------------

   double m_high;
   double m_previousHigh;

   double m_low;
   double m_previousLow;

public:

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

   CTPStructureAnalyzer()
   {
      m_status = TP_STRUCTURE_UNKNOWN;

      m_initialized = false;

      m_price = 0.0;

      m_high = 0.0;
      m_previousHigh = 0.0;

      m_low = 0.0;
      m_previousLow = 0.0;
   }

   //--------------------------------------------------
   // Inicialización
   //--------------------------------------------------

   bool Initialize()
   {
      m_status = TP_STRUCTURE_UNKNOWN;

      m_initialized = true;

      m_price = 0.0;

      m_high = 0.0;
      m_previousHigh = 0.0;

      m_low = 0.0;
      m_previousLow = 0.0;

      Print("StructureAnalyzer inicializado.");

      return true;
   }

   //--------------------------------------------------
   // Actualización
   //--------------------------------------------------

   bool Update(
      const CTPMarketStructure &structure,
      double price)
   {
      if(!m_initialized)
         return false;

      m_price = price;

      //--------------------------------------------------
      // Obtener estructura
      //--------------------------------------------------

      m_high =
         structure.CurrentHigh();

      m_previousHigh =
         structure.PreviousHigh();

      m_low =
         structure.CurrentLow();

      m_previousLow =
         structure.PreviousLow();

      //--------------------------------------------------
      // Estado inicial
      //--------------------------------------------------

      m_status =
         TP_STRUCTURE_UNKNOWN;

      //--------------------------------------------------
      // Validar datos
      //--------------------------------------------------

      if(m_high <= 0.0 ||
         m_low <= 0.0)
      {
         m_status =
            TP_STRUCTURE_UNKNOWN;

         return false;
      }

      //--------------------------------------------------
      // Detectar ruptura alcista
      //--------------------------------------------------

      if(m_previousHigh > 0.0 &&
         m_price > m_high)
      {
         m_status =
            TP_STRUCTURE_BULLISH_BREAK;

         return true;
      }

      //--------------------------------------------------
      // Detectar ruptura bajista
      //--------------------------------------------------

      if(m_previousLow > 0.0 &&
         m_price < m_low)
      {
         m_status =
            TP_STRUCTURE_BEARISH_BREAK;

         return true;
      }

      //--------------------------------------------------
      // Estructura alcista
      //--------------------------------------------------

      if(structure.IsHigherHigh() &&
         structure.IsHigherLow())
      {
         m_status =
            TP_STRUCTURE_BULLISH;

         return true;
      }

      //--------------------------------------------------
      // Estructura bajista
      //--------------------------------------------------

      if(structure.IsLowerHigh() &&
         structure.IsLowerLow())
      {
         m_status =
            TP_STRUCTURE_BEARISH;

         return true;
      }

      //--------------------------------------------------
      // Estructura parcialmente alcista
      //--------------------------------------------------

      if(structure.IsHigherHigh() ||
         structure.IsHigherLow())
      {
         m_status =
            TP_STRUCTURE_BULLISH;

         return true;
      }

      //--------------------------------------------------
      // Estructura parcialmente bajista
      //--------------------------------------------------

      if(structure.IsLowerHigh() ||
         structure.IsLowerLow())
      {
         m_status =
            TP_STRUCTURE_BEARISH;

         return true;
      }

      //--------------------------------------------------
      // Rango
      //--------------------------------------------------

      m_status =
         TP_STRUCTURE_RANGE;

      return true;
   }

   //--------------------------------------------------
   // Estado
   //--------------------------------------------------

   ENUM_TP_STRUCTURE_STATUS Status() const
   {
      return m_status;
   }

   //--------------------------------------------------
   // Bullish
   //--------------------------------------------------

   bool IsBullish() const
   {
      return (
         m_status == TP_STRUCTURE_BULLISH ||
         m_status == TP_STRUCTURE_BULLISH_BREAK
      );
   }

   //--------------------------------------------------
   // Bearish
   //--------------------------------------------------

   bool IsBearish() const
   {
      return (
         m_status == TP_STRUCTURE_BEARISH ||
         m_status == TP_STRUCTURE_BEARISH_BREAK
      );
   }

   //--------------------------------------------------
   // Breakout
   //--------------------------------------------------

   bool IsBreakout() const
   {
      return (
         m_status == TP_STRUCTURE_BULLISH_BREAK
      );
   }

   //--------------------------------------------------
   // Breakdown
   //--------------------------------------------------

   bool IsBreakdown() const
   {
      return (
         m_status == TP_STRUCTURE_BEARISH_BREAK
      );
   }

   //--------------------------------------------------
   // Range
   //--------------------------------------------------

   bool IsRange() const
   {
      return (
         m_status == TP_STRUCTURE_RANGE
      );
   }

   //--------------------------------------------------
   // Retracement
   //--------------------------------------------------

   bool IsRetracement() const
   {
      if(m_status == TP_STRUCTURE_BULLISH &&
         m_price < m_high &&
         m_price > m_low)
      {
         return true;
      }

      if(m_status == TP_STRUCTURE_BEARISH &&
         m_price > m_low &&
         m_price < m_high)
      {
         return true;
      }

      return false;
   }

   //--------------------------------------------------
   // Precio
   //--------------------------------------------------

   double Price() const
   {
      return m_price;
   }

   //--------------------------------------------------
   // High
   //--------------------------------------------------

   double High() const
   {
      return m_high;
   }

   //--------------------------------------------------
   // Previous High
   //--------------------------------------------------

   double PreviousHigh() const
   {
      return m_previousHigh;
   }

   //--------------------------------------------------
   // Low
   //--------------------------------------------------

   double Low() const
   {
      return m_low;
   }

   //--------------------------------------------------
   // Previous Low
   //--------------------------------------------------

   double PreviousLow() const
   {
      return m_previousLow;
   }

   //--------------------------------------------------
   // Nombre del estado
   //--------------------------------------------------

   string StatusName() const
   {
      switch(m_status)
      {
         case TP_STRUCTURE_BULLISH:
            return "BULLISH";

         case TP_STRUCTURE_BEARISH:
            return "BEARISH";

         case TP_STRUCTURE_RANGE:
            return "RANGE";

         case TP_STRUCTURE_BULLISH_BREAK:
            return "BULLISH_BREAK";

         case TP_STRUCTURE_BEARISH_BREAK:
            return "BEARISH_BREAK";

         default:
            return "UNKNOWN";
      }
   }

   //--------------------------------------------------
   // Shutdown
   //--------------------------------------------------

   void Shutdown()
   {
      m_status =
         TP_STRUCTURE_UNKNOWN;

      m_initialized = false;

      m_price = 0.0;

      m_high = 0.0;
      m_previousHigh = 0.0;

      m_low = 0.0;
      m_previousLow = 0.0;

      Print("StructureAnalyzer detenido.");
   }
};

#endif