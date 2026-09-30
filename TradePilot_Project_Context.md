# TradePilot --- Especificación Técnica, Roadmap y Estado del Proyecto

## 1. Propósito del documento

Este documento sirve como **contexto técnico persistente para otra IA o
desarrollador** que deba continuar el proyecto TradePilot sin perder las
decisiones tomadas hasta el momento.

TradePilot es un **Expert Advisor (EA) para MetaTrader 5**, actualmente
orientado a XAUUSD como activo inicial, pero diseñado para no quedar
acoplado permanentemente al oro.

El objetivo no es construir un bot que opere únicamente por indicadores
ni uno que calcule el Stop Loss a partir del dinero disponible. El
proyecto busca construir progresivamente un **motor de análisis de
mercado basado en estructura de precio, volatilidad, señales técnicas,
gestión de riesgo y, posteriormente, un motor probabilístico de
decisión**.

> Estado actual: **fase de construcción y validación técnica en cuenta
> Demo**.\
> No considerar la lógica actual como lista para operar con dinero real.

------------------------------------------------------------------------

# 2. Objetivos del proyecto

## 2.1 Objetivo general

Construir un sistema modular para MT5 capaz de:

1.  Analizar el mercado.
2.  Detectar estructura de precio.
3.  Detectar swings relevantes.
4.  Identificar tendencia, rango, ruptura y retroceso.
5.  Calcular Stop Loss a partir del comportamiento del precio.
6.  Determinar si una operación tiene una relación riesgo/estructura
    razonable.
7.  Calcular posteriormente el volumen apropiado.
8.  Aplicar límites de riesgo.
9.  Generar señales.
10. Ejecutar operaciones únicamente cuando todas las validaciones
    necesarias sean satisfactorias.
11. Registrar las decisiones para poder auditar y mejorar el sistema.
12. Incorporar progresivamente un modelo probabilístico de predicción.
13. Mantener una arquitectura modular que permita cambiar componentes
    sin reescribir el sistema completo.

------------------------------------------------------------------------

# 3. Principios fundamentales

## 3.1 El mercado determina el Stop Loss

El Stop Loss **NO debe depender directamente del balance**.

Incorrecto:

``` text
Balance = $3000
10% del balance = $300
SL = distancia arbitraria equivalente a $300
```

Correcto:

``` text
Precio
   ↓
Swing / estructura
   ↓
Nivel estructural relevante
   ↓
Buffer de seguridad
   ↓
Stop Loss
```

El balance y el riesgo monetario se utilizarán posteriormente para
determinar el **volumen**, no para decidir directamente dónde está el
SL.

------------------------------------------------------------------------

## 3.2 El Stop Loss debe representar invalidación de la idea

Un SL debe colocarse en una zona donde la hipótesis de la operación deje
de ser válida.

Ejemplo conceptual:

### BUY

``` text
Entrada
   │
   │
   │
Swing Low
   │
Buffer
   │
SL
```

### SELL

``` text
SL
 │
Buffer
 │
Swing High
 │
 │
 │
Entrada
```

Nunca se debe reducir artificialmente un SL estructural solo para que
entre en un límite monetario.

Si la estructura exige un SL demasiado amplio para el perfil operativo,
la operación debe poder ser **descartada**.

------------------------------------------------------------------------

## 3.3 El riesgo determina el volumen

La secuencia correcta será:

``` text
Mercado
   ↓
Estructura
   ↓
SL
   ↓
¿SL razonable?
   ↓
Position Sizer
   ↓
Volumen
   ↓
Risk Manager
   ↓
Trade Manager
```

No:

``` text
Balance
   ↓
SL
```

------------------------------------------------------------------------

## 3.4 Primero reglas deterministas, después probabilidad

No se debe introducir Machine Learning antes de tener una base técnica
medible.

La evolución prevista es:

``` text
Reglas técnicas
      ↓
Backtesting
      ↓
Features
      ↓
Scoring probabilístico
      ↓
Validación estadística
      ↓
Modelo ML opcional
```

El sistema debe poder funcionar y ser evaluado incluso sin Machine
Learning.

------------------------------------------------------------------------

# 4. Arquitectura actual

La arquitectura es modular y está organizada por responsabilidades.

Estructura conceptual:

