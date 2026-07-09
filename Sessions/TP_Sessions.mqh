//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#ifndef __TP_SESSIONS_MQH__
#define __TP_SESSIONS_MQH__

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CTPSessions
  {
private:

   //--------------------------------------------------
   // Configuración
   //--------------------------------------------------

   int               m_brokerUtcOffset;

   bool              m_tradeSydney;
   bool              m_tradeTokyo;
   bool              m_tradeLondon;
   bool              m_tradeNewYork;

   //--------------------------------------------------
   // Estado de sesiones
   //--------------------------------------------------

   bool              m_sydneyOpen;
   bool              m_tokyoOpen;
   bool              m_londonOpen;
   bool              m_newYorkOpen;

public:

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

                     CTPSessions()
     {
      m_brokerUtcOffset = 0;

      m_tradeSydney  = false;
      m_tradeTokyo   = false;
      m_tradeLondon  = true;
      m_tradeNewYork = true;

      m_sydneyOpen   = false;
      m_tokyoOpen    = false;
      m_londonOpen   = false;
      m_newYorkOpen  = false;
     }

   //--------------------------------------------------
   // Inicialización
   //--------------------------------------------------

   bool              Initialize(
      int brokerUtcOffset,
      bool tradeSydney,
      bool tradeTokyo,
      bool tradeLondon,
      bool tradeNewYork)
     {
      m_brokerUtcOffset = brokerUtcOffset;

      m_tradeSydney  = tradeSydney;
      m_tradeTokyo   = tradeTokyo;
      m_tradeLondon  = tradeLondon;
      m_tradeNewYork = tradeNewYork;

      Print("--------------------------------------");
      Print("Inicializando módulo Sessions...");
      Print("--------------------------------------");

      Update();

      Print("Sesión actual : ", CurrentSession());
      Print("Trading        : ", IsTradingTime() ? "SI" : "NO");

      Print("Sessions inicializado correctamente.");

      return true;
     }

   //--------------------------------------------------
   // Actualización
   //--------------------------------------------------

   void              Update()
     {
      datetime serverTime = TimeCurrent();

      MqlDateTime tm;

      TimeToStruct(serverTime, tm);

      int hour = tm.hour - m_brokerUtcOffset;

      if(hour < 0)
         hour += 24;

      if(hour >= 24)
         hour -= 24;

      //------------------------------

      m_sydneyOpen  = (hour >= 22 || hour < 7);

      m_tokyoOpen   = (hour >= 0 && hour < 9);

      m_londonOpen  = (hour >= 8 && hour < 17);

      m_newYorkOpen = (hour >= 13 && hour < 22);
     }

   //--------------------------------------------------
   // Finalización
   //--------------------------------------------------

   void              Shutdown()
     {
      Print("Sessions detenido.");
     }

   //--------------------------------------------------
   // Getters
   //--------------------------------------------------

   bool              IsSydneyOpen() const
     {
      return m_sydneyOpen;
     }

   bool              IsTokyoOpen() const
     {
      return m_tokyoOpen;
     }

   bool              IsLondonOpen() const
     {
      return m_londonOpen;
     }

   bool              IsNewYorkOpen() const
     {
      return m_newYorkOpen;
     }

   //--------------------------------------------------
   // Overlap
   //--------------------------------------------------

   bool              IsOverlap() const
     {
      return m_londonOpen && m_newYorkOpen;
     }

   //--------------------------------------------------
   // Nombre sesión
   //--------------------------------------------------

   string            CurrentSession() const
     {
      if(IsOverlap())
         return "LONDON_NEWYORK";

      if(m_londonOpen)
         return "LONDON";

      if(m_newYorkOpen)
         return "NEW_YORK";

      if(m_tokyoOpen)
         return "TOKYO";

      if(m_sydneyOpen)
         return "SYDNEY";

      return "CLOSED";
     }

   //--------------------------------------------------
   // ¿Se permite operar?
   //--------------------------------------------------

   bool              IsTradingTime() const
     {
      if(m_londonOpen && m_tradeLondon)
         return true;

      if(m_newYorkOpen && m_tradeNewYork)
         return true;

      if(m_tokyoOpen && m_tradeTokyo)
         return true;

      if(m_sydneyOpen && m_tradeSydney)
         return true;

      return false;
     }

  };

#endif
//+------------------------------------------------------------------+
