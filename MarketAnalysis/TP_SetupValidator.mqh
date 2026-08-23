#ifndef __TP_SETUPVALIDATOR_MQH__
#define __TP_SETUPVALIDATOR_MQH__

// Razones de validación (convención ENUM_TP_, primer valor 0).
enum ENUM_TP_SETUP_VALIDATION
{
   TP_SETUP_OK = 0,
   TP_SETUP_NO_INICIALIZADO,
   TP_SETUP_SL_NO_CALCULADO,
   TP_SETUP_DATOS_INVALIDOS,
   TP_SETUP_SL_MUY_CORTO,
   TP_SETUP_SL_MUY_AMPLIO,
   TP_SETUP_ATR_INCOHERENTE,
   TP_SETUP_SPREAD_ALTO,
   TP_SETUP_STOPS_LEVEL_INVALIDO
};

//+------------------------------------------------------------------+
//| Setup Validator                                                  |
//|                                                                  |
//| Valida el SL estructural calculado antes de dimensionar volumen. |
//|                                                                  |
//| IMPORTANTE:                                                      |
//| Validación determinista y fail-safe: entrada inválida ⇒ rechazo. |
//| El balance de la cuenta NO interviene en la validación.          |
//+------------------------------------------------------------------+
class CTPSetupValidator
{
private:

   //--------------------------------------------------
   // Configuración
   //--------------------------------------------------

   double m_minSLPoints;

   double m_maxSLPoints;

   double m_maxSpreadPoints;

   double m_atrMinMultiplier;

   double m_atrMaxMultiplier;

   //--------------------------------------------------
   // Estado
   //--------------------------------------------------

   bool m_buyValid;

   bool m_sellValid;

   ENUM_TP_SETUP_VALIDATION m_buyReason;

   ENUM_TP_SETUP_VALIDATION m_sellReason;

   bool m_initialized;


public:

   //==================================================
   // Constructor
   //==================================================

   CTPSetupValidator()
   {
      m_minSLPoints = 30.0;

      m_maxSLPoints = 400.0;

      m_maxSpreadPoints = 50.0;

      m_atrMinMultiplier = 0.5;

      m_atrMaxMultiplier = 4.0;

      m_buyValid = false;

      m_sellValid = false;

      m_buyReason = TP_SETUP_NO_INICIALIZADO;

      m_sellReason = TP_SETUP_NO_INICIALIZADO;

      m_initialized = false;
   }


   //==================================================
   // Inicialización
   //==================================================

   bool Initialize(
      double minSLPoints = 30.0,
      double maxSLPoints = 400.0,
      double maxSpreadPoints = 50.0,
      double atrMinMult = 0.5,
      double atrMaxMult = 4.0)
   {
      if(minSLPoints <= 0.0)
      {
         Print("ERROR: SetupValidator - MinSLPoints debe ser mayor que cero.");

         return false;
      }

      if(maxSLPoints < minSLPoints)
      {
         Print("ERROR: SetupValidator - MaxSLPoints debe ser mayor o igual que MinSLPoints.");

         return false;
      }

      if(maxSpreadPoints <= 0.0)
      {
         Print("ERROR: SetupValidator - MaxSpreadPoints debe ser mayor que cero.");

         return false;
      }

      if(atrMinMult <= 0.0)
      {
         Print("ERROR: SetupValidator - AtrMinMult debe ser mayor que cero.");

         return false;
      }

      if(atrMaxMult < atrMinMult)
      {
         Print("ERROR: SetupValidator - AtrMaxMult debe ser mayor o igual que AtrMinMult.");

         return false;
      }


      m_minSLPoints = minSLPoints;

      m_maxSLPoints = maxSLPoints;

      m_maxSpreadPoints = maxSpreadPoints;

      m_atrMinMultiplier = atrMinMult;

      m_atrMaxMultiplier = atrMaxMult;


      m_buyValid = false;

      m_sellValid = false;

      m_buyReason = TP_SETUP_NO_INICIALIZADO;

      m_sellReason = TP_SETUP_NO_INICIALIZADO;

      m_initialized = true;


      Print("SetupValidator inicializado.");

      Print(
         "Min SL Points     : ",
         DoubleToString(
            m_minSLPoints,
            2)
      );

      Print(
         "Max SL Points     : ",
         DoubleToString(
            m_maxSLPoints,
            2)
      );

      Print(
         "Max Spread Points : ",
         DoubleToString(
            m_maxSpreadPoints,
            2)
      );

      Print(
         "ATR Min Mult      : ",
         DoubleToString(
            m_atrMinMultiplier,
            2)
      );

      Print(
         "ATR Max Mult      : ",
         DoubleToString(
            m_atrMaxMultiplier,
            2)
      );


      return true;
   }


   //==================================================
   // Evaluar setups BUY y SELL
   //==================================================

