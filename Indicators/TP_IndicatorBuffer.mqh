#ifndef __TP_INDICATORBUFFER_MQH__
#define __TP_INDICATORBUFFER_MQH__

//+------------------------------------------------------------------+
//| Buffer de un indicador MT5                                       |
//+------------------------------------------------------------------+
class CTPIndicatorBuffer
{
private:

   int      m_handle;
   int      m_buffer;
   int      m_history;

   double   m_values[];

public:

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

   CTPIndicatorBuffer()
   {
      m_handle  = INVALID_HANDLE;
      m_buffer  = 0;
      m_history = 0;
   }

   //--------------------------------------------------
   // Inicialización
   //--------------------------------------------------

   bool Initialize(
      int handle,
      int buffer,
      int history = 200)
   {
      m_handle  = handle;
      m_buffer  = buffer;
      m_history = history;

      ArraySetAsSeries(m_values, true);

      return true;
   }

   //--------------------------------------------------
   // Actualizar datos
   //--------------------------------------------------

   bool Update()
   {
      if(m_handle == INVALID_HANDLE)
         return false;

      int copied =
         CopyBuffer(
            m_handle,
            m_buffer,
            0,
            m_history,
            m_values);

      return (copied > 0);
   }

   //--------------------------------------------------
   // Obtener valor
   //--------------------------------------------------

   double Value(int shift = 0) const
   {
      if(shift < 0)
         return 0.0;

      if(shift >= ArraySize(m_values))
         return 0.0;

      return m_values[shift];
   }

   //--------------------------------------------------
   // Liberar
   //--------------------------------------------------

   void Shutdown()
   {
      ArrayFree(m_values);

      m_handle = INVALID_HANDLE;
   }

};

#endif