//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#ifndef __TP_INDICATORBUFFER_MQH__
#define __TP_INDICATORBUFFER_MQH__

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CTPIndicatorBuffer
  {
private:

   //--------------------------------------------------
   // Configuración
   //--------------------------------------------------

   int               m_handle;
   int               m_buffer;

   //--------------------------------------------------
   // Datos
   //--------------------------------------------------

   double            m_values[];

   int               m_size;

   bool              m_ready;

public:

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

                     CTPIndicatorBuffer()
     {
      m_handle = INVALID_HANDLE;
      m_buffer = 0;

      m_size = 0;

      m_ready = false;
     }

   //--------------------------------------------------
   // Inicialización
   //--------------------------------------------------

   bool              Initialize(
      int handle,
      int buffer,
      int size)
     {
      if(handle == INVALID_HANDLE)
         return false;

      m_handle = handle;
      m_buffer = buffer;
      m_size   = size;

      ArrayResize(m_values,m_size);
      ArraySetAsSeries(m_values,true);
      ArrayInitialize(m_values,0.0);

      m_ready = true;

      return true;
     }

   //--------------------------------------------------
   // Actualizar
   //--------------------------------------------------

   bool              Update()
     {
      if(!m_ready)
        {
         Print("IndicatorBuffer: buffer no inicializado.");
         return false;
        }

      ResetLastError();

      int copied =
         CopyBuffer(
            m_handle,
            m_buffer,
            0,
            m_size,
            m_values);

      if(copied <= 0)
        {
         Print("CopyBuffer ERROR");
         Print("Handle     : ", m_handle);
         Print("Buffer     : ", m_buffer);
         Print("Solicitados: ", m_size);
         Print("Copiados   : ", copied);
         Print("LastError  : ", GetLastError());

         return false;
        }

      return true;
     }

   //--------------------------------------------------
   // Valor
   //--------------------------------------------------

   double            Value(int shift=0) const
     {
      if(!m_ready)
         return EMPTY_VALUE;

      if(shift < 0)
         return EMPTY_VALUE;

      if(shift >= m_size)
         return EMPTY_VALUE;

      return m_values[shift];
     }

   //--------------------------------------------------
   // Tamaño
   //--------------------------------------------------

   int               Size() const
     {
      return m_size;
     }

   //--------------------------------------------------
   // Estado
   //--------------------------------------------------

   bool              Ready() const
     {
      return m_ready;
     }

   //--------------------------------------------------
   // Liberar memoria
   //--------------------------------------------------

   void              Shutdown()
     {
      ArrayFree(m_values);

      m_ready = false;

      m_handle = INVALID_HANDLE;
      m_buffer = 0;
      m_size = 0;
     }

  };

#endif
//+------------------------------------------------------------------+
