#ifndef __TP_PANEL_MQH__
#define __TP_PANEL_MQH__

#include "../MarketState/TP_MarketState.mqh"
#include "../Risk/TP_RiskManager.mqh"

//+------------------------------------------------------------------+
//| Panel de estado del EA sobre el gráfico                          |
//|                                                                  |
//| Prefijo único TPPANEL_ para limpieza total en Shutdown.          |
//| Refresco por tick; los datos de posición se leen directo         |
//| del terminal para no acoplar Core.                               |
//+------------------------------------------------------------------+
class CTPPanel
{
private:

   string m_prefijo;

   string m_lineaTitulo;
   string m_lineaPerfil;
   string m_lineaHTF;

   //--------------------------------------------------
   // Crear una etiqueta de texto
   //--------------------------------------------------

   void CrearEtiqueta(
      string nombre,
      int    x,
      int    y,
      color  clr)
   {
      string id = m_prefijo + nombre;

      ObjectCreate(0, id, OBJ_LABEL, 0, 0, 0);

      ObjectSetInteger(0, id, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, id, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, id, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, id, OBJPROP_FONTSIZE, 9);
      ObjectSetString(0, id, OBJPROP_FONT, "Consolas");
      ObjectSetInteger(0, id, OBJPROP_COLOR, clr);
      ObjectSetString(0, id, OBJPROP_TEXT, " ");
   }

   //--------------------------------------------------
   // Escribir texto y color de una etiqueta
   //--------------------------------------------------

   void Escribir(
      string nombre,
      string texto,
      color  clr)
   {
      string id = m_prefijo + nombre;

      ObjectSetString(0, id, OBJPROP_TEXT, texto);

      ObjectSetInteger(0, id, OBJPROP_COLOR, clr);
   }

public:

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

   CTPPanel()
   {
      m_prefijo = "TPPANEL_";

      m_lineaTitulo = " ";
      m_lineaPerfil = " ";
      m_lineaHTF    = " ";
   }

   //--------------------------------------------------
   // Inicializar (crea objetos)
   //--------------------------------------------------

   bool Initialize(
      string simbolo,
      string txtTF,
      string txtPerfil,
      string txtHTF)
   {
      m_lineaTitulo =
         "TradePilot  " + simbolo + "  " + txtTF;

      //--------------------------------------------------
      // Quitar prefijo "PERIOD_" para lectura compacta
      //--------------------------------------------------

      string tfCorto   = txtTF;
      string htfCorto  = txtHTF;

      if(StringFind(tfCorto, "PERIOD_") == 0)
         tfCorto = StringSubstr(tfCorto, 7);

      if(StringFind(htfCorto, "PERIOD_") == 0)
         htfCorto = StringSubstr(htfCorto, 7);

      m_lineaPerfil =
         "Perfil SL   : " + txtPerfil + " pts";

      m_lineaHTF =
         "Contexto    : " + htfCorto +
         "  [grafico " + tfCorto + "]";

      string fondo = m_prefijo + "FONDO";

      ObjectCreate(0, fondo, OBJ_RECTANGLE_LABEL, 0, 0, 0);

      ObjectSetInteger(0, fondo, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, fondo, OBJPROP_XDISTANCE, 8);
      ObjectSetInteger(0, fondo, OBJPROP_YDISTANCE, 18);
      ObjectSetInteger(0, fondo, OBJPROP_XSIZE, 300);
      ObjectSetInteger(0, fondo, OBJPROP_YSIZE, 268);
      ObjectSetInteger(0, fondo, OBJPROP_BGCOLOR, C'20,24,30');
      ObjectSetInteger(0, fondo, OBJPROP_COLOR, C'70,80,95');
      ObjectSetInteger(0, fondo, OBJPROP_BACK, false);
      ObjectSetInteger(0, fondo, OBJPROP_BORDER_TYPE, BORDER_FLAT);

      int fila = 28;

      CrearEtiqueta("TITULO",   16, fila,        clrWhite);       fila += 18;
      CrearEtiqueta("PERFIL",   16, fila,        clrSilver);      fila += 18;
      CrearEtiqueta("HTF",      16, fila,        clrSilver);      fila += 18;
      CrearEtiqueta("TENDENCIA",16, fila,        clrSilver);      fila += 18;
      CrearEtiqueta("SETUP",    16, fila,        clrSilver);      fila += 18;
      CrearEtiqueta("PROB",     16, fila,        clrSilver);      fila += 18;
      CrearEtiqueta("POSICION", 16, fila,        clrSilver);      fila += 18;
      CrearEtiqueta("RIESGO",   16, fila,        clrSilver);      fila += 18;
      CrearEtiqueta("TRADES",   16, fila,        clrSilver);      fila += 18;
      CrearEtiqueta("VOLUMEN",  16, fila,        clrSilver);      fila += 18;
      CrearEtiqueta("EVAL",     16, fila,        clrSilver);      fila += 18;
      CrearEtiqueta("SESION",   16, fila,        clrSilver);      fila += 18;
      CrearEtiqueta("PATRON",   16, fila,        clrSilver);

      Print("Panel inicializado.");

      return true;
   }

