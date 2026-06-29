#property copyright "TradePilot"
#property version   "0.1.0"

#include "Core/TP_Core.mqh"

CTPCore Core;

//--------------------------------------------------
// Inicialización
//--------------------------------------------------

int OnInit()
{
   Print("===============================");
   Print("TradePilot v0.1.0");
   Print("===============================");

   if(!Core.Initialize())
      return(INIT_FAILED);

   Print("Expert Advisor iniciado.");

   return(INIT_SUCCEEDED);
}

//--------------------------------------------------
// Tick
//--------------------------------------------------

void OnTick()
{
   Core.Update();
}

//--------------------------------------------------
// Finalización
//--------------------------------------------------

void OnDeinit(const int reason)
{
   Core.Shutdown();

   Print("TradePilot finalizado.");
}