#ifndef __TP_TELEMETRY_MQH__
#define __TP_TELEMETRY_MQH__

#include "../Signals/TP_SignalManager.mqh"

//+------------------------------------------------------------------+
//| Telemetria por operacion                                         |
//|                                                                  |
//| Registra en el log educativo cada operacion (entrada/cierre)     |
//| con los features activos, para el futuro Naive Bayes (fase 3.5b) |
//| y para medir el impacto de noticias de forma externa.            |
//|                                                                  |
//| NO guarda archivos: emite lineas prefijadas TP_TEL para que      |
//| puedan filtrarse y procesarse fuera.                             |
//+------------------------------------------------------------------+
class CTPTelemetry
{
private:

   long m_magicNumber;

   //--------------------------------------------------
   // Estado de operacion abierta
   //--------------------------------------------------

   ulong m_openTicket;
   ulong m_signalId;
   bool  m_tracked;

   datetime m_openTime;
   double   m_openPrice;

public:

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

   CTPTelemetry()
   {
      m_magicNumber = 0;
      m_openTicket  = 0;
      m_signalId    = 0;
      m_tracked     = false;
      m_openTime    = 0;
      m_openPrice   = 0.0;
   }

   //--------------------------------------------------
   // Inicialización
   //--------------------------------------------------

   void Initialize(long magicNumber)
   {
      m_magicNumber = magicNumber;

      Print("Telemetría inicializada (magic ", m_magicNumber, ").");
   }

   //--------------------------------------------------
   // Registrar entrada de operacion
   //--------------------------------------------------

   void OnOpen(
      ulong ticket,
      ulong signalId,
      string direccion,
      double precio,
      double sl,
      double tp,
      double volumen)
   {
      m_openTicket = ticket;
      m_signalId   = signalId;
      m_tracked    = true;
      m_openTime   = TimeCurrent();
      m_openPrice  = precio;

      Print(
         "TP_TEL|ENTRADA|",
         "ticket=", ticket,
         "|senal=", signalId,
         "|dir=", direccion,
         "|precio=", DoubleToString(precio, 5),
         "|sl=", DoubleToString(sl, 5),
         "|tp=", DoubleToString(tp, 5),
         "|vol=", DoubleToString(volumen, 2),
         "|time=", TimeToString(m_openTime)
      );
   }

   //--------------------------------------------------
   // Registrar cierre de operacion (resultado)
   //--------------------------------------------------

   void OnClose(
      ulong ticket,
      string direccion,
      double precioCierre,
      double profit,
      double swap,
      double commission,
      string motivo)
   {
      bool eraTracked = m_tracked && (m_openTicket == ticket);

      double resultadoNeto = profit + swap + commission;

      Print(
         "TP_TEL|CIERRE|",
         "ticket=", ticket,
         "|dir=", direccion,
         "|precio=", DoubleToString(precioCierre, 5),
         "|profit=", DoubleToString(profit, 2),
         "|neto=", DoubleToString(resultadoNeto, 2),
         "|motivo=", motivo,
         "|tracked=", (int)eraTracked
      );

      if(eraTracked)
      {
         // Duración en horas
         double horas = (double)(TimeCurrent() - m_openTime) / 3600.0;

         Print(
            "TP_TEL|RESULTADO|",
            "senal=", m_signalId,
            "|neto=", DoubleToString(resultadoNeto, 2),
            "|horas=", DoubleToString(horas, 2),
            "|timeOpen=", TimeToString(m_openTime),
            "|priceOpen=", DoubleToString(m_openPrice, 5)
         );

         m_tracked     = false;
         m_openTicket  = 0;
      }
   }

   //--------------------------------------------------
   // Registrar senal evaluada (para funnel)
   //--------------------------------------------------

   void OnSignalEvaluated(
      string direccion,
      bool ejecutada,
      string motivo)
   {
      Print(
         "TP_TEL|SENAL|",
         "dir=", direccion,
         "|ejecutada=", (int)ejecutada,
         "|motivo=", motivo
      );
   }

   //--------------------------------------------------
   // Shutdown
   //--------------------------------------------------

   void Shutdown()
   {
      Print("Telemetría detenida.");
   }

};

#endif
