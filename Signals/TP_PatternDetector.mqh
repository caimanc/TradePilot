#ifndef __TP_PATTERNDETECTOR_MQH__
#define __TP_PATTERNDETECTOR_MQH__

#include "../Market/TP_PriceSeries.mqh"

//+------------------------------------------------------------------+
//| Enums para patrones de vela                                       |
//+------------------------------------------------------------------+

enum ENUM_TP_PATRON_DIR
{
   TP_PATRON_NEUTRA  = 0,   // Sin dirección clara (indecisión/compactación)
   TP_PATRON_ALCISTA = 1,   // Dirección alcista
   TP_PATRON_BAJISTA = 2    // Dirección bajista
};

enum ENUM_TP_PATRON_CONF
{
   TP_PATRON_CONF_BAJA  = 0,  // Baja confianza
   TP_PATRON_CONF_MEDIA = 1,  // Media confianza
   TP_PATRON_CONF_ALTA  = 2   // Alta confianza
};

//+------------------------------------------------------------------+
//| Detector de patrones de vela (OHLC puro, velas CERRADAS)         |
//| Prioridad fija: 3S/3C estricto (rev) > 3S/3C (cont) >            |
//|                 Engulfing > Marubozu > Doji > Inside Bar          |
//| Solo lee datos de CTPPriceSeries — NO llama Update()             |
//+------------------------------------------------------------------+
class CTPPatternDetector
{
private:

   ENUM_TP_PATRON_DIR  m_dir;
   ENUM_TP_PATRON_CONF m_conf;
   string              m_nombre;    // "Engulfing alcista", "3 Cuervos", ...
   string              m_motivo;    // "reversión" | "continuación" | "indecisión" | "compactación"

   //--------------------------------------------------
   // Helpers OHLC
   //--------------------------------------------------

   double Cuerpo(double open, double close) const
   {
      return MathAbs(close - open);
   }

   double Range(double high, double low) const
   {
      return high - low;
   }

   //--------------------------------------------------
   // 3 Soldados (alcista) / 3 Cuervos (bajista)
   // 3 velas consecutivas con cierres progresivos
   // Velas en shift 1 (más reciente), 2, 3 (más antigua)
   //--------------------------------------------------

   bool Detectar3Soldados(const CTPPriceSeries &prices)
   {
      // Velas 3→2→1 (antigua a reciente)
      bool v3Alc = prices.Close(3) > prices.Open(3);
      bool v2Alc = prices.Close(2) > prices.Open(2);
      bool v1Alc = prices.Close(1) > prices.Open(1);

      if(v3Alc && v2Alc && v1Alc &&
         prices.Close(1) > prices.Close(2) &&
         prices.Close(2) > prices.Close(3))
      {
         m_dir     = TP_PATRON_ALCISTA;
         m_conf    = TP_PATRON_CONF_ALTA;
         m_nombre  = "3 Soldados";
         m_motivo  = "continuación";
         return true;
      }

      // 3 Cuervos (bajista)
      bool v3Baj = prices.Close(3) < prices.Open(3);
      bool v2Baj = prices.Close(2) < prices.Open(2);
      bool v1Baj = prices.Close(1) < prices.Open(1);

      if(v3Baj && v2Baj && v1Baj &&
         prices.Close(1) < prices.Close(2) &&
         prices.Close(2) < prices.Close(3))
      {
         m_dir     = TP_PATRON_BAJISTA;
         m_conf    = TP_PATRON_CONF_ALTA;
         m_nombre  = "3 Cuervos";
         m_motivo  = "continuación";
         return true;
      }

      return false;
   }

   //--------------------------------------------------
   // 3 Cuervos ESTRICTO (bajista, REVERSIÓN)
   // 3 velas bajistas con cierres descendentes Y cada
   // apertura DENTRO del cuerpo de la vela anterior
   // (presión bajista sostenida sin gaps = reversión)
   // Velas en shift 1 (más reciente), 2, 3 (más antigua)
   //--------------------------------------------------

   bool Detectar3CuervosEstricto(const CTPPriceSeries &prices)
   {
      // 3 velas bajistas (cierre < apertura)
      if(prices.Close(1) >= prices.Open(1) ||
         prices.Close(2) >= prices.Open(2) ||
         prices.Close(3) >= prices.Open(3))
         return false;

      // Cierres descendentes progresivos
      if(prices.Close(1) >= prices.Close(2) ||
         prices.Close(2) >= prices.Close(3))
         return false;

      // Contención de cuerpo (vela n bajista → cuerpo [Close(n), Open(n)]):
      // apertura de la vela más reciente dentro del cuerpo de la anterior
      if(!(prices.Close(2) < prices.Open(1) && prices.Open(1) < prices.Open(2)))
         return false;

      if(!(prices.Close(3) < prices.Open(2) && prices.Open(2) < prices.Open(3)))
         return false;

      m_dir     = TP_PATRON_BAJISTA;
      m_conf    = TP_PATRON_CONF_ALTA;
      m_nombre  = "3 Cuervos estricto";
      m_motivo  = "reversión";
      return true;
   }

