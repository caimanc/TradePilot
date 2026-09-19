#ifndef __TP_VOLUMEPROFILE_MQH__
#define __TP_VOLUMEPROFILE_MQH__

#include "../Market/TP_PriceSeries.mqh"

//+------------------------------------------------------------------+
//| Perfil de volumen por precio                                     |
//|                                                                  |
//| Histograma de volumen acumulado por nivel de precio sobre las    |
//| ultimas N velas cerradas. Barras de precio de tamano             |
//| tick_size x 10. POC = nivel con mas volumen (fair value).        |
//| HVN = zonas de alto volumen (paredes), LVN = valles de liquidez. |
//| Se usa para que el SL evite dejar el stop pegado a una pared.    |
//+------------------------------------------------------------------+
class CTPVolumeProfile
{
private:

   double m_bins[];
   int    m_capacidad;
   double m_precioBase;
   double m_tamanoBin;
   int    m_pocIndex;

   //--------------------------------------------------
   // Tamano de barra de precio
   //--------------------------------------------------

   double TamanoBin() const
   {
      double tickSize =
         SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

      if(tickSize <= 0.0)
         tickSize = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

      return MathMax(
         tickSize * 10.0,
         SymbolInfoDouble(_Symbol, SYMBOL_POINT));
   }

   //--------------------------------------------------
   // Precio central de un bin
   //--------------------------------------------------

   double PrecioBin(int idx) const
   {
      return m_precioBase + (idx + 0.5) * m_tamanoBin;
   }

   //--------------------------------------------------
   // Indice del bin que contiene un precio
   //--------------------------------------------------

   int Indice(double precio) const
   {
      if(m_tamanoBin <= 0.0)
         return -1;

      int idx =
         (int)MathFloor(
            (precio - m_precioBase) / m_tamanoBin);

      if(idx < 0 || idx >= m_capacidad)
         return -1;

      return idx;
   }

public:

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

   CTPVolumeProfile()
   {
      m_capacidad  = 0;
      m_precioBase = 0.0;
      m_tamanoBin  = 0.0;
      m_pocIndex   = -1;
   }

   //--------------------------------------------------
   // Actualizar perfil sobre las ultimas N velas
   //--------------------------------------------------

   void Update(const CTPPriceSeries &prices, int bins)
   {
      m_pocIndex = -1;

      if(bins < 1)
         return;

      int bars = prices.Bars();

      if(bars < bins + 1)
         return;

      m_tamanoBin = TamanoBin();

      if(m_tamanoBin <= 0.0)
         return;

      //--------------------------------------------------
      // Rango de la ventana para dimensionar los bins
      //--------------------------------------------------

      double minP = DBL_MAX;
      double maxP = 0.0;

      for(int i=1; i<=bins; i++)
      {
         if(prices.Low(i)  < minP)
            minP = prices.Low(i);

         if(prices.High(i) > maxP)
            maxP = prices.High(i);
      }

      if(minP >= maxP)
         return;

      m_precioBase = minP;

      m_capacidad =
         (int)MathFloor(
            (maxP - minP) / m_tamanoBin) + 2;

      ArrayResize(m_bins, m_capacidad);

      ArrayInitialize(m_bins, 0.0);

      //--------------------------------------------------
      // Acumular volumen en los niveles que atraviesa cada vela
      //--------------------------------------------------

      for(int i=1; i<=bins; i++)
      {
         double vol = (double)prices.TickVolume(i);

         if(vol <= 0.0)
            continue;

         int idxLow  = Indice(prices.Low(i));
         int idxHigh = Indice(prices.High(i));

         if(idxLow < 0)
            idxLow = 0;

         if(idxHigh < 0 || idxHigh >= m_capacidad)
            idxHigh = m_capacidad - 1;

         int tramos = (idxHigh - idxLow) + 1;

         if(tramos < 1)
            tramos = 1;

         double porBin = vol / (double)tramos;

         for(int b=idxLow; b<=idxHigh; b++)
            m_bins[b] += porBin;
      }

      //--------------------------------------------------
      // POC: bin con mas volumen acumulado
      //--------------------------------------------------

      double maxVol = 0.0;

      for(int b=0; b<m_capacidad; b++)
      {
         if(m_bins[b] > maxVol)
         {
            maxVol    = m_bins[b];
            m_pocIndex = b;
         }
      }
   }

   //--------------------------------------------------
   // POC: precio con mas volumen
   //--------------------------------------------------

   double POC() const
   {
      if(m_pocIndex < 0)
         return 0.0;

      return PrecioBin(m_pocIndex);
   }

   //--------------------------------------------------
   // Volumen acumulado en el nivel de un precio
   //--------------------------------------------------

   double VolumenEn(double precio) const
   {
      int idx = Indice(precio);

      if(idx < 0)
         return 0.0;

      return m_bins[idx];
   }

   //--------------------------------------------------
   // Volumen maximo del perfil
   //--------------------------------------------------

   double VolumenMax() const
   {
      if(m_pocIndex < 0)
         return 0.0;

      return m_bins[m_pocIndex];
   }

   //--------------------------------------------------
   // HVN: el precio esta en zona de alto volumen
   //--------------------------------------------------

   bool EsHVN(double precio) const
   {
      double maxVol = VolumenMax();

      if(maxVol <= 0.0)
         return false;

      int idx = Indice(precio);

      if(idx < 0)
         return false;

      if(m_bins[idx] >= maxVol * 0.6)
         return true;

      if(idx-1 >= 0 && m_bins[idx-1] >= maxVol * 0.75)
         return true;

      if(idx+1 < m_capacidad && m_bins[idx+1] >= maxVol * 0.75)
         return true;

      return false;
   }

   //--------------------------------------------------
   // LVN: el precio esta en un valle de liquidez
   //--------------------------------------------------

   bool EsLVN(double precio) const
   {
      double maxVol = VolumenMax();

      if(maxVol <= 0.0)
         return false;

      int idx = Indice(precio);

      if(idx < 0)
         return false;

      return m_bins[idx] <= maxVol * 0.15;
   }
};

#endif