   //--------------------------------------------------
   // Actualizar por tick
   //--------------------------------------------------

   void Update(
      const CTPMarketState &marketState,
      const CTPRiskManager &riskManager,
      double probBuy  = 0.0,
      double probSell = 0.0,
      double scoreThreshold = 0.0,
      bool   scoreEnabled    = false,
      string sesionName      = "",
      double sesionFactor    = 0.0,
      int    senalesEvaluadas  = 0,
      int    senalesEjecutadas = 0,
      string patronNombre      = "",
      int    patronDir         = 0,
      bool   patronConfirmado  = false)
   {
      //--------------------------------------------------
      // Contexto HTF
      //--------------------------------------------------

      color clrHTF = clrSilver;

      string txtHTF = m_lineaHTF + " : esperando";

      if(marketState.IsHtfBull())
      {
         txtHTF = m_lineaHTF + " : BULL";

         clrHTF = clrLime;
      }
      else if(marketState.IsHtfBear())
      {
         txtHTF = m_lineaHTF + " : BEAR";

         clrHTF = clrTomato;
      }
      else if(marketState.IsRange())
      {
         txtHTF = m_lineaHTF + " : NEUTRAL";
      }

      Escribir("HTF", txtHTF, clrHTF);

      //--------------------------------------------------
      // Tendencia local
      //--------------------------------------------------

      color clrTend = clrSilver;

      string txtTend = "Tendencia   : LATERAL";

      if(marketState.IsBullTrend())
      {
         txtTend = "Tendencia   : ALCISTA";

         clrTend = clrLime;
      }
      else if(marketState.IsBearTrend())
      {
         txtTend = "Tendencia   : BAJISTA";

         clrTend = clrTomato;
      }

      Escribir("TENDENCIA", txtTend, clrTend);

      //--------------------------------------------------
      // Setups validados
      //--------------------------------------------------

      string txtSetup =
         "Setup       : BUY " +
         (marketState.IsBuySetupValid() ? "OK" : "--") +
         " | SELL " +
         (marketState.IsSellSetupValid() ? "OK" : "--");

      color clrSetup =
         marketState.IsBuySetupValid() ? clrLime :
         marketState.IsSellSetupValid() ? clrTomato : clrSilver;

      Escribir("SETUP", txtSetup, clrSetup);

      //--------------------------------------------------
      // Capa de probabilidad (scoring)
      //--------------------------------------------------

      string txtProb;

      if(scoreEnabled)
      {
         txtProb = StringFormat(
            "Probabilidad: BUY %.0f%% SELL %.0f%% (min %.0f)",
            probBuy,
            probSell,
            scoreThreshold
         );
      }
      else
      {
         txtProb = StringFormat(
            "Probabilidad: BUY %.0f%% SELL %.0f%% (off)",
            probBuy,
            probSell
         );
      }

      color clrProb = clrSilver;

      if(scoreEnabled)
      {
         clrProb = (probBuy >= scoreThreshold ||
                    probSell >= scoreThreshold) ? clrLime : clrOrange;
      }

      Escribir("PROB", txtProb, clrProb);

      //--------------------------------------------------
      // Posición abierta (lectura directa del terminal)
      //--------------------------------------------------

      if(PositionSelect(_Symbol))
      {
         bool esCompra =
            PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY;

         double entrada  = PositionGetDouble(POSITION_PRICE_OPEN);
         double slActual = PositionGetDouble(POSITION_SL);

         double profitActual = 0.0;

         if(esCompra)
            profitActual = SymbolInfoDouble(_Symbol, SYMBOL_BID) - entrada;
         else
            profitActual = entrada - SymbolInfoDouble(_Symbol, SYMBOL_ASK);

         string txtPos =
            "Posicion    : " +
            (esCompra ? "BUY " : "SELL ") +
            DoubleToString(PositionGetDouble(POSITION_VOLUME), 2) +
            " @" +
            DoubleToString(entrada, 2);

         if(slActual > 0.0)
         {
            double volumen = PositionGetDouble(POSITION_VOLUME);
            double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
            double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);

            double distancia = esCompra
               ? slActual - entrada
               : entrada - slActual;

            double lockeUSD = 0.0;

            if(tickSize > 0.0 && tickValue > 0.0 && volumen > 0.0)
               lockeUSD = distancia / tickSize * volumen * tickValue;

            txtPos += "  Trail:$" +
               DoubleToString(lockeUSD, 2);
         }

         Escribir(
            "POSICION",
            txtPos,
            esCompra ? clrLime : clrTomato
         );
      }
      else
      {
         Escribir("POSICION", "Posicion    : ninguna", clrSilver);
      }