   //--------------------------------------------------
   // 3 Soldados ESTRICTO (alcista, REVERSIÓN)
   // 3 velas alcistas con cierres ascendentes Y cada
   // apertura DENTRO del cuerpo de la vela anterior
   //--------------------------------------------------

   bool Detectar3SoldadosEstricto(const CTPPriceSeries &prices)
   {
      // 3 velas alcistas (cierre > apertura)
      if(prices.Close(1) <= prices.Open(1) ||
         prices.Close(2) <= prices.Open(2) ||
         prices.Close(3) <= prices.Open(3))
         return false;

      // Cierres ascendentes progresivos
      if(prices.Close(1) <= prices.Close(2) ||
         prices.Close(2) <= prices.Close(3))
         return false;

      // Contención de cuerpo (vela n alcista → cuerpo [Open(n), Close(n)]):
      // apertura de la vela más reciente dentro del cuerpo de la anterior
      if(!(prices.Open(2) < prices.Open(1) && prices.Open(1) < prices.Close(2)))
         return false;

      if(!(prices.Open(3) < prices.Open(2) && prices.Open(2) < prices.Close(3)))
         return false;

      m_dir     = TP_PATRON_ALCISTA;
      m_conf    = TP_PATRON_CONF_ALTA;
      m_nombre  = "3 Soldados estricto";
      m_motivo  = "reversión";
      return true;
   }

   //--------------------------------------------------
   // Engulfing (estricto: vela anterior debe tener
   // cuerpo en dirección opuesta)
   // Alcista: vela2 bajista + vela1 alcista engloba
   // Bajista: vela2 alcista + vela1 bajista engloba
   //--------------------------------------------------

   bool DetectarEngulfing(const CTPPriceSeries &prices)
   {
      double o1 = prices.Open(1),  c1 = prices.Close(1);
      double o2 = prices.Open(2),  c2 = prices.Close(2);

      double cuerpo1 = Cuerpo(o1, c1);
      double cuerpo2 = Cuerpo(o2, c2);

      //--------------------------------------------------
      // Engulfing alcista: vela2 bajista, vela1 alcista
      // cuerpo1 engloba completamente a cuerpo2
      //--------------------------------------------------

      if(c1 > o1 && c2 < o2 &&
         o1 <= o2 && c1 >= c2)
      {
         m_dir = TP_PATRON_ALCISTA;
         m_motivo = "reversión";

         // Confianza por firmeza del cierre
         if(cuerpo2 == 0.0 || cuerpo1 > 1.5 * cuerpo2)
            m_conf = TP_PATRON_CONF_ALTA;
         else if(cuerpo1 > cuerpo2)
            m_conf = TP_PATRON_CONF_MEDIA;
         else
            m_conf = TP_PATRON_CONF_BAJA;

         m_nombre = "Engulfing alcista";
         return true;
      }

      //--------------------------------------------------
      // Engulfing bajista: vela2 alcista, vela1 bajista
      // cuerpo1 engloba completamente a cuerpo2
      //--------------------------------------------------

      if(c1 < o1 && c2 > o2 &&
         o1 >= o2 && c1 <= c2)
      {
         m_dir = TP_PATRON_BAJISTA;
         m_motivo = "reversión";

         if(cuerpo2 == 0.0 || cuerpo1 > 1.5 * cuerpo2)
            m_conf = TP_PATRON_CONF_ALTA;
         else if(cuerpo1 > cuerpo2)
            m_conf = TP_PATRON_CONF_MEDIA;
         else
            m_conf = TP_PATRON_CONF_BAJA;

         m_nombre = "Engulfing bajista";
         return true;
      }

      return false;
   }

   //--------------------------------------------------
   // Marubozu: cuerpo casi puro (mechas < 10% del range)
   // Guard: range > 0 (vela plana = skip)
   //--------------------------------------------------