``` text
TradePilot/
│
├── Common/
│
├── Config/
│
├── Core/
│
├── Execution/
│
├── Indicators/
│
├── Logs/
│
├── Market/
│
├── MarketAnalysis/
│
├── MarketState/
│
├── Probability/
│
├── Presets/
│
├── Risk/
│
├── Signals/
│
└── ...
```

El Core coordina los módulos, pero no debe concentrar toda la lógica de
negocio.

------------------------------------------------------------------------

# 5. Módulos actuales

## 5.1 CTPConfig

Responsabilidad:

-   Símbolo.
-   Timeframe.
-   Magic Number.
-   Configuración general del EA.

Debe evitar que otras clases tengan configuraciones hardcodeadas
innecesariamente.

------------------------------------------------------------------------

## 5.2 CTPMarket

Responsabilidad:

-   Símbolo.
-   Timeframe.
-   Bid.
-   Ask.
-   Spread.
-   Detección de nueva vela.

Actualmente el sistema procesa el análisis principal **una vez por nueva
vela**.

Los logs completos aparecen nuevamente cuando cambia la vela porque el
modo actual está diseñado para diagnóstico.

Más adelante debe existir un modo:

``` text
DEBUG
```

y otro:

``` text
NORMAL
```

En DEBUG se muestran todos los datos.

En NORMAL solo eventos importantes.

------------------------------------------------------------------------

## 5.3 CTPPriceSeries

Responsabilidad:

-   Cargar datos históricos.
-   Exponer OHLC.
-   Número de barras.
-   Proporcionar información a los módulos de análisis.

Actualmente se utiliza como fuente para `CTPSwingDetector`.

------------------------------------------------------------------------

## 5.4 CTPIndicators

Indicadores actuales:

-   EMA20.
-   EMA50.
-   ADX.
-   +DI.
-   -DI.
-   ATR.

El sistema utiliza los indicadores como **confirmación/contexto**, no
como único motor de decisión.

------------------------------------------------------------------------

# 6. Market State

`CTPMarketState` resume información técnica en estados como:

``` text
Bull trend
Bear trend
```

Debe evolucionar para representar mejor:

``` text
TREND_BULLISH
TREND_BEARISH
RANGE
TRANSITION
UNKNOWN
```

El MarketState no debe confundirse con la estructura de precio.

------------------------------------------------------------------------

# 7. SwingDetector

Archivo:

``` text
MarketAnalysis/TP_SwingDetector.mqh
```

Clase:

``` text
CTPSwingDetector
```

Responsabilidad:

-   Detectar Swing High.
-   Detectar Swing Low.
-   Guardar shift del swing.
-   Trabajar sobre `CTPPriceSeries`.

Actualmente utiliza un `lookback`.

Conceptualmente:

``` text
Swing High:

        High
         ▲
        / \
       /   \
------/-----\------

Swing Low:

------\-----/------
       \   /
        \ /
         ▼
        Low
```

El SwingDetector no decide si comprar o vender.

Su responsabilidad es exclusivamente detectar puntos estructurales
relevantes.

------------------------------------------------------------------------

# 8. MarketStructure

Archivo:

``` text
MarketAnalysis/TP_MarketStructure.mqh
```

Debe interpretar los swings para determinar:

``` text
HH = Higher High
HL = Higher Low
LH = Lower High
LL = Lower Low
```

### Estructura alcista

``` text
HH
HL
HH
HL
```

### Estructura bajista

``` text
LH
LL
LH
LL
```

### Rango

Cuando no existe una estructura suficientemente clara.

------------------------------------------------------------------------

# 9. StructureAnalyzer

Archivo:

``` text
MarketAnalysis/TP_StructureAnalyzer.mqh
```

Estados actuales:

``` text
UNKNOWN
BULLISH
BEARISH
RANGE
BULLISH_BREAK
BEARISH_BREAK
```

También expone:

``` text
IsBullish()
IsBearish()
IsBreakout()
IsBreakdown()
IsRange()
IsRetracement()
```

El objetivo es separar:

``` text
detección de estructura
```

de:

``` text
interpretación de estructura
```

------------------------------------------------------------------------

# 10. StopLossCalculator

Responsabilidad:

Calcular el Stop Loss basándose principalmente en estructura y
volatilidad.

El concepto actual es:

``` text
BUY:

SL = SwingLow - Buffer

SELL:

SL = SwingHigh + Buffer
```

El buffer puede considerar volatilidad/ATR.

El módulo debe poder producir:

