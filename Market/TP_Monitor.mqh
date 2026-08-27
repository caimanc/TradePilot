#ifndef __TP_MONITOR_MQH__
#define __TP_MONITOR_MQH__

#include "TP_Telemetry.mqh"

//+------------------------------------------------------------------+
//| Monitor de operaciones                                           |
//|                                                                  |
//| Registra la telemetria por operacion (entrada/cierre) para       |
//| alimentar el futuro Naive Bayes y medir el impacto de eventos    |
//| externos (p.ej. noticias) cruzando las marcas de tiempo del log. |
//|                                                                  |
//| NO bloquea operaciones: solo registra (log) para decidir con     |
//| datos en el futuro.                                              |
//+------------------------------------------------------------------+
class CTPMonitor
{
private:

   long m_magicNumber;

   CTPTelemetry m_telemetry;

   //--------------------------------------------------
   // Estado de la posicion propia abierta
   //--------------------------------------------------

   ulong    m_posTicket;
   bool     m_posAbierta;

   string   m_posDireccion;

   //--------------------------------------------------
   // Contador de senales para trazabilidad
   //--------------------------------------------------

   ulong    m_signalCounter;

   //--------------------------------------------------
   // Detectar apertura/ajuste de posicion propia
   //--------------------------------------------------

   void DetectarPosicion()
   {
      bool encontrada = false;

      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong ticket = PositionGetTicket(i);

         if(ticket == 0)
            continue;

         if(PositionGetInteger(POSITION_MAGIC) != m_magicNumber)
            continue;

         if(PositionGetString(POSITION_SYMBOL) != _Symbol)
            continue;

         // Posicion propia
         encontrada = true;

         long tipo = PositionGetInteger(POSITION_TYPE);

         string dir = (tipo == POSITION_TYPE_BUY) ? "BUY" : "SELL";

         if(!m_posAbierta)
         {
            // Nueva apertura
            m_posAbierta    = true;
            m_posTicket     = ticket;
            m_posDireccion  = dir;

            m_signalCounter++;

            double precio = PositionGetDouble(POSITION_PRICE_OPEN);
            double sl     = PositionGetDouble(POSITION_SL);
            double tp     = PositionGetDouble(POSITION_TP);
            double volumen = PositionGetDouble(POSITION_VOLUME);

            m_telemetry.OnOpen(
               ticket,
               m_signalCounter,
               dir,
               precio,
               sl,
               tp,
               volumen
            );
         }
         else if(ticket != m_posTicket)
         {
            // Cambio de ticket sin cierre aparente (raro): re-sincronizar
            m_posTicket    = ticket;
            m_posDireccion = dir;
         }

         break;
      }

      // Si antes habia posicion y ahora no -> se cerro
      if(!encontrada && m_posAbierta)
      {
         double profit    = 0.0;
         double swap      = 0.0;
         double commission = 0.0;
         double precioCierre = 0.0;
         string motivo    = "desconocido";

         // Buscar el deal OUT de nuestro ticket/magic en el historial
         if(HistorySelect(0, TimeCurrent()))
         {
            int total = HistoryDealsTotal();

            for(int d = 0; d < total; d++)
            {
               ulong dTicket = HistoryDealGetTicket(d);

               if(dTicket == 0)
                  continue;

               if(HistoryDealGetInteger(dTicket, DEAL_MAGIC) != m_magicNumber)
                  continue;

               if(HistoryDealGetString(dTicket, DEAL_SYMBOL) != _Symbol)
                  continue;

               long entrada = HistoryDealGetInteger(dTicket, DEAL_ENTRY);

               if(entrada != DEAL_ENTRY_OUT &&
                  entrada != DEAL_ENTRY_OUT_BY)
                  continue;

               // Deal de salida
               profit    = HistoryDealGetDouble(dTicket, DEAL_PROFIT);
               swap      = HistoryDealGetDouble(dTicket, DEAL_SWAP);
               commission = HistoryDealGetDouble(dTicket, DEAL_COMMISSION);
               precioCierre = HistoryDealGetDouble(dTicket, DEAL_PRICE);

               // Motivo por la orden del deal
               ulong ordTicket = HistoryDealGetInteger(dTicket, DEAL_ORDER);

               if(ordTicket != 0 &&
                  HistoryOrderSelect(ordTicket))
               {
                  long motivoOrden =
                     HistoryOrderGetInteger(ordTicket, ORDER_REASON);

                  switch((ENUM_ORDER_REASON)motivoOrden)
                  {
                     case ORDER_REASON_SL:     motivo = "SL"; break;
                     case ORDER_REASON_TP:     motivo = "TP"; break;
                     case ORDER_REASON_CLIENT: motivo = "manual"; break;
                     default:                  motivo = "otro"; break;
                  }
               }

               break;
            }
         }

         m_telemetry.OnClose(
            m_posTicket,
            m_posDireccion,
            precioCierre,
            profit,
            swap,
            commission,
            motivo
         );

         m_posAbierta  = false;
         m_posTicket   = 0;
      }
   }

public:

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

   CTPMonitor()
   {
      m_magicNumber   = 0;
      m_posTicket     = 0;
      m_posAbierta    = false;
      m_posDireccion  = "";
      m_signalCounter = 0;
   }

   //--------------------------------------------------
   // Inicialización
   //--------------------------------------------------

   void Initialize(long magicNumber)
   {
      m_magicNumber  = magicNumber;

      m_telemetry.Initialize(magicNumber);

      // Sincronizar posicion existente al arrancar
      m_posAbierta = false;

      Print("Monitor de operaciones inicializado.");
   }

   //--------------------------------------------------
   // Actualización (llamar cada tick)
   //--------------------------------------------------

   void Update()
   {
      DetectarPosicion();
   }

   //--------------------------------------------------
   // Shutdown
   //--------------------------------------------------

   void Shutdown()
   {
      m_telemetry.Shutdown();

      Print("Monitor detenido.");
   }

};

#endif