   bool DetectarMarubozu(const CTPPriceSeries &prices)
   {
      double o = prices.Open(1);
      double c = prices.Close(1);
      double h = prices.High(1);
      double l = prices.Low(1);

      double r = Range(h, l);

      // Vela plana: sin rango, no hay Marubozu
      if(r <= 0.0)
         return false;

      double cuerpo = Cuerpo(o, c);

      // Al menos 30% del rango debe ser cuerpo para ser Marubozu
      if(cuerpo < 0.3 * r)
         return false;

      double mechaSup = (h - MathMax(o, c)) / r;
      double mechaInf = (MathMin(o, c) - l) / r;

      //--------------------------------------------------
      // Marubozu alcista
      //--------------------------------------------------

      if(c > o && mechaSup < 0.1 && mechaInf < 0.1)
      {
         m_dir     = TP_PATRON_ALCISTA;
         m_conf    = TP_PATRON_CONF_ALTA;
         m_nombre  = "Marubozu alcista";
         m_motivo  = "continuación";
         return true;
      }

      //--------------------------------------------------
      // Marubozu bajista
      //--------------------------------------------------

      if(c < o && mechaSup < 0.1 && mechaInf < 0.1)
      {
         m_dir     = TP_PATRON_BAJISTA;
         m_conf    = TP_PATRON_CONF_ALTA;
         m_nombre  = "Marubozu bajista";
         m_motivo  = "continuación";
         return true;
      }

      return false;
   }

   //--------------------------------------------------
   // Doji: cuerpo < 10% del rango total
   // Dirección NEUTRA (indecisión/giro)
   //--------------------------------------------------

   bool DetectarDoji(const CTPPriceSeries &prices)
   {
      double o = prices.Open(1);
      double c = prices.Close(1);
      double h = prices.High(1);
      double l = prices.Low(1);

      double r = Range(h, l);

      if(r <= 0.0)
         return false;

      if(Cuerpo(o, c) / r < 0.1)
      {
         m_dir     = TP_PATRON_NEUTRA;
         m_conf    = TP_PATRON_CONF_MEDIA;
         m_nombre  = "Doji";
         m_motivo  = "indecisión";
         return true;
      }

      return false;
   }

   //--------------------------------------------------
   // Inside Bar: vela1 contenida en vela2
   // Dirección NEUTRA (compactación)
   //--------------------------------------------------

   bool DetectarInsideBar(const CTPPriceSeries &prices)
   {
      if(prices.High(1) <= prices.High(2) &&
         prices.Low(1)  >= prices.Low(2))
      {
         m_dir     = TP_PATRON_NEUTRA;
         m_conf    = TP_PATRON_CONF_BAJA;
         m_nombre  = "Inside Bar";
         m_motivo  = "compactación";
         return true;
      }

      return false;
   }

public:

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

   CTPPatternDetector()
   {
      m_dir    = TP_PATRON_NEUTRA;
      m_conf   = TP_PATRON_CONF_BAJA;
      m_nombre = "";
      m_motivo = "";
   }

   //--------------------------------------------------
   // Actualizar detección (llamar UNA vez por vela nueva)
   // Lee datos del array cacheado de CTPPriceSeries.
   // NO llama prices.Update() — Core lo hace.
   // Prioridad fija: 3S/3C estricto (rev) > 3S/3C (cont) >
   //                  Engulfing > Marubozu > Doji > Inside Bar
   //--------------------------------------------------

   bool Update(const CTPPriceSeries &prices)
   {
      // Resetear estado
      m_dir    = TP_PATRON_NEUTRA;
      m_conf   = TP_PATRON_CONF_BAJA;
      m_nombre = "";
      m_motivo = "";

      if(prices.Bars() < 4)
         return false;

      // Primera coincidencia gana (prioridad fija D9)
      // Reversión estricta > continuación > resto
      if(Detectar3CuervosEstricto(prices))
         return true;

      if(Detectar3SoldadosEstricto(prices))
         return true;

      if(Detectar3Soldados(prices))
         return true;

      if(DetectarEngulfing(prices))
         return true;

      if(DetectarMarubozu(prices))
         return true;

      if(DetectarDoji(prices))
         return true;

      if(DetectarInsideBar(prices))
         return true;

      return false;
   }

   //--------------------------------------------------
   // ¿Hay patrón direccional con confianza ≥ MEDIA?
   //--------------------------------------------------

   bool Activo() const
   {
      return m_dir != TP_PATRON_NEUTRA &&
             m_conf >= TP_PATRON_CONF_MEDIA;
   }

   //--------------------------------------------------
   // Dirección del patrón
   //--------------------------------------------------

   bool EsAlcista() const
   {
      return m_dir == TP_PATRON_ALCISTA;
   }

   bool EsBajista() const
   {
      return m_dir == TP_PATRON_BAJISTA;
   }

   //--------------------------------------------------
   // Nombre del patrón detectado (para comment)
   //--------------------------------------------------

   string UltimoPatron() const
   {
      return m_nombre;
   }

   //--------------------------------------------------
   // Motivo del patrón (para comment)
   //--------------------------------------------------

   string Motivo() const
   {
      return m_motivo;
   }

   //--------------------------------------------------
   // Getters de dirección y confianza
   //--------------------------------------------------

   ENUM_TP_PATRON_DIR Direccion() const
   {
      return m_dir;
   }

   ENUM_TP_PATRON_CONF Confianza() const
   {
      return m_conf;
   }
};

#endif
