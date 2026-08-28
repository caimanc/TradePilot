#ifndef __TP_SIGNALMANAGER_MQH__
#define __TP_SIGNALMANAGER_MQH__

#include "TP_TrendSignal.mqh"
#include "TP_PatternDetector.mqh"
#include "../MarketState/TP_MarketState.mqh"
#include "../Scoring/TP_ProbabilityScorer.mqh"

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
      double wTendencia,
      double wHtf,
      double wSetup,
      double wSesion)
   {
      m_probabilityScorer.SetParams(
         threshold,
         wTendencia,
         wHtf,
         wSetup,
         wSesion
      );
   }

   //--------------------------------------------------
   // Configurar sesiones del scoring
   //--------------------------------------------------

   void SetScoreSessions(int brokerUtcOffset)
   {
      m_probabilityScorer.SetSessions(brokerUtcOffset);
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
      m_ventaPatron  = m_entradaPatron && m_patronBaj;

      return ok;
   }

   //--------------------------------------------------
   // Getters
   //--------------------------------------------------

   bool Buy() const
   {
      return (m_trendSignal.Buy() &&
              m_probabilityScorer.Buy()) ||
             m_compraPatron;
   }

   bool Sell() const
   {
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