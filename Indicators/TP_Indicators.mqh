//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#ifndef __TP_INDICATORS_MQH__
#define __TP_INDICATORS_MQH__

#include "../Market/TP_Market.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CTPIndicators
  {
private:

   //--------------------------------------------------
   // Dependencias
   //--------------------------------------------------

   CTPMarket         *m_market;

   //--------------------------------------------------
   // Handles
   //--------------------------------------------------

   int               m_handleEMA20;
   int               m_handleEMA50;

   int               m_handleATR14;

   int               m_handleADX14;

public:

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

                     CTPIndicators()
     {
      m_market = NULL;

      m_handleEMA20 = INVALID_HANDLE;
      m_handleEMA50 = INVALID_HANDLE;

      m_handleATR14 = INVALID_HANDLE;

      m_handleADX14 = INVALID_HANDLE;
     }

   //--------------------------------------------------
   // Inicialización
   //--------------------------------------------------

   bool              Initialize(CTPMarket &market)
     {
      Print("--------------------------------------");
      Print("Inicializando módulo Indicators...");
      Print("--------------------------------------");

      m_market = &market;

      string symbol = m_market.Symbol();
      ENUM_TIMEFRAMES tf = m_market.Timeframe();

      //------------------------------------------
      // EMA 20
      //------------------------------------------

      m_handleEMA20 =
         iMA(symbol,
             tf,
             20,
             0,
             MODE_EMA,
             PRICE_CLOSE);

      //------------------------------------------
      // EMA 50
      //------------------------------------------

      m_handleEMA50 =
         iMA(symbol,
             tf,
             50,
             0,
             MODE_EMA,
             PRICE_CLOSE);

      //------------------------------------------
      // ATR
      //------------------------------------------

      m_handleATR14 =
         iATR(symbol,
              tf,
              14);

      //------------------------------------------
      // ADX
      //------------------------------------------

      m_handleADX14 =
         iADX(symbol,
              tf,
              14);

      if(m_handleEMA20==INVALID_HANDLE)
         return false;

      if(m_handleEMA50==INVALID_HANDLE)
         return false;

      if(m_handleATR14==INVALID_HANDLE)
         return false;

      if(m_handleADX14==INVALID_HANDLE)
         return false;

      Print("Indicators inicializado correctamente.");

      return true;
     }

   //--------------------------------------------------
   // Update
   //--------------------------------------------------

   void              Update()
     {

     }

   //--------------------------------------------------
   // Shutdown
   //--------------------------------------------------

   void              Shutdown()
     {
      if(m_handleEMA20!=INVALID_HANDLE)
         IndicatorRelease(m_handleEMA20);

      if(m_handleEMA50!=INVALID_HANDLE)
         IndicatorRelease(m_handleEMA50);

      if(m_handleATR14!=INVALID_HANDLE)
         IndicatorRelease(m_handleATR14);

      if(m_handleADX14!=INVALID_HANDLE)
         IndicatorRelease(m_handleADX14);

      Print("Indicators detenido.");
     }

  };

#endif
//+------------------------------------------------------------------+
