#ifndef __TP_RISKMANAGER_MQH__
#define __TP_RISKMANAGER_MQH__

#include "TP_PositionSizer.mqh"

//+------------------------------------------------------------------+
//| Risk Manager                                                     |
//+------------------------------------------------------------------+
class CTPRiskManager
{
private:

   //--------------------------------------------------
   // Componentes
   //--------------------------------------------------

   CTPPositionSizer m_positionSizer;

   //--------------------------------------------------
   // Riesgo diario
   //--------------------------------------------------

   double m_maxDailyLoss;
   double m_dailyLoss;

   int    m_tradeCount;
   int    m_maxTrades;

public:

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

   CTPRiskManager()
   {
      m_maxDailyLoss = 50.0;
      m_dailyLoss = 0.0;

      m_tradeCount = 0;
      m_maxTrades = 5;
   }

   //--------------------------------------------------
   // Inicialización
   //--------------------------------------------------

   bool Initialize()
   {
      if(!m_positionSizer.Initialize())
         return false;

      Print("RiskManager inicializado.");

      return true;
   }

   //--------------------------------------------------
   // Actualización
   //--------------------------------------------------

   void Update()
   {
      m_positionSizer.Calculate();
   }

   //--------------------------------------------------
   // Validar apertura
   //--------------------------------------------------

   bool CanOpenTrade() const
   {
      if(m_dailyLoss >= m_maxDailyLoss)
         return false;

      if(m_tradeCount >= m_maxTrades)
         return false;

      return true;
   }

   //--------------------------------------------------
   // Registrar operación
   //--------------------------------------------------

   void RegisterTrade()
   {
      m_tradeCount++;
   }

   //--------------------------------------------------
   // Getters
   //--------------------------------------------------

   double Volume() const
   {
      return m_positionSizer.Volume();
   }

   //--------------------------------------------------
   // Shutdown
   //--------------------------------------------------

   void Shutdown()
   {
      m_positionSizer.Shutdown();

      Print("RiskManager detenido.");
   }

};

#endif