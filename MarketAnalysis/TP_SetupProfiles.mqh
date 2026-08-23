#ifndef __TP_SETUPPROFILES_MQH__
#define __TP_SETUPPROFILES_MQH__

//+------------------------------------------------------------------+
//| Perfiles de umbrales del SetupValidator por temporalidad         |
//|                                                                  |
//| Los límites de SL en PUNTOS escalan con la temporalidad del      |
//| gráfico. El spread máximo y los múltiplos ATR son invariantes    |
//| (spread vivo idéntico en todo TF; múltiplos son ratios):         |
//| NO viven en este módulo.                                         |
//|                                                                  |
//| Valores v1 ESTIMADOS (base M1 = defaults históricos del EA);     |
//| calibrar con datos reales de Demo por temporalidad.              |
//+------------------------------------------------------------------+
struct TPSetupProfile
{
   double minSLPoints;
   double maxSLPoints;
};

//+------------------------------------------------------------------+
//| Perfil de umbrales para una temporalidad                         |
//|                                                                  |
//| TF no listado usa el perfil del TF listado inferior más          |
//| cercano; por debajo de M1 rige M1 (criterio conservador).        |
//+------------------------------------------------------------------+
void ObtenerPerfil(
   ENUM_TIMEFRAMES timeframe,
   TPSetupProfile &perfil)
{
   if(timeframe >= PERIOD_H1)
   {
      perfil.minSLPoints = 250.0;
      perfil.maxSLPoints = 2400.0;

      return;
   }

   if(timeframe >= PERIOD_M15)
   {
      perfil.minSLPoints = 120.0;
      perfil.maxSLPoints = 1600.0;

      return;
   }

   if(timeframe >= PERIOD_M5)
   {
      perfil.minSLPoints = 75.0;
      perfil.maxSLPoints = 1000.0;

      return;
   }

   //--------------------------------------------------
   // M1 y menores: defaults históricos del EA
   //--------------------------------------------------

   perfil.minSLPoints = 30.0;
   perfil.maxSLPoints = 400.0;
}

#endif