   bool Evaluate(
      bool buySLCalculado,
      double buySLPoints,
      bool sellSLCalculado,
      double sellSLPoints,
      double atrPoints,
      double spreadPoints,
      long stopsLevelPoints)
   {
      //--------------------------------------------------
      // Validez formal de las entradas compartidas
      // (solo para el valor de retorno; el orden fijo
      // de razones vive en ValidateDirection)
      //--------------------------------------------------

      bool inputsValidos =
         atrPoints > 0.0 &&
         spreadPoints >= 0.0 &&
         stopsLevelPoints >= 0;


      if(!m_initialized)
      {
         m_buyValid = false;

         m_sellValid = false;

         m_buyReason = TP_SETUP_NO_INICIALIZADO;

         m_sellReason = TP_SETUP_NO_INICIALIZADO;
      }
      else
      {
         m_buyReason =
            ValidateDirection(
               buySLCalculado,
               buySLPoints,
               atrPoints,
               spreadPoints,
               stopsLevelPoints);

         m_buyValid =
            (m_buyReason == TP_SETUP_OK);

         m_sellReason =
            ValidateDirection(
               sellSLCalculado,
               sellSLPoints,
               atrPoints,
               spreadPoints,
               stopsLevelPoints);

         m_sellValid =
            (m_sellReason == TP_SETUP_OK);
      }


      //--------------------------------------------------
      // Trazabilidad: un log por dirección
      //--------------------------------------------------

      LogVerdict(
         "BUY",
         m_buyValid,
         m_buyReason,
         buySLPoints,
         atrPoints,
         spreadPoints);

      LogVerdict(
         "SELL",
         m_sellValid,
         m_sellReason,
         sellSLPoints,
         atrPoints,
         spreadPoints);


      return m_initialized && inputsValidos;
   }


   //==================================================
   // Veredicto BUY
   //==================================================

   bool BuySetupValid() const
   {
      return m_buyValid;
   }


   //==================================================
   // Veredicto SELL
   //==================================================

   bool SellSetupValid() const
   {
      return m_sellValid;
   }


   //==================================================
   // Razón BUY
   //==================================================

   ENUM_TP_SETUP_VALIDATION BuyReason() const
   {
      return m_buyReason;
   }


   //==================================================
   // Razón SELL
   //==================================================

   ENUM_TP_SETUP_VALIDATION SellReason() const
   {
      return m_sellReason;
   }


   //==================================================
   // Nombre de la razón
   //==================================================

   string ReasonName(ENUM_TP_SETUP_VALIDATION reason) const
   {
      switch(reason)
      {
         case TP_SETUP_OK:
            return "OK";

         case TP_SETUP_NO_INICIALIZADO:
            return "NO INICIALIZADO";

         case TP_SETUP_SL_NO_CALCULADO:
            return "SL NO CALCULADO";

         case TP_SETUP_DATOS_INVALIDOS:
            return "DATOS INVALIDOS";

         case TP_SETUP_SL_MUY_CORTO:
            return "SL MUY CORTO";

         case TP_SETUP_SL_MUY_AMPLIO:
            return "SL MUY AMPLIO";

         case TP_SETUP_ATR_INCOHERENTE:
            return "ATR INCOHERENTE";

         case TP_SETUP_SPREAD_ALTO:
            return "SPREAD ALTO";

         case TP_SETUP_STOPS_LEVEL_INVALIDO:
            return "STOPS LEVEL INVALIDO";
      }

      return "DESCONOCIDO";
   }


   //==================================================
   // Shutdown
   //==================================================

   void Shutdown()
   {
      m_buyValid = false;

      m_sellValid = false;

      m_buyReason = TP_SETUP_NO_INICIALIZADO;

      m_sellReason = TP_SETUP_NO_INICIALIZADO;

      m_initialized = false;

      Print("SetupValidator detenido.");
   }


private:

   //==================================================
   // Validar una dirección
   //==================================================

   ENUM_TP_SETUP_VALIDATION ValidateDirection(
      bool slCalculado,
      double slPoints,
      double atrPoints,
      double spreadPoints,
      long stopsLevelPoints)
   {
      if(!slCalculado)
         return TP_SETUP_SL_NO_CALCULADO;


      //--------------------------------------------------
      // Datos inválidos (fail-safe, orden fijo tras SL)
      //--------------------------------------------------

      if(slPoints <= 0.0 ||
         atrPoints <= 0.0 ||
         spreadPoints < 0.0 ||
         stopsLevelPoints < 0)
         return TP_SETUP_DATOS_INVALIDOS;


      if(slPoints < m_minSLPoints)
         return TP_SETUP_SL_MUY_CORTO;

      if(slPoints > m_maxSLPoints)
         return TP_SETUP_SL_MUY_AMPLIO;


      //--------------------------------------------------
      // Banda de coherencia con el ATR
      //--------------------------------------------------

      double atrMinDistance =
         m_atrMinMultiplier * atrPoints;

      double atrMaxDistance =
         m_atrMaxMultiplier * atrPoints;


      if(slPoints < atrMinDistance ||
         slPoints > atrMaxDistance)
         return TP_SETUP_ATR_INCOHERENTE;


      //--------------------------------------------------
      // Coste de entrada acotado
      //--------------------------------------------------

      if(spreadPoints > m_maxSpreadPoints)
         return TP_SETUP_SPREAD_ALTO;


      //--------------------------------------------------
      // Mínimo del símbolo (broker)
      //--------------------------------------------------

      if(slPoints <= stopsLevelPoints)
         return TP_SETUP_STOPS_LEVEL_INVALIDO;


      return TP_SETUP_OK;
   }


   //==================================================
   // Log del veredicto de una dirección
   //==================================================

   void LogVerdict(
      string direccion,
      bool valido,
      ENUM_TP_SETUP_VALIDATION razon,
      double slPoints,
      double atrPoints,
      double spreadPoints)
   {
      string veredicto = "RECHAZADO";

      if(valido)
         veredicto = "ACEPTADO";


      Print(
         "SETUP VALIDATION ",
         direccion,
         " : ",
         veredicto,
         " [",
         ReasonName(razon),
         "] SL=",
         DoubleToString(
            slPoints,
            2),
         "pts ATR=",
         DoubleToString(
            atrPoints,
            2),
         "pts Spread=",
         DoubleToString(
            spreadPoints,
            2),
         "pts"
      );
   }
};

#endif
