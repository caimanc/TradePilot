#ifndef __TP_SIGNALMANAGER_MQH__
#define __TP_SIGNALMANAGER_MQH__

#include "TP_TrendSignal.mqh"
#include "TP_PatternDetector.mqh"
#include "../MarketState/TP_MarketState.mqh"
#include "../Scoring/TP_ProbabilityScorer.mqh"
#include "../Scoring/TP_NaiveBayes.mqh"
#include "../MarketAnalysis/TP_VWAP.mqh"
#include "../MarketAnalysis/TP_SweepDetector.mqh"
#include "../MarketAnalysis/TP_DeltaFlow.mqh"

//+------------------------------------------------------------------+
//| Administrador de señales                                         |
//+------------------------------------------------------------------+
class CTPSignalManager
{
private:

   CTPTrendSignal m_trendSignal;

   CTPProbabilityScorer m_probabilityScorer;

   //--------------------------------------------------
   // Detector de patrones de vela (camino de suficiencia)
   //--------------------------------------------------

   CTPPatternDetector m_patternDetector;

   bool m_entradaPatron;   // maestro ∧ modo entrada activos
   bool m_salidaPatron;    // maestro ∧ modo agotamiento activos

   bool m_patronAlc;       // patrón direccional alcista confirmado (cache por vela)
   bool m_patronBaj;       // patrón direccional bajista confirmado (cache por vela)

   bool m_compraPatron;    // m_patronAlc ∧ m_entradaPatron
   bool m_ventaPatron;     // m_patronBaj ∧ m_entradaPatron

   //--------------------------------------------------
   // Análisis avanzado (opcional)
   //--------------------------------------------------

   bool m_vwapActivo;      // filtro direccional por VWAP

   CTPVWAP *m_vwap;

   bool m_barridoActivo;   // refuerzo/invalidación por barrido de liquidez

   CTPSweepDetector *m_sweeper;

   //--------------------------------------------------
   // Confirmación del patrón (regla D3)
   // direccional ∧ conf≥MEDIA ∧ alineado ∧ ¬opuesto
   //--------------------------------------------------

   bool Confirmar(const CTPMarketState &ms, bool alcista) const
   {
      bool alineado = alcista
         ? (ms.IsBullTrend() || ms.IsHtfBull())
         : (ms.IsBearTrend() || ms.IsHtfBear());

      bool opuesto = alcista
         ? (ms.IsBearTrend() || ms.IsHtfBear())
         : (ms.IsBullTrend() || ms.IsHtfBull());

      return alineado && !opuesto;
   }

public:

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

   CTPSignalManager()
   {
      m_entradaPatron = false;
      m_salidaPatron  = false;
      m_patronAlc     = false;
      m_patronBaj     = false;
      m_compraPatron  = false;
      m_ventaPatron   = false;

      m_vwapActivo    = false;
      m_vwap          = NULL;
      m_barridoActivo = false;
      m_sweeper       = NULL;
   }

   //--------------------------------------------------
   // Configurar parámetros del módulo de patrones
   // activo = maestro; entrada/agotamiento = modos
   //--------------------------------------------------

   void SetPatronParams(bool activo, bool entrada, bool agotamiento)
   {
      m_entradaPatron = activo && entrada;
      m_salidaPatron  = activo && agotamiento;

      m_patronAlc     = false;
      m_patronBaj     = false;
      m_compraPatron  = false;
      m_ventaPatron   = false;
   }

   //--------------------------------------------------
   // Configurar capa de probabilidad
   //--------------------------------------------------

   void SetScoreParams(
      double threshold,
      bool nbActivo)
   {
      m_probabilityScorer.SetParams(threshold);
      m_probabilityScorer.SetNBActivo(nbActivo);
   }

   //--------------------------------------------------
   // Conectar el modelo vivo del scoring
   //--------------------------------------------------

   void SetNBModel(CTPNaiveBayes &model)
   {
      m_probabilityScorer.SetModel(model);
   }

   //--------------------------------------------------
   // Configurar sesiones del scoring
   //--------------------------------------------------

   void SetScoreSessions(int brokerUtcOffset)
   {
      m_probabilityScorer.SetSessions(brokerUtcOffset);
   }

   //--------------------------------------------------
   // Configurar análisis avanzado (VWAP + barrido)
   //--------------------------------------------------

   void SetAnalisisAvanzado(
      bool vwapActivo,
      CTPVWAP &vwap,
      bool barridoActivo,
      CTPSweepDetector &sweeper)
   {
      m_vwapActivo    = vwapActivo;
      m_barridoActivo = barridoActivo;

      m_vwap    = GetPointer(vwap);
      m_sweeper = GetPointer(sweeper);
   }

   //--------------------------------------------------
   // Configurar feature de flujo/delta del scoring
   //--------------------------------------------------

   void SetDeltaDetector(
      bool deltaActivo,
      CTPDeltaFlow &delta)
   {
      m_probabilityScorer.SetDeltaActivo(deltaActivo);
      m_probabilityScorer.SetDeltaFlow(delta);
   }

   //--------------------------------------------------
   // Actualizar señales
   //--------------------------------------------------

