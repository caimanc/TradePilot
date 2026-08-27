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
      long   magicNumber  = 0,
      double volumenManual = 0.0,
      int    maxTrades     = 0,
      double maxDailyLoss  = 50.0)
   {
      if(!m_positionSizer.Initialize())
         return false;

      m_magicNumber = magicNumber;

      m_maxTrades    = maxTrades;
      m_maxDailyLoss = maxDailyLoss;

      m_positionSizer.SetVolumeOverride(
         volumenManual
      );

      Print("RiskManager inicializado.");

      Print(
         "Magic Number    : ",
         m_magicNumber
      );

      Print(
         "Max Trades      : ",
         m_maxTrades == 0 ? "ILIMITADO" : IntegerToString(m_maxTrades)
      );

      Print(
         "Max Perdida     : ",
         DoubleToString(m_maxDailyLoss, 2),
         " USD"
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
   // Recalcular volumen con distancia real del SL
   //--------------------------------------------------

   void CalcularVolumen(double distanciaSLPrecio)
   {
      m_positionSizer.Calculate(distanciaSLPrecio);
   }

   //--------------------------------------------------
   // Getters para el panel
   //--------------------------------------------------

   double DailyLoss() const
   {
      return m_dailyLoss;
   }

   double MaxDailyLoss() const
   {
      return m_maxDailyLoss;
   }

   int TradeCount() const
   {
      return m_tradeCount;
   }

   int MaxTrades() const
   {
      return m_maxTrades;
   }

   bool IsManualVolume() const
   {
      return m_positionSizer.IsManual();
   }

   //--------------------------------------------------
   // Validar apertura
   //--------------------------------------------------

   bool CanOpenTrade() const
   {
      if(m_dailyLoss >= m_maxDailyLoss)
         return false;

      if(m_maxTrades > 0 && m_tradeCount >= m_maxTrades)
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