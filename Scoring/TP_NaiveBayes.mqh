//+------------------------------------------------------------------+
//| Modelo Naive Bayes vivo - TradePilot (septiembre 2026)           |
//|                                                                  |
//| Aprende EN VIVO de las operaciones cerradas del propio EA: la    |
//| telemetria (TP_Telemetry) entrega las features que hubo en la     |
//| apertura (dir, tend, htf, setup, sesion) y el resultado neto.    |
//|                                                                  |
//| Ventana deslizante: solo se conservan las ultimas               |
//| NB_MAX_SAMPLES operaciones (las mas antiguas se descartan).       |
//| Suavizado de Laplace (alpha = 1) en priors y features.           |
//|                                                                  |
//| Persistencia: MQL5/Files/TradePilot_NB.csv                      |
//| (cabecera "dir,tend,htf,setup,sesion,ganador").                  |
//|                                                                  |
//| Uso: modelo.ProbabilidadGanar(dir, tend, htf, setup, sesion)     |
//+------------------------------------------------------------------+
#ifndef __TP_NAIVEBAYES_MODEL_MQH__
#define __TP_NAIVEBAYES_MODEL_MQH__

// MQL5 no admite inicializadores en miembros de clase,
// por eso las constantes viven a nivel de archivo.

// Ventana deslizante de aprendizaje
const int    NB_MAX_SAMPLES  = 100;

// Archivo de persistencia (MQL5/Files)
const string NB_ARCHIVO      = "TradePilot_NB.csv";

// Indices de feature
const int    NB_F_DIR        = 0;
const int    NB_F_TEND       = 1;
const int    NB_F_HTF        = 2;
const int    NB_F_SETUP      = 3;
const int    NB_F_SESION     = 4;

// Cardinalidad de cada feature (valores posibles)
const int    NB_K_DIR        = 2;   // BUY, SELL
const int    NB_K_TEND       = 3;   // BULL, BEAR, RANGO
const int    NB_K_HTF        = 3;   // BULL, BEAR, NEUTRO
const int    NB_K_SETUP      = 3;   // BUY, SELL, NINGUNO
const int    NB_K_SESION     = 5;   // LONDON, LONDON_NEWYORK, NEW_YORK, SYDNEY, TOKYO


// Muestra de entrenamiento: features de la apertura + resultado
struct TPNBSample
{
   string dir;
   string tend;
   string htf;
   string setup;
   string sesion;
   int    ganador;   // 1 = ganadora, 0 = perdedora
};

class CTPNaiveBayes
{
private:

   TPNBSample m_samples[];

   // Log natural (MQL5 no tiene log natural directo)
   static double Ln(double x)
   {
      return MathLog(x);
   }

   //--------------------------------------------------
   // Contar muestras de una clase con un valor de feature
   //--------------------------------------------------

   int ContarFeature(int feature, string valor, int clase) const
   {
      int cuenta = 0;
      int total  = ArraySize(m_samples);

      for(int i = 0; i < total; i++)
      {
         if(m_samples[i].ganador != clase)
            continue;

         string v = "";

         // switch exige literales: 0..4 segun NB_F_*
         switch(feature)
         {
            case 0:  v = m_samples[i].dir;    break;
            case 1:  v = m_samples[i].tend;   break;
            case 2:  v = m_samples[i].htf;    break;
            case 3:  v = m_samples[i].setup;  break;
            default: v = m_samples[i].sesion; break;
         }

         if(v == valor)
            cuenta++;
      }

      return cuenta;
   }

   //--------------------------------------------------
   // P(feature | clase) con suavizado de Laplace
   // k = cardinalidad de la feature
   //--------------------------------------------------

   double ProbFeature(
      int    feature,
      string valor,
      int    clase,
      int    nClase,
      int    k) const
   {
      if(nClase <= 0)
         return 1.0 / (double)k;

      return (double)(ContarFeature(feature, valor, clase) + 1)
             / (double)(nClase + k);
   }

   //--------------------------------------------------
   // Añadir al final de la ventana (sin persistir)
   //--------------------------------------------------

   void Push(
      string dir,
      string tend,
      string htf,
      string setup,
      string sesion,
      int    ganador)
   {
      int total = ArraySize(m_samples);

      ArrayResize(m_samples, total + 1);

      m_samples[total].dir     = dir;
      m_samples[total].tend    = tend;
      m_samples[total].htf     = htf;
      m_samples[total].setup   = setup;
      m_samples[total].sesion  = sesion;
      m_samples[total].ganador = (ganador == 1) ? 1 : 0;

      // Ventana deslizante: se descarta la mas antigua
      while(ArraySize(m_samples) > NB_MAX_SAMPLES)
         ArrayRemove(m_samples, 0, 1);
   }

public:

   //--------------------------------------------------
   // Cargar el dataset persistente (si existe)
   //--------------------------------------------------