   bool Update(const CTPMarketState &marketState, const CTPPriceSeries &prices)
   {
      bool ok = m_trendSignal.Update(marketState);

      m_probabilityScorer.Update(marketState);

      //--------------------------------------------------
      // Camino B: detector de patrones (velas cerradas)
      //--------------------------------------------------

      m_patternDetector.Update(prices);

      m_patronAlc = m_patternDetector.Activo() &&
                    m_patternDetector.EsAlcista() &&
                    Confirmar(marketState, true);

      m_patronBaj = m_patternDetector.Activo() &&
                    m_patternDetector.EsBajista() &&
                    Confirmar(marketState, false);

      m_compraPatron = m_entradaPatron && m_patronAlc;

      // Barrido de liquidez: si se barrio el maximo, el patron
      // alcista queda invalidado para esta vela
      if(m_barridoActivo && m_sweeper != NULL &&
         m_sweeper.BarridoBajista())
      {
         m_compraPatron = false;
      }

      m_ventaPatron  = m_entradaPatron && m_patronBaj;

      // Simetrico: el barrido del minimo invalida el patron bajista
      if(m_barridoActivo && m_sweeper != NULL &&
         m_sweeper.BarridoAlcista())
      {
         m_ventaPatron = false;
      }

      return ok;
   }

   //--------------------------------------------------
   // Getters
   //--------------------------------------------------

   bool Buy() const
   {
      // Filtro direccional VWAP (solo si esta activo y hay datos)
      if(m_vwapActivo && m_vwap != NULL &&
         !m_vwap.PermiteCompra(SymbolInfoDouble(_Symbol, SYMBOL_ASK)))
         return false;

      return (m_trendSignal.Buy() &&
              m_probabilityScorer.Buy()) ||
             m_compraPatron;
   }

   bool Sell() const
   {
      // Filtro direccional VWAP (solo si esta activo y hay datos)
      if(m_vwapActivo && m_vwap != NULL &&
         !m_vwap.PermiteVenta(SymbolInfoDouble(_Symbol, SYMBOL_BID)))
         return false;

      return (m_trendSignal.Sell() &&
              m_probabilityScorer.Sell()) ||
             m_ventaPatron;
   }

   //--------------------------------------------------
   // Patrones confirmados para salida por agotamiento
   // (solo afirman cuando el modo agotamiento está activo)
   //--------------------------------------------------

   bool PatronAlcistaConfirmado() const
   {
      return m_salidaPatron && m_patronAlc;
   }

   bool PatronBajistaConfirmado() const
   {
      return m_salidaPatron && m_patronBaj;
   }

   //--------------------------------------------------
   // Freno de salida anticipada: interruptor del modo agotamiento
   // (Maestro ∧ modo agotamiento activos). Controla el cierre por
   // patrón contrario y por inversión de tendencia (freno mixto)
   //--------------------------------------------------

   bool SalidaPatronActiva() const
   {
      return m_salidaPatron;
   }

   //--------------------------------------------------
   // Nombre del patrón detectado (para alertas/comment)
   //--------------------------------------------------

   string UltimoPatron() const
   {
      return m_patternDetector.UltimoPatron();
   }

   //--------------------------------------------------
   // Estado del patrón para el panel
   //--------------------------------------------------

   // Dirección del patrón detectado (0 neutra, 1 alcista, 2 bajista)
   int PatronDireccion() const
   {
      return (int)m_patternDetector.Direccion();
   }

   string PatronMotivo() const
   {
      return m_patternDetector.Motivo();
   }

   bool PatronConfirmado() const
   {
      return m_patronAlc || m_patronBaj;
   }

   //--------------------------------------------------
   // Comment de la orden según la ruta activa
   // Vacío si NO abre la ruta del patrón
   //--------------------------------------------------

   string CommentBuy() const
   {
      if(m_compraPatron)
         return "TradePilot BUY | patrón: " + m_patternDetector.UltimoPatron() +
                " (" + m_patternDetector.Motivo() + ")";
      return "TradePilot BUY";
   }

   string CommentSell() const
   {
      if(m_ventaPatron)
         return "TradePilot SELL | patrón: " + m_patternDetector.UltimoPatron() +
                " (" + m_patternDetector.Motivo() + ")";
      return "TradePilot SELL";
   }

   //--------------------------------------------------
   // Probabilidades para el panel
   //--------------------------------------------------

   double BuyProbability() const
   {
      return m_probabilityScorer.BuyProbability();
   }

   double SellProbability() const
   {
      return m_probabilityScorer.SellProbability();
   }

   double ScoreThreshold() const
   {
      return m_probabilityScorer.Threshold();
   }

   bool ScoreEnabled() const
   {
      return m_probabilityScorer.Enabled();
   }

   bool ScoreNBActivo() const
   {
      return m_probabilityScorer.NBActivo();
   }

   double SesionFactor() const
   {
      return m_probabilityScorer.SesionFactor();
   }

   string SesionName() const
   {
      return m_probabilityScorer.SesionName();
   }

   //--------------------------------------------------
   // Reset
   //--------------------------------------------------

   void Reset()
   {
      // Reservado para futuras señales
   }

};

#endif