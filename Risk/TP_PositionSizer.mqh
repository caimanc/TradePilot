#ifndef __TP_POSITIONSIZER_MQH__
#define __TP_POSITIONSIZER_MQH__

//+------------------------------------------------------------------+
//| Calculador de tamaño de posición                                 |
//|                                                                  |
//| Dos modos:                                                       |
//| - Override manual: usa el volumen indicado (normalizado).        |
//| - Automatico: balance x riesgo% / perdida del SL por lote.       |
//+------------------------------------------------------------------+
class CTPPositionSizer
{
private:

   double m_riskPercent;
   double m_volume;

   bool   m_manual;

public:

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

   CTPPositionSizer()
   {
      m_riskPercent = 1.0;
      m_volume = 0.01;

      m_manual = false;
   }

   //--------------------------------------------------
   // Inicialización
   //--------------------------------------------------

   bool Initialize()
   {
      Print("PositionSizer inicializado.");

      return true;
   }

   //--------------------------------------------------
   // Configurar riesgo
   //--------------------------------------------------

   void SetRiskPercent(double risk)
   {
      if(risk > 0.0)
         m_riskPercent = risk;
   }

   //--------------------------------------------------
   // Definir volumen manual (normalizado al broker)
   //--------------------------------------------------

   void SetVolumeOverride(double volumen)
   {
      if(volumen <= 0.0)
         return;

      m_volume = Normalizar(volumen);

      m_manual = true;

      Print(
         "Volumen manual    : ",
         DoubleToString(m_volume, 2)
      );
   }

   //--------------------------------------------------
   // Calcular volumen
   // Con distancia del SL resuelve el modo automatico;
   // sin distancia solo rige el override manual.
   //--------------------------------------------------

   bool Calculate(
      double distanciaSLPrecio = 0.0)
   {
      if(m_manual)
         return true;

      if(distanciaSLPrecio <= 0.0)
         return true;

      double tickValue =
         SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);

      double tickSize =
         SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

      if(tickValue <= 0.0 ||
         tickSize <= 0.0)
      {
         Print("ERROR: datos de simbolo incompletos para sizing.");

         m_volume = 0.01;

         return true;
      }

      double perdidaPorLote =
         distanciaSLPrecio / tickSize * tickValue;

      if(perdidaPorLote <= 0.0)
      {
         m_volume = 0.01;

         return true;
      }

      double riesgoUSD =
         AccountInfoDouble(ACCOUNT_BALANCE) *
         m_riskPercent / 100.0;

      m_volume = Normalizar(
         riesgoUSD / perdidaPorLote
      );

      return true;
   }

   //--------------------------------------------------
   // Obtener volumen
   //--------------------------------------------------

   double Volume() const
   {
      return m_volume;
   }

   //--------------------------------------------------
   // Modo manual
   //--------------------------------------------------

   bool IsManual() const
   {
      return m_manual;
   }

   //--------------------------------------------------
   // Shutdown
   //--------------------------------------------------

   void Shutdown()
   {
      Print("PositionSizer detenido.");
   }

private:

   //--------------------------------------------------
   // Normalizar al step/min/max del broker
   // (floor: sesga a MENOS riesgo)
   //--------------------------------------------------

   double Normalizar(double volumen)
   {
      double paso =
         SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

      double minimo =
         SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);

      double maximo =
         SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);

      if(paso > 0.0)
         volumen =
            MathFloor(volumen / paso) * paso;

      if(minimo > 0.0 &&
         volumen < minimo)
      {
         Print("AVISO: volumen bajo el minimo del broker, usando minimo.");

         volumen = minimo;
      }

      if(maximo > 0.0 &&
         volumen > maximo)
         volumen = maximo;

      return volumen;
   }

};

#endif
