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
   double m_dailyNet;   // neto firmado del día (+ganancia / -pérdida)

   int    m_tradeCount;
   int    m_maxTrades;

   //--------------------------------------------------
   // Drawdown total y hard stop
   //--------------------------------------------------

   double m_maxDrawdownPct;   // % sobre equity pico. 0 = desactivado
   bool   m_hardStop;         // true = cerrar todo y detener el EA
   double m_peakEquity;       // equity mas alto visto desde el arranque
   double m_drawdownPct;      // drawdown actual (0..100)
   bool   m_hardStopTriggered; // se dispara una sola vez

   //--------------------------------------------------
   // Identidad y día corriente
   //--------------------------------------------------

   long m_magicNumber;

   int  m_currentDay;

   //--------------------------------------------------
   // Resultado neto del día (firmado: +ganancia / -pérdida)
   // (deals propios cerrados)
   //--------------------------------------------------

   double ResultadoDiarioRealizado()
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

      return resultado;
   }

   //--------------------------------------------------
   // Pérdida neta realizada hoy (deals propios cerrados)
   //--------------------------------------------------

   double PerdidaDiariaRealizada()
   {
      return MathMax(0.0, -ResultadoDiarioRealizado());
   }

public:

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

   CTPRiskManager()
   {
      m_maxDailyLoss = 50.0;
      m_dailyLoss = 0.0;
      m_dailyNet  = 0.0;

      m_tradeCount = 0;
      m_maxTrades = 5;

      m_magicNumber = 0;

      m_currentDay = 0;

      m_maxDrawdownPct  = 0.0;
      m_hardStop        = false;
      m_peakEquity      = 0.0;
      m_drawdownPct     = 0.0;
      m_hardStopTriggered = false;
   }

   //--------------------------------------------------
   // Inicialización
   //--------------------------------------------------

   bool Initialize(
      long   magicNumber  = 0,
      double volumenManual = 0.0,
      int    maxTrades     = 0,
      double maxDailyLoss  = 50.0,
      double maxDrawdownPct = 0.0,
      bool   hardStop       = false)
   {
      if(!m_positionSizer.Initialize())
         return false;

      m_magicNumber = magicNumber;

      m_maxTrades    = maxTrades;
      m_maxDailyLoss = maxDailyLoss;

      m_maxDrawdownPct  = maxDrawdownPct;
      m_hardStop        = hardStop;
      m_peakEquity      = AccountInfoDouble(ACCOUNT_EQUITY);
      m_drawdownPct     = 0.0;
      m_hardStopTriggered = false;

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

      Print(
         "Max Drawdown    : ",
         m_maxDrawdownPct <= 0.0 ? "DESACTIVADO" : DoubleToString(m_maxDrawdownPct, 1) + " %"
      );

      Print(
         "Hard Stop       : ",
         m_hardStop ? "ACTIVO (cierra todo y detiene el EA)" : "off"
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
         m_dailyNet  = 0.0;

         m_tradeCount = 0;

         m_currentDay = diaActual;
      }

      m_positionSizer.Calculate();

      m_dailyLoss = PerdidaDiariaRealizada();
      m_dailyNet  = ResultadoDiarioRealizado();

      //--------------------------------------------------
      // Drawdown total sobre el equity pico
      // (incluye ganancia/pérdida flotante, no solo cerrado)
      //--------------------------------------------------

      if(m_maxDrawdownPct > 0.0)
      {
         double equity = AccountInfoDouble(ACCOUNT_EQUITY);

         if(equity > m_peakEquity)
            m_peakEquity = equity;

         if(m_peakEquity > 0.0)
            m_drawdownPct = (m_peakEquity - equity) / m_peakEquity * 100.0;

         if(m_drawdownPct >= m_maxDrawdownPct && !m_hardStopTriggered)
         {
            m_hardStopTriggered = true;

            Print("ALERTA DRAWDOWN: ",
                  DoubleToString(m_drawdownPct, 1), " % sobre equity pico (",
                  DoubleToString(m_maxDrawdownPct, 1), " % limite).");

            if(m_hardStop)
               Print("HARD STOP: se cerraran todas las posiciones y el EA se detendra.");
            else
               Print("Nuevas operaciones bloqueadas hasta reiniciar.");
         }
      }
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

   //--------------------------------------------------
   // Neto del día firmado (+ganancia / -pérdida)
   //--------------------------------------------------

   double DailyNet() const
   {
      return m_dailyNet;
   }

   double MaxDailyLoss() const
   {
      return m_maxDailyLoss;
   }

   //--------------------------------------------------
   // Drawdown total (0..100 %) y hard stop
   //--------------------------------------------------

   double DrawdownPct() const
   {
      return m_drawdownPct;
   }

   double MaxDrawdownPct() const
   {
      return m_maxDrawdownPct;
   }

   bool HardStopTriggered() const
   {
      return m_hardStopTriggered;
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
      if(m_hardStopTriggered)
         return false;

      if(m_maxDrawdownPct > 0.0 && m_drawdownPct >= m_maxDrawdownPct)
         return false;

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