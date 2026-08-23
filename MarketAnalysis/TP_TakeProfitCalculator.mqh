#ifndef __TP_TAKEPROFITCALCULATOR_MQH__
#define __TP_TAKEPROFITCALCULATOR_MQH__

//+------------------------------------------------------------------+
//| Take Profit Calculator                                           |
//|                                                                  |
//| Calcula el TP como múltiplo RR de la distancia del SL            |
//| estructural ya calculada para la vela en curso.                  |
//|                                                                  |
//| IMPORTANTE:                                                      |
//| El balance de la cuenta NO determina el nivel del TP.            |
//+------------------------------------------------------------------+
class CTPTakeProfitCalculator
{
private:

   //--------------------------------------------------
   // Configuración
   //--------------------------------------------------

   double m_rrMultiplier;

   //--------------------------------------------------
   // Estado
   //--------------------------------------------------

   double m_buyTakeProfit;

   double m_sellTakeProfit;

   bool m_initialized;


public:

   //==================================================
   // Constructor
   //==================================================

   CTPTakeProfitCalculator()
   {
      m_rrMultiplier = 1.5;

      m_buyTakeProfit = 0.0;

      m_sellTakeProfit = 0.0;

      m_initialized = false;
   }


   //==================================================
   // Inicialización
   //==================================================

   bool Initialize(
      double rrMultiplier = 1.5)
   {
      if(rrMultiplier <= 0.0)
         return false;


      m_rrMultiplier = rrMultiplier;


      m_buyTakeProfit = 0.0;

      m_sellTakeProfit = 0.0;

      m_initialized = true;


      Print("TakeProfitCalculator inicializado.");

      Print(
         "RR Multiplier  : ",
         DoubleToString(
            m_rrMultiplier,
            2)
      );


      return true;
   }


   //==================================================
   // Calcular TP para ambos lados
   //==================================================

   bool Calculate(
      bool buySLCalculated,
      double buyEntry,
      double buyDistance,
      bool sellSLCalculated,
      double sellEntry,
      double sellDistance)
   {
      if(!m_initialized)
         return false;


      //--------------------------------------------------
      // Reset por vela: sin datos frescos no hay TP
      //--------------------------------------------------

      m_buyTakeProfit = 0.0;

      m_sellTakeProfit = 0.0;


      //--------------------------------------------------
      // BUY: TP encima de la entrada
      //--------------------------------------------------

      if(buySLCalculated &&
         buyEntry > 0.0 &&
         buyDistance > 0.0)
      {
         m_buyTakeProfit =
            buyEntry +
            m_rrMultiplier * buyDistance;
      }


      //--------------------------------------------------
      // SELL: TP debajo de la entrada
      //--------------------------------------------------

      if(sellSLCalculated &&
         sellEntry > 0.0 &&
         sellDistance > 0.0)
      {
         m_sellTakeProfit =
            sellEntry -
            m_rrMultiplier * sellDistance;
      }


      return true;
   }


   //==================================================
   // Take Profit BUY
   //==================================================

   double BuyTakeProfit() const
   {
      return m_buyTakeProfit;
   }


   //==================================================
   // Take Profit SELL
   //==================================================

   double SellTakeProfit() const
   {
      return m_sellTakeProfit;
   }


   //==================================================
   // Shutdown
   //==================================================

   void Shutdown()
   {
      m_buyTakeProfit = 0.0;

      m_sellTakeProfit = 0.0;

      m_initialized = false;

      Print("TakeProfitCalculator detenido.");
   }
};

#endif