``` text
SL
distancia
distancia en puntos
validación
```

## Reglas

Un BUY es inválido si:

``` text
SL >= Entry
```

Un SELL es inválido si:

``` text
SL <= Entry
```

El módulo no debe utilizar directamente:

-   balance
-   equity
-   dinero disponible

para decidir el nivel estructural.

------------------------------------------------------------------------

# 11. Próximo componente: Setup Validator

Antes de conectar completamente la ejecución, se debe introducir una
validación del setup.

Objetivo:

``` text
SL estructural
      ↓
¿Distancia razonable?
      ↓
SI → continuar
NO → descartar operación
```

Debe evaluar, como mínimo:

-   Distancia del SL.
-   ATR.
-   Timeframe.
-   Tipo de operación.
-   Contexto estructural.
-   Spread.
-   Posible objetivo.
-   Relación riesgo/beneficio.

Ejemplo:

``` text
SL = 385 puntos

Perfil:
M1 Scalping

Resultado:
SETUP RECHAZADO
```

No porque el SL esté mal calculado, sino porque puede ser demasiado
amplio para ese perfil.

------------------------------------------------------------------------

# 12. PositionSizer

Responsabilidad futura:

Determinar el volumen a partir de:

``` text
Riesgo monetario permitido
+
Distancia del SL
+
Valor del tick
+
Tamaño del tick
+
Especificaciones del símbolo
=
Volumen
```

El PositionSizer **NO debe mover el SL**.

Ejemplo conceptual:

``` text
SL estructural = 100 puntos

Risk Manager:
riesgo máximo = X

PositionSizer:
calcula volumen compatible con esos 100 puntos
```

Si el SL es demasiado grande:

``` text
Setup Validator → rechaza
```

No:

``` text
PositionSizer → mueve el SL
```

------------------------------------------------------------------------

# 13. RiskManager

Responsabilidad actual:

-   Volumen por defecto.
-   Pérdida diaria máxima.
-   Conteo de operaciones.
-   Máximo de operaciones.

La versión actual es una base inicial y debe evolucionar.

Debe controlar como mínimo:

``` text
Daily Loss Limit
Maximum Trades
Maximum Risk per Trade
Maximum Exposure
```

También debe impedir que una nueva operación viole las reglas de riesgo.

------------------------------------------------------------------------

# 14. TradeManager

Responsabilidad:

-   Recibir señales.
-   Consultar validaciones.
-   Coordinar ejecución.

Actualmente trabaja con:

``` text
CTPExecution
```

y evita abrir una nueva posición cuando ya existe una posición sobre el
símbolo.

El objetivo futuro es que TradeManager **no tome decisiones de análisis
de mercado**.

Debe recibir una decisión ya validada.

------------------------------------------------------------------------

# 15. Execution

Responsabilidad:

-   BUY.
-   SELL.
-   SL.
-   TP.
-   Magic Number.
-   Ejecución de órdenes.

La ejecución debe estar separada del análisis.

------------------------------------------------------------------------

# 16. Flujo completo objetivo

El flujo final previsto:

``` text
                     ┌───────────────┐
                     │    MARKET     │
                     └───────┬───────┘
                             │
                             ▼
                     ┌───────────────┐
                     │ PRICE SERIES  │
                     └───────┬───────┘
                             │
              ┌──────────────┴─────────────┐
              ▼                            ▼
       ┌─────────────┐              ┌─────────────┐
       │ INDICATORS  │              │ SWING        │
       └──────┬──────┘              │ DETECTOR     │
              │                     └──────┬──────┘
              │                            │
              │                            ▼
              │                     ┌─────────────┐
              │                     │ MARKET      │
              │                     │ STRUCTURE   │
              │                     └──────┬──────┘
              │                            │
              └────────────┬───────────────┘
                           ▼
                   ┌───────────────┐
                   │ MARKET STATE  │
                   └───────┬───────┘
                           │
                           ▼
                   ┌───────────────┐
                   │ SIGNAL ENGINE │
                   └───────┬───────┘
                           │
                           ▼
                   ┌───────────────┐
                   │ STOP LOSS     │
                   │ CALCULATOR    │
                   └───────┬───────┘
                           │
                           ▼
                   ┌───────────────┐
                   │ SETUP         │
                   │ VALIDATOR     │
                   └───────┬───────┘
                           │
                           ▼
                   ┌───────────────┐
                   │ POSITION      │
                   │ SIZER         │
                   └───────┬───────┘
                           │
                           ▼
                   ┌───────────────┐
                   │ RISK MANAGER  │
                   └───────┬───────┘
                           │
                           ▼
                   ┌───────────────┐
                   │ TRADE MANAGER │
                   └───────┬───────┘
                           │
                           ▼
                   ┌───────────────┐
                   │  EXECUTION    │
                   └───────────────┘
```

