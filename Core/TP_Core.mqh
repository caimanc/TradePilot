#ifndef __TP_CORE_MQH__
#define __TP_CORE_MQH__

class CTPCore
{
private:

   bool m_initialized;

public:

   CTPCore()
   {
      m_initialized = false;
   }

   bool Initialize()
   {
      Print("======================================");
      Print("TradePilot Core");
      Print("Inicializando núcleo...");
      Print("======================================");

      m_initialized = true;

      Print("Core inicializado correctamente.");

      return true;
   }

   void Update()
   {
      if(!m_initialized)
         return;

      // Aquí se ejecutarán todos los módulos
   }

   void Shutdown()
   {
      if(!m_initialized)
         return;

      Print("Core detenido.");

      m_initialized = false;
   }

   bool IsInitialized()
   {
      return m_initialized;
   }
};

#endif