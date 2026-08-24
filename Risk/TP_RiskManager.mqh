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

   //--------------------------------------------------
   // Identidad y día corriente
   //--------------------------------------------------

   long m_magicNumber;

   int  m_currentDay;

   //--------------------------------------------------
   // Pérdida neta realizada hoy (deals propios cerrados)
   //--------------------------------------------------

   double PerdidaDiariaRealizada()
   {
      datetime inicioDia =
         TimeCurrent() - TimeCurrent() % 86400;

      if(!HistorySelect(inicioDia, TimeCurrent()))
         return 0.0;

      double resultado = 0.0;

      int total = HistoryDealsTotal();

      for(int i = 0; i < total; i++)
      {
         ulong ticket = HistoryDealGetTicket(i);

         if(ticket == 0)
            continue;

         if(HistoryDealGetString(
               ticket,
               DEAL_SYMBOL) != _Symbol)
            continue;

         if(HistoryDealGetInteger(
               ticket,
               DEAL_MAGIC) != m_magicNumber)
            continue;

         long entrada =
            HistoryDealGetInteger(
               ticket,
               DEAL_ENTRY);

         if(entrada != DEAL_ENTRY_OUT &&
            entrada != DEAL_ENTRY_OUT_BY)
            continue;

         resultado +=
            HistoryDealGetDouble(ticket, DEAL_PROFIT) +
            HistoryDealGetDouble(ticket, DEAL_SWAP) +
            HistoryDealGetDouble(ticket, DEAL_COMMISSION);
      }

      return MathMax(0.0, -resultado);
   }

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

      m_magicNumber = 0;

      m_currentDay = 0;
   }

   //--------------------------------------------------
   // Inicialización
   //--------------------------------------------------

   bool Initialize(
      long magicNumber = 0)
   {
      if(!m_positionSizer.Initialize())
         return false;

      m_magicNumber = magicNumber;

      Print("RiskManager inicializado.");

      Print(
         "Magic Number    : ",
         m_magicNumber
      );

      return true;
   }

   //--------------------------------------------------
   // Actualización
   //--------------------------------------------------

   void Update()
   {
      //--------------------------------------------------
      // Reinicio por cambio de día (server time)
      //--------------------------------------------------

      MqlDateTime ahora;

      TimeToStruct(TimeCurrent(), ahora);

      int diaActual = ahora.year * 1000 + ahora.day_of_year;

      if(diaActual != m_currentDay)
      {
         m_dailyLoss = 0.0;

         m_tradeCount = 0;

         m_currentDay = diaActual;
      }

      m_positionSizer.Calculate();

      m_dailyLoss = PerdidaDiariaRealizada();
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