------------------------------------------------------------------------

# 17. Motor de señales

El SignalManager actualmente trabaja con MarketState.

Debe evolucionar para utilizar múltiples dimensiones:

``` text
Structure
Trend
Momentum
Volatility
Price Action
Spread
Session
```

Una señal no debe depender de un solo indicador.

Ejemplo conceptual:

``` text
BUY candidate si:

Structure = Bullish
AND
EMA20 > EMA50
AND
ADX suficientemente fuerte
AND
DI confirma dirección
AND
precio presenta condición de entrada
AND
SL estructural válido
AND
spread aceptable
AND
risk permitido
```

No significa que todos estos criterios tengan que ser obligatorios
permanentemente. Deben poder configurarse y probarse.

------------------------------------------------------------------------

# 18. Motor de predicción

## 18.1 Enfoque inicial

El proyecto debe comenzar con un **motor de scoring probabilístico**, no
con un modelo ML complejo.

Las variables pueden incluir:

``` text
Trend
Structure
EMA relationship
ADX
DI
ATR
Swing distance
Breakout
Retracement
Spread
Session
Momentum
Price action
```

Cada característica aporta evidencia a favor o en contra de una
operación.

Conceptualmente:

``` text
Features
   ↓
Normalización
   ↓
Scoring
   ↓
Probabilidad estimada
   ↓
Confidence
```

Ejemplo:

``` text
BUY probability = 0.72
SELL probability = 0.18
NEUTRAL          = 0.10
```

La operación no debe ejecutarse simplemente porque:

``` text
BUY > 50%
```

Debe existir un umbral configurable y otras validaciones.

------------------------------------------------------------------------

# 19. Probabilidad no significa certeza

El motor debe distinguir:

``` text
Probability
```

de:

``` text
Confidence
```

Ejemplo:

``` text
BUY probability = 65%
Confidence = baja
```

puede ser peor que:

``` text
BUY probability = 62%
Confidence = alta
```

si la segunda situación proviene de una estructura más consistente.

La definición exacta debe establecerse mediante backtesting y datos.

------------------------------------------------------------------------

# 20. Modelo estadístico inicial

El primer motor probabilístico puede implementarse mediante un modelo
interpretable.

Opciones aceptables para esta fase:

1.  Logistic Regression.
2.  Bayesian scoring.
3.  Weighted probabilistic scoring.
4.  Calibración de probabilidades sobre resultados históricos.

Prioridad:

``` text
Interpretabilidad
>
Complejidad
```

No introducir una red neuronal simplemente porque sea posible.

------------------------------------------------------------------------

# 21. Machine Learning futuro

Una vez exista suficiente historial etiquetado, se puede evaluar:

``` text
XGBoost
LightGBM
Random Forest
Logistic Regression
```

La opción inicial preferida para experimentar con ML tabular puede ser
**XGBoost**, pero únicamente después de construir un dataset confiable.

El modelo debe predecir algo concreto, por ejemplo:

``` text
P(TP antes que SL | features actuales)
```

o:

``` text
P(movimiento favorable >= X puntos dentro de N velas)
```

No utilizar una variable ambigua como:

``` text
"precio subirá"
```

porque no define horizonte ni criterio de éxito.

------------------------------------------------------------------------

# 22. Dataset para ML

Cada observación debe contener:

``` text
timestamp
symbol
timeframe

price
spread

EMA20
EMA50
ADX
PlusDI
MinusDI
ATR

swingHigh
swingLow

structure
HH
HL
LH
LL

breakout
breakdown
retracement

session

entryPrice
stopLoss
target

futureOutcome
```

La etiqueta debe definirse con precisión.

Ejemplo:

``` text
1 = TP alcanzado antes que SL
0 = SL alcanzado antes que TP
```

------------------------------------------------------------------------

# 23. Prevención de data leakage

El modelo nunca debe recibir información que no estaba disponible en el
momento de la decisión.

Prohibido:

