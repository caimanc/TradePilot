#ifndef __TP_CORE_MQH__
#define __TP_CORE_MQH__

class CTPCore
{
private:

   bool m_initialized;

public:

   //==================================================
   // Constructor
   //==================================================

   CTPCore()
   {
      m_initialized = false;
   }

   //==================================================
   // Inicialización
   //==================================================

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

   //==================================================
   // Bucle principal
   //==================================================

   void Update()
   {
      if(!m_initialized)
         return;

      // Aquí se ejecutarán todos los módulos

      // Config.Update();
      // Market.Update();
      // Sessions.Update();
      // Strategy.Update();
      // Risk.Update();
      // Trade.Update();
      // Statistics.Update();
      // UI.Update();
   }

   //==================================================
   // Finalización
   //==================================================

   void Shutdown()
   {
      if(!m_initialized)
         return;

      Print("Core detenido.");

      m_initialized = false;
   }

   //==================================================
   // Estado
   //==================================================

   bool IsInitialized() const
   {
      return m_initialized;
   }
};

#endif // __TP_CORE_MQH__