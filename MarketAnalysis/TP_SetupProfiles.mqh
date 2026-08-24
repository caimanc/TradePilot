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
//| Valores v2 calibrados con datos reales de Demo XAUUSD:           |
//| caps ~p85-p90 de distancias estructurales coherentes con ATR.    |
//| M1: 24-ago (n=63, p50=1680, p90=3481).                           |
//| M5: 25-ago (n=131, p50=1153, p90=2057).                          |
//| M15/H1: extrapolados sin muestras propias aun.                   |
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
      perfil.minSLPoints = 300.0;
      perfil.maxSLPoints = 4000.0;

      return;
   }

   if(timeframe >= PERIOD_M15)
   {
      perfil.minSLPoints = 150.0;
      perfil.maxSLPoints = 2800.0;

      return;
   }

   if(timeframe >= PERIOD_M5)
   {
      perfil.minSLPoints = 100.0;
      perfil.maxSLPoints = 2000.0;

      return;
   }

   //--------------------------------------------------
   // M1 y menores
   //--------------------------------------------------

   perfil.minSLPoints = 50.0;
   perfil.maxSLPoints = 2500.0;
}

#endif