   void Initialize()
   {
      ArrayResize(m_samples, 0);

      int handle = FileOpen(NB_ARCHIVO,
                            FILE_READ | FILE_CSV | FILE_ANSI,
                            ',');
      if(handle == INVALID_HANDLE)
         return;   // sin dataset previo: se aprende desde cero

      while(!FileIsEnding(handle))
      {
         string dir = FileReadString(handle);

         if(dir == "")
            break;

         // Se consume la fila completa ANTES de descartar la
         // cabecera (si no, el stream quedaria desalineado)
         string tend    = FileReadString(handle);
         string htf     = FileReadString(handle);
         string setup   = FileReadString(handle);
         string sesion  = FileReadString(handle);
         string ganador = FileReadString(handle);

         // Cabecera del CSV (tolera BOM inicial)
         if(StringFind(dir, "dir") >= 0)
            continue;

         // Fila incompleta: se abandona la carga
         if(tend == "" || htf == "" ||
            setup == "" || sesion == "" || ganador == "")
            break;

         Push(dir, tend, htf, setup, sesion,
              (StringToInteger(ganador) == 1) ? 1 : 0);
      }

      FileClose(handle);
   }

   //--------------------------------------------------
   // Reescribir el dataset completo
   //--------------------------------------------------

   void Save()
   {
      int handle = FileOpen(NB_ARCHIVO,
                            FILE_WRITE | FILE_CSV | FILE_ANSI,
                            ',');
      if(handle == INVALID_HANDLE)
         return;

      FileWrite(handle,
                "dir", "tend", "htf", "setup", "sesion", "ganador");

      int total = ArraySize(m_samples);

      for(int i = 0; i < total; i++)
      {
         FileWrite(handle,
                   m_samples[i].dir,
                   m_samples[i].tend,
                   m_samples[i].htf,
                   m_samples[i].setup,
                   m_samples[i].sesion,
                   IntegerToString(m_samples[i].ganador));
      }

      FileClose(handle);
   }

   //--------------------------------------------------
   // Aprendizaje: incorporar una operacion cerrada
   //--------------------------------------------------

   void AddSample(
      string dir,
      string tend,
      string htf,
      string setup,
      string sesion,
      int    ganador)
   {
      Push(dir, tend, htf, setup, sesion, ganador);

      Save();
   }

   //--------------------------------------------------
   // Probabilidad de ganar (0..100) dadas las features
   // Devuelve -1 si el modelo no esta disponible
   //--------------------------------------------------

   double ProbabilidadGanar(
      string dir,
      string tend,
      string htf,
      string setup,
      string sesion)
   {
      int nTotal  = ArraySize(m_samples);
      int nGanar  = MuestrasGanar();
      int nPerder = nTotal - nGanar;

      // Sin historial el modelo no puede opinar
      if(nTotal == 0)
         return -1.0;

      // Ventana de una sola clase: respuesta degenerada
      if(nGanar == 0)
         return 0.0;

      if(nPerder == 0)
         return 100.0;

      // Priores con suavizado de Laplace
      double priorGanar  = (double)(nGanar  + 1)
                           / (double)(nTotal + 2);

      double priorPerder = (double)(nPerder + 1)
                           / (double)(nTotal + 2);

      double logG = Ln(priorGanar);
      double logP = Ln(priorPerder);

      logG += Ln(ProbFeature(NB_F_DIR,   dir,    1, nGanar,  NB_K_DIR))
            + Ln(ProbFeature(NB_F_TEND,  tend,   1, nGanar,  NB_K_TEND))
            + Ln(ProbFeature(NB_F_HTF,   htf,    1, nGanar,  NB_K_HTF))
            + Ln(ProbFeature(NB_F_SETUP, setup,  1, nGanar,  NB_K_SETUP))
            + Ln(ProbFeature(NB_F_SESION, sesion, 1, nGanar, NB_K_SESION));

      logP += Ln(ProbFeature(NB_F_DIR,   dir,    0, nPerder, NB_K_DIR))
            + Ln(ProbFeature(NB_F_TEND,  tend,   0, nPerder, NB_K_TEND))
            + Ln(ProbFeature(NB_F_HTF,   htf,    0, nPerder, NB_K_HTF))
            + Ln(ProbFeature(NB_F_SETUP, setup,  0, nPerder, NB_K_SETUP))
            + Ln(ProbFeature(NB_F_SESION, sesion, 0, nPerder, NB_K_SESION));

      // Normalizacion estable: restar el maximo
      double maxLog = (logG > logP) ? logG : logP;

      double eG = MathExp(logG - maxLog);
      double eP = MathExp(logP - maxLog);

      if(eG + eP <= 0.0)
         return -1.0;

      return eG / (eG + eP) * 100.0;
   }

   //--------------------------------------------------
   // Exposicion de metadatos del modelo (para el panel)
   //--------------------------------------------------

   int Muestras() const
   {
      return ArraySize(m_samples);
   }

   int MuestrasGanar() const
   {
      int cuenta = 0;
      int total  = ArraySize(m_samples);

      for(int i = 0; i < total; i++)
      {
         if(m_samples[i].ganador == 1)
            cuenta++;
      }

      return cuenta;
   }

   string Nombre() const
   {
      return "NB vivo sep-2026";
   }

};

#endif