``` text
usar High/Low futuros
usar indicadores calculados con velas futuras
mezclar entrenamiento y test aleatoriamente cuando rompe el orden temporal
```

Debe utilizarse separación temporal:

``` text
TRAIN
   ↓
VALIDATION
   ↓
TEST
```

y preferiblemente walk-forward validation.

------------------------------------------------------------------------

# 24. Backtesting

Antes de usar cualquier modelo predictivo:

1.  Definir reglas.
2.  Crear dataset.
3.  Ejecutar backtest.
4.  Medir resultados.
5.  Analizar drawdown.
6.  Analizar distribución de ganancias/pérdidas.
7.  Analizar operaciones por sesión.
8.  Analizar operaciones por timeframe.
9.  Evaluar SL.
10. Evaluar TP.
11. Evaluar spread.
12. Evaluar estabilidad.

Métricas mínimas:

``` text
Win Rate
Profit Factor
Expectancy
Maximum Drawdown
Average Win
Average Loss
Number of Trades
Risk/Reward
Consecutive Losses
```

------------------------------------------------------------------------

# 25. Expectancy

La métrica central no debe ser únicamente Win Rate.

Debe analizarse:

``` text
Expectancy =
(P(win) × AvgWin)
-
(P(loss) × AvgLoss)
```

Un sistema con 70% de operaciones ganadoras puede ser malo si las
pérdidas son demasiado grandes.

Un sistema con 45% de aciertos puede ser rentable si sus ganancias
promedio compensan las pérdidas.

------------------------------------------------------------------------

# 26. TP y gestión de posición

El Take Profit también debe evolucionar hacia una lógica basada en
mercado.

Posibles referencias:

``` text
Swing
Structure
ATR
Liquidity/levels
Risk/Reward
Volatility
```

No utilizar únicamente:

``` text
TP = X dólares
```

El objetivo es que tanto SL como TP representen el comportamiento del
mercado.

------------------------------------------------------------------------

# 27. Gestión dinámica futura

Después de tener una ejecución estable:

-   Break-even.
-   Trailing Stop.
-   Partial Close.
-   Dynamic TP.
-   Dynamic SL.
-   Exit on structure reversal.
-   Exit on invalidation.

Regla importante:

Si el sistema detecta un cambio estructural fuerte contrario a la
operación, debe poder cerrar o detener la gestión según el modo
operativo configurado.

------------------------------------------------------------------------

# 28. Timeframes

El sistema debe ser configurable.

Perfiles previstos:

## Scalping

Principalmente:

``` text
M1
M5
```

## Intradía

Principalmente:

``` text
M15
M30
```

No asumir que un mismo SL o parámetro funciona igual en todos los
timeframes.

Los parámetros deben configurarse por perfil.

------------------------------------------------------------------------

# 29. Multi-timeframe futuro

Una evolución importante será:

``` text
Higher Timeframe
        ↓
Contexto
        ↓
Lower Timeframe
        ↓
Entrada
```

Ejemplo conceptual:

``` text
M30 → tendencia/contexto
M15 → estructura
M1/M5 → entrada
```

El timeframe superior no debe ejecutar operaciones; debe proporcionar
contexto.

------------------------------------------------------------------------

# 30. Sesiones de mercado

Futuro soporte para:

``` text
Asia
London
New York
```

El sistema podrá considerar:

-   apertura de sesión
-   volatilidad inicial
-   spread
-   comportamiento posterior a apertura
-   ventanas de operación

También puede existir una regla de espera después de la apertura para
evitar operar durante movimientos iniciales excesivamente erráticos.

------------------------------------------------------------------------

# 31. Modos operativos

El proyecto contempla tres modos principales.

## Assistant

El sistema:

``` text
Analiza
↓
Predice
↓
Propone
```

pero no ejecuta automáticamente.

## Management

El sistema:

``` text
Analiza
↓
Propone
↓
Calcula SL/TP/volumen
↓
Usuario decide
```

## Automatic

El sistema:

``` text
Analiza
↓
Valida
↓
Gestiona riesgo
↓
Ejecuta
↓
Gestiona posición
```

La automatización completa debe llegar después de validar correctamente
las fases anteriores.

------------------------------------------------------------------------

# 32. Risk Manager vs Position Sizer

No mezclar responsabilidades.

## RiskManager

Decide:

``` text
¿Podemos operar?
```

Controla:

