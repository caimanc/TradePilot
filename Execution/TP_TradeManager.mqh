#ifndef __TP_TRADEMANAGER_MQH__
#define __TP_TRADEMANAGER_MQH__

#include "TP_Execution.mqh"
#include "../Signals/TP_SignalManager.mqh"

//+------------------------------------------------------------------+
//| Gestor de operaciones                                            |
//+------------------------------------------------------------------+
class CTPTradeManager
{
private:

   CTPExecution m_execution;

   double m_volume;

public:

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

   CTPTradeManager()
   {
      m_volume = 0.01;
   }

   //--------------------------------------------------
   // Inicializar
   //--------------------------------------------------

   bool Initialize(long magicNumber)
   {
      m_execution.SetMagicNumber(magicNumber);

      Print("TradeManager inicializado.");

      return true;
   }

   //--------------------------------------------------
   // Configuración
   //--------------------------------------------------

   void SetVolume(double volume)
   {
      m_volume = volume;
   }

   //--------------------------------------------------
   // Ejecutar señales
   //--------------------------------------------------

   bool Update(const CTPSignalManager &signals)
   {
      //--------------------------------------------------
      // Ya existe una posición
      //--------------------------------------------------

      if(PositionSelect(_Symbol))
         return true;

      //--------------------------------------------------
      // BUY
      //--------------------------------------------------

      if(signals.Buy())
      {
         Print(">>> BUY SIGNAL");

         return m_execution.Buy(
            m_volume,
            0.0,
            0.0);
      }

      //--------------------------------------------------
      // SELL
      //--------------------------------------------------

      if(signals.Sell())
      {
         Print(">>> SELL SIGNAL");

         return m_execution.Sell(
            m_volume,
            0.0,
            0.0);
      }

      return true;
   }

};

#endif