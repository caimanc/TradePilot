//+------------------------------------------------------------------+
//|                                                      TradePilot  |
//+------------------------------------------------------------------+
#ifndef __TP_INDICATOR_MQH__
#define __TP_INDICATOR_MQH__

#include "TP_IndicatorBuffer.mqh"

//+------------------------------------------------------------------+
//| Clase base para todos los indicadores                            |
//+------------------------------------------------------------------+
class CTPIndicator
{
protected:

   //--------------------------------------------------
   // Configuración
   //--------------------------------------------------

   string            m_symbol;
   ENUM_TIMEFRAMES   m_timeframe;
   int               m_period;

   //--------------------------------------------------
   // Handle MT5
   //--------------------------------------------------

   int               m_handle;

   //--------------------------------------------------
   // Estado
   //--------------------------------------------------

   bool              m_initialized;

public:

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

   CTPIndicator()
   {
      m_symbol      = "";
      m_timeframe   = PERIOD_CURRENT;
      m_period      = 0;

      m_handle      = INVALID_HANDLE;

      m_initialized = false;
   }

   //--------------------------------------------------
   // Destructor
   //--------------------------------------------------

   virtual ~CTPIndicator()
   {
      Shutdown();
   }

   //--------------------------------------------------
   // Inicialización
   //--------------------------------------------------

   virtual bool Initialize(
      string symbol,
      ENUM_TIMEFRAMES timeframe,
      int period,
      int history = 200) = 0;

   //--------------------------------------------------
   // Actualización
   //--------------------------------------------------

   virtual bool Update() = 0;

   //--------------------------------------------------
   // Valor principal del indicador
   //--------------------------------------------------

   virtual double Value(int shift = 0) const = 0;

   //--------------------------------------------------
   // Liberar recursos
   //--------------------------------------------------

   virtual void Shutdown()
   {
      if(m_handle != INVALID_HANDLE)
      {
         IndicatorRelease(m_handle);
         m_handle = INVALID_HANDLE;
      }

      m_initialized = false;
   }

   //--------------------------------------------------
   // Estado
   //--------------------------------------------------

   bool IsInitialized() const
   {
      return m_initialized;
   }

   //--------------------------------------------------
   // Getters
   //--------------------------------------------------

   string Symbol() const
   {
      return m_symbol;
   }

   ENUM_TIMEFRAMES Timeframe() const
   {
      return m_timeframe;
   }

   int Period() const
   {
      return m_period;
   }

   int Handle() const
   {
      return m_handle;
   }

};

#endif
//+------------------------------------------------------------------+