-   pérdida máxima
-   máximo de operaciones
-   exposición
-   límites diarios
-   restricciones operativas

## PositionSizer

Decide:

``` text
¿Cuánto volumen podemos usar?
```

A partir de:

``` text
SL
Risk
Symbol specifications
Tick value
Tick size
Volume limits
```

------------------------------------------------------------------------

# 33. Reglas de seguridad técnica

El EA debe validar:

-   símbolo disponible.
-   datos suficientes.
-   spread.
-   volumen mínimo.
-   volumen máximo.
-   volumen step.
-   stops level del broker.
-   freeze level.
-   precio válido.
-   SL válido.
-   TP válido.
-   posición existente.
-   magic number.
-   resultado de la orden.

Nunca asumir que una orden fue ejecutada solo porque se llamó a la
función de trading.

------------------------------------------------------------------------

# 34. Arquitectura y SOLID

## Single Responsibility

Cada clase debe tener una responsabilidad principal.

Ejemplo:

``` text
SwingDetector → swings
MarketStructure → estructura
StopLossCalculator → SL
PositionSizer → volumen
RiskManager → riesgo
TradeManager → coordinación
Execution → broker
```

## Open/Closed

Agregar nuevos algoritmos no debería requerir modificar todo el Core.

## Dependency Inversion

El Core debe coordinar componentes, evitando concentrar reglas de
negocio en un único método gigante.

------------------------------------------------------------------------

# 35. Reglas de código MQL5

Mantener:

``` text
#ifndef
#define
#endif
```

en headers.

Usar includes relativos coherentes con la estructura.

Ejemplo:

``` cpp
#include "TP_SwingDetector.mqh"
```

cuando dos archivos están dentro de:

``` text
MarketAnalysis/
```

Evitar rutas absolutas.

Evitar referencias no soportadas por MQL5.

Evitar duplicar clases o nombres.

Compilar después de cada módulo significativo.

------------------------------------------------------------------------

# 36. Logs

Actualmente los logs detallados aparecen una vez por nueva vela.

Esto es **intencional durante la fase de diagnóstico**.

Ejemplo:

``` text
STOP LOSS ANALYSIS

BUY Entry
BUY SL
BUY Distance
BUY Points

SELL Entry
SELL SL
SELL Distance
SELL Points
```

Más adelante implementar:

``` text
DebugMode = true
```

para diagnóstico completo.

Y:

``` text
DebugMode = false
```

para logs resumidos.

------------------------------------------------------------------------

# 37. Estado actual del proyecto

## Completado/funcional

-   [x] Proyecto TradePilot creado.
-   [x] EA principal funcionando.
-   [x] Arquitectura modular.
-   [x] Config.
-   [x] Market.
-   [x] PriceSeries.
-   [x] Indicators.
-   [x] MarketState.
-   [x] SignalManager.
-   [x] Execution.
-   [x] TradeManager.
-   [x] RiskManager base.
-   [x] SwingDetector.
-   [x] MarketStructure.
-   [x] StructureAnalyzer.
-   [x] StopLossCalculator integrado al Core.
-   [x] Compilación del Core.
-   [x] Compilación del EA.
-   [x] Pruebas en cuenta Demo.
-   [x] Logs de estructura.
-   [x] Logs de SL.

------------------------------------------------------------------------

# 38. Evidencia actual

En pruebas recientes sobre XAUUSD se observó:

``` text
BUY Entry      : 4382.35000
BUY SL Valid   : false

SELL Entry     : 4382.14000
SELL SL Valid  : true
SELL SL        : 4385.99071
SELL Distance  : 3.85071
SELL Points    : 385.07
```

Interpretación:

El sistema ya es capaz de detectar que un SL puede ser válido para una
dirección y no válido para otra.

Importante:

``` text
385 puntos ≠ $385
```

En el contexto utilizado:

``` text
385 puntos ≈ 3.85 unidades de precio
```

El valor monetario depende del volumen y de las especificaciones del
símbolo.

------------------------------------------------------------------------

# 39. Próxima fase inmediata

## Fase actual: validación del Stop Loss

Objetivo:

Confirmar que:

``` text
Swing
+
ATR
+
Structure
```

producen SL razonables.

No conectar todavía la lógica definitiva de SL con la ejecución
automática.

------------------------------------------------------------------------

# 40. Próximo paso: Setup Validator

Crear un componente dedicado a:

``` text
CTPSetupValidator
```

Responsabilidades:

1.  Validar SL.
2.  Validar spread.
3.  Validar distancia máxima.
4.  Validar distancia mínima.
5.  Evaluar ATR.
6.  Evaluar contexto estructural.
7.  Evaluar riesgo/beneficio.
8.  Determinar:

``` text
VALID
INVALID
```

------------------------------------------------------------------------

# 41. Fases generales del proyecto

## Fase 1 --- Infraestructura

Estado:

``` text
COMPLETADA
```

Incluye:

-   EA.
-   Config.
-   Market.
-   PriceSeries.
-   Indicators.
-   Core.

------------------------------------------------------------------------

## Fase 2 --- Análisis técnico

Estado:

``` text
EN PROGRESO / MAYORMENTE COMPLETADA
```

Incluye:

-   EMA.
-   ATR.
-   ADX.
-   DI. 
-   SwingDetector.
-   MarketStructure.
-   StructureAnalyzer.

------------------------------------------------------------------------

## Fase 3 --- Gestión estructural del riesgo

Estado:

``` text
EN PROGRESO
```

Incluye:

-   StopLossCalculator.
-   SetupValidator.
-   PositionSizer.
-   RiskManager.

------------------------------------------------------------------------

## Fase 4 --- Señales

Objetivo:

Combinar:

``` text
Structure
+
Indicators
+
Price Action
+
Volatility
```

para producir señales de calidad.

------------------------------------------------------------------------

## Fase 5 --- Motor probabilístico

Objetivo:

Crear un score/probabilidad interpretable.

Ejemplo:

``` text
BUY: 0.71
SELL: 0.16
NEUTRAL: 0.13
```

Debe existir calibración sobre datos históricos.

------------------------------------------------------------------------

## Fase 6 --- Backtesting

Objetivo:

Evaluar:

-   señales
-   SL
-   TP
-   volumen
-   drawdown
-   expectancy
-   estabilidad

------------------------------------------------------------------------

## Fase 7 --- Dataset

Crear histórico estructurado de decisiones y resultados.

------------------------------------------------------------------------

## Fase 8 --- Machine Learning

Evaluar modelos tabulares:

``` text
Logistic Regression
XGBoost
LightGBM
Random Forest
```

Prioridad inicial:

``` text
Interpretabilidad + estabilidad + validación temporal
```

------------------------------------------------------------------------

## Fase 9 --- Gestión avanzada

Implementar:

-   Break-even.
-   Trailing.
-   Dynamic TP.
-   Dynamic SL.
-   Partial Close.
-   Exit on structure reversal.

------------------------------------------------------------------------

## Fase 10 --- Multi-timeframe

Incorporar:

``` text
HTF context
+
MTF structure
+
LTF entry
```

------------------------------------------------------------------------

## Fase 11 --- Automatización controlada

Solo después de validar:

``` text
Backtest
+
Demo
+
Risk controls
+
Execution
```

------------------------------------------------------------------------

# 42. Qué NO hacer

No:

-   Convertir el balance directamente en distancia de SL.
-   Mover el SL artificialmente para cumplir un límite monetario.
-   Ejecutar operaciones solo por EMA.
-   Ejecutar operaciones solo por ADX.
-   Ejecutar operaciones solo porque una probabilidad sea mayor al 50%.
-   Introducir ML antes de tener dataset.
-   Entrenar con información futura.
-   Mezclar test y entrenamiento temporalmente.
-   Meter toda la lógica dentro de `TP_Core.mqh`.
-   Hacer que `TradeManager` decida la estructura del mercado.
-   Hacer que `PositionSizer` decida el SL.
-   Hacer que `RiskManager` modifique la estructura.
-   Ejecutar operaciones reales durante la fase de desarrollo.

------------------------------------------------------------------------

# 43. Prioridad de implementación

Orden obligatorio recomendado:

``` text
1. StopLossCalculator
        ↓
2. SetupValidator
        ↓
3. PositionSizer
        ↓
4. RiskManager completo
        ↓
5. TradeManager con SL/TP/volume
        ↓
6. Validación en Demo
        ↓
7. Backtesting
        ↓
8. Motor probabilístico
        ↓
9. Dataset
        ↓
10. ML
        ↓
11. Gestión dinámica
        ↓
12. Multi-timeframe
        ↓
13. Automatización avanzada
```

No saltar directamente a Machine Learning.

------------------------------------------------------------------------

# 44. Criterio de aceptación de una operación

Una operación ideal debe pasar por:

``` text
Datos válidos
   ↓
Nueva vela
   ↓
Indicadores válidos
   ↓
Swing válido
   ↓
Estructura válida
   ↓
Señal válida
   ↓
SL estructural válido
   ↓
SL razonable
   ↓
TP razonable
   ↓
Risk/Reward válido
   ↓
Riesgo permitido
   ↓
Volumen válido
   ↓
Spread válido
   ↓
Execution válida
   ↓
TRADE
```

Si falla una validación crítica:

``` text
NO TRADE
```

------------------------------------------------------------------------

# 45. Filosofía general del sistema

TradePilot no debe intentar adivinar el mercado.

Debe:

``` text
OBSERVAR
   ↓
INTERPRETAR
   ↓
ESTIMAR
   ↓
VALIDAR
   ↓
DECIDIR
   ↓
GESTIONAR
```

La predicción es probabilística, no determinista.

El sistema debe aceptar que:

``` text
una señal puede fallar
```

y diseñar el riesgo para que una señal fallida no comprometa el sistema
completo.

------------------------------------------------------------------------

# 46. Instrucción para la IA que continúe el proyecto

Cualquier IA que continúe este proyecto debe respetar las siguientes
reglas:

1.  Leer primero este documento.
2.  No reemplazar la arquitectura existente sin justificación.
3.  Mantener las responsabilidades de cada módulo.
4.  No introducir código innecesario.
5.  Aplicar YAGNI.
6.  Mantener SOLID.
7.  Mantener separación de responsabilidades.
8.  Validar cada modificación compilando MQL5.
9.  Probar primero en Demo.
10. No introducir Machine Learning prematuramente.
11. Mantener el SL basado en estructura/mercado.
12. Usar PositionSizer para adaptar volumen al riesgo.
13. No adaptar artificialmente el SL al balance.
14. Mantener logs suficientes para auditar decisiones.
15. Evitar hardcodear parámetros que posteriormente deban ser
    configurables.
16. Mantener compatibilidad con diferentes símbolos y timeframes.
17. No asumir que XAUUSD será el único activo futuro.
18. No ejecutar operaciones reales durante la fase de desarrollo.
19. Cada nuevo componente debe tener una responsabilidad clara.
20. Antes de modificar un módulo existente, revisar sus dependencias y
    consumidores.

------------------------------------------------------------------------

# 47. Punto exacto de continuación

El proyecto se encuentra actualmente aquí:

``` text
Market
   ↓
PriceSeries
   ↓
Indicators
   ↓
SwingDetector
   ↓
MarketStructure
   ↓
StructureAnalyzer
   ↓
MarketState
   ↓
SignalManager
   ↓
StopLossCalculator
   ↓
[ SIGUIENTE: SetupValidator ]
   ↓
PositionSizer
   ↓
RiskManager
   ↓
TradeManager
   ↓
Execution
```

### Próxima tarea

Implementar:

``` text
CTPSetupValidator
```

sin modificar innecesariamente los módulos que ya compilan.

El objetivo inmediato no es abrir más operaciones.

El objetivo inmediato es responder correctamente:

> **¿Esta configuración de mercado tiene un Stop Loss estructural válido
> y razonable para el perfil operativo actual?**

Una vez que esa pregunta esté resuelta, continuar con `PositionSizer`.

------------------------------------------------------------------------

# 48. Estado de compilación

Al momento de redactar este documento:

``` text
TradePilot EA       → compila
TP_Core.mqh         → compila
SwingDetector       → compila
MarketStructure     → compila
StructureAnalyzer   → compila
StopLossCalculator  → integrado y probado
RiskManager         → base funcional
```

El proyecto está siendo probado en:

``` text
MetaTrader 5
Cuenta Demo
XAUUSD
```

y se ha observado correctamente la generación de logs de:

``` text
Market
Swings
Structure
Indicators
MarketState
Signals
Stop Loss
```

------------------------------------------------------------------------

# 49. Regla final

**No avanzar de fase solamente porque el código compile.**

Cada fase debe cumplir:

``` text
Compila
+
Ejecuta
+
Produce datos coherentes
+
Se puede explicar
+
Se puede probar
+
Se puede auditar
```

Solo entonces se considera terminada.
