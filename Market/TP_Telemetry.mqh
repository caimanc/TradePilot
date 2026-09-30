#ifndef __TP_TELEMETRY_MQH__
#define __TP_TELEMETRY_MQH__

#include "../Signals/TP_SignalManager.mqh"
#include "../Scoring/TP_NaiveBayes.mqh"

//+------------------------------------------------------------------+
//| Telemetria por operacion                                         |
//|                                                                  |
//| Registra en el log educativo cada operacion (entrada/cierre)     |
//| con los features activos, para el Naive Bayes vivo               |
//| y para medir el impacto de noticias de forma externa.            |
//|                                                                  |
//| Ademas, alimenta el aprendizaje: guarda las features de la       |
//| entrada y al cerrar entrega la muestra (features + resultado)    |
//| al modelo, que persiste su ventana deslizante en un CSV.         |
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

   //--------------------------------------------------
   // Features de la entrada (muestra para el NB)
   //--------------------------------------------------

   string m_openDir;
   string m_openTend;
   string m_openHtf;
   string m_openSetup;
   string m_openSesion;

   //--------------------------------------------------
   // Modelo vivo (aprendizaje en linea)
   //--------------------------------------------------

   CTPNaiveBayes *m_model;

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

      m_openDir    = "";
      m_openTend   = "";
      m_openHtf    = "";
      m_openSetup  = "";
      m_openSesion = "";

      m_model = NULL;
   }

   //--------------------------------------------------
   // Conectar el modelo que aprende de la telemetria
   //--------------------------------------------------

   void SetNBModel(CTPNaiveBayes &model)
   {
      m_model = GetPointer(model);
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
      double volumen,
      const CTPMarketState &marketState,
      const CTPSignalManager &signals)
   {
      m_openTicket = ticket;
      m_signalId   = signalId;
      m_tracked    = true;
      m_openTime   = TimeCurrent();
      m_openPrice  = precio;

      //--------------------------------------------------
      // Features del modelo en el momento de la entrada
      // (para el futuro dataset del Naive Bayes)
      //--------------------------------------------------

      string tend = marketState.IsBullTrend() ? "BULL" :
                    (marketState.IsBearTrend() ? "BEAR" : "RANGO");

      string htf = marketState.IsHtfBull() ? "BULL" :
                   (marketState.IsHtfBear() ? "BEAR" : "NEUTRO");

      string setup = marketState.IsBuySetupValid() ? "BUY" :
                     (marketState.IsSellSetupValid() ? "SELL" : "NINGUNO");

      //--------------------------------------------------
      // Se guardan para que al cerrar la operacion el
      // modelo pueda aprender de esta muestra
      //--------------------------------------------------

      m_openDir    = direccion;
      m_openTend   = tend;
      m_openHtf    = htf;
      m_openSetup  = setup;
      m_openSesion = signals.SesionName();

      Print(
         "TP_TEL|ENTRADA|",
         "ticket=", ticket,
         "|senal=", signalId,
         "|dir=", direccion,
         "|precio=", DoubleToString(precio, 5),
         "|sl=", DoubleToString(sl, 5),
         "|tp=", DoubleToString(tp, 5),
         "|vol=", DoubleToString(volumen, 2),
         "|time=", TimeToString(m_openTime),
         "|tend=", tend,
         "|htf=", htf,
         "|setup=", setup,
         "|sesion=", signals.SesionName(),
         "|patron=", signals.UltimoPatron(),
         "|pdir=", signals.PatronDireccion(),
         "|pmot=", signals.PatronMotivo(),
         "|adx=", DoubleToString(marketState.TrendStrength(), 1)
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

         //--------------------------------------------------
         // Aprendizaje: la operacion cerrada es una muestra
         // nueva del modelo (features de entrada + resultado)
         //--------------------------------------------------

         if(m_model != NULL)
         {
            m_model.AddSample(
               m_openDir,
               m_openTend,
               m_openHtf,
               m_openSetup,
               m_openSesion,
               (resultadoNeto > 0.0) ? 1 : 0
            );
         }

         m_openDir     = "";
         m_openTend    = "";
         m_openHtf     = "";
         m_openSetup   = "";
         m_openSesion  = "";

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