      //--------------------------------------------------
      // Riesgo diario (neto del día: +ganancia / -pérdida)
      //--------------------------------------------------

      double netoDia = riskManager.DailyNet();

      color clrRiesgo = clrSilver;

      if(netoDia <= -riskManager.MaxDailyLoss())
         clrRiesgo = clrTomato;

      else if(netoDia < 0.0)
         clrRiesgo = clrOrange;

      else if(netoDia > 0.0)
         clrRiesgo = clrLime;

      Escribir(
         "RIESGO",
         StringFormat(
            "Ganancia dia: %.2f USD",
            netoDia
         ),
         clrRiesgo
      );

      //--------------------------------------------------
      // Trades del día
      //--------------------------------------------------

      string maxTradesStr = (riskManager.MaxTrades() == 0)
         ? "∞" : IntegerToString(riskManager.MaxTrades());

      bool tradesBloqueado =
         riskManager.MaxTrades() > 0 &&
         riskManager.TradeCount() >= riskManager.MaxTrades();

      Escribir(
         "TRADES",
         StringFormat(
            "Trades hoy  : %d / %s",
            riskManager.TradeCount(),
            maxTradesStr
         ),
         tradesBloqueado ? clrTomato : clrSilver
      );

      //--------------------------------------------------
      // Volumen
      //--------------------------------------------------

      string txtVol =
         riskManager.IsManualVolume()
            ? "Volumen     : MANUAL "
            : "Volumen     : AUTO   ";

      txtVol +=
         DoubleToString(riskManager.Volume(), 2);

      Escribir(
         "VOLUMEN",
         txtVol,
         riskManager.IsManualVolume() ? clrGold : clrSilver
      );

      //--------------------------------------------------
      // Funnel de señales (evaluadas vs ejecutadas)
      //--------------------------------------------------

      Escribir(
         "EVAL",
         StringFormat(
            "Señales     : eval %d / ejec %d",
            senalesEvaluadas,
            senalesEjecutadas
         ),
         (senalesEvaluadas > 0 &&
          senalesEjecutadas == 0) ? clrOrange : clrSilver
      );

      //--------------------------------------------------
      // Sesión y factor de ponderación
      //--------------------------------------------------

      string txtSesion;

      if(sesionName == "")
      {
         txtSesion = "Sesion      : --";
      }
      else
      {
         txtSesion = StringFormat(
            "Sesion      : %s  (f %.2f)",
            sesionName,
            sesionFactor
         );
      }

      color clrSesion = clrSilver;

      if(sesionFactor <= 0.0)
         clrSesion = clrDimGray;
      else if(sesionFactor >= 0.75)
         clrSesion = clrGold;

      Escribir("SESION", txtSesion, clrSesion);

      //--------------------------------------------------
      // Patrón de vela detectado
      //--------------------------------------------------

      string txtPatron;
      color  clrPatron = clrSilver;

      if(patronNombre == "")
      {
         txtPatron = "Patron      : --";
      }
      else
      {
         // 1 = alcista, 2 = bajista
         bool esAlcista = (patronDir == 1);
         bool esBajista = (patronDir == 2);

         txtPatron = "Patron      : " + patronNombre +
            (patronConfirmado ? "  [OPERA]" : "");

         if(esAlcista)
            clrPatron = (patronConfirmado ? clrLime : clrPaleGreen);
         else if(esBajista)
            clrPatron = (patronConfirmado ? clrTomato : clrCoral);
         else
            clrPatron = clrOrange;
      }

      Escribir("PATRON", txtPatron, clrPatron);

      ChartRedraw();
   }

   //--------------------------------------------------
   // Shutdown (borra todos los objetos propios)
   //--------------------------------------------------

   void Shutdown()
   {
      ObjectsDeleteAll(0, m_prefijo);

      Print("Panel detenido.");
   }

};

#endif
