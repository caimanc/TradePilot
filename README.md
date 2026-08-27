# TradePilot

Expert Advisor de MetaTrader 5 para trading sistemático, con capa de **scoring probabilístico**, **gestión de riesgo** y **telemetría** para aprendizaje basado en datos.

> Documentación de **conceptos del log**, **inputs** (qué significan, qué valores aceptan y qué rango manejar) y **hoja de ruta**. Léelo completo antes de configurar: **0.0 suele significar "modo automático"** o "desactivado", según el input.

---

## 0. Resumen en 30 segundos

- El bot abre posiciones **Buy/Sell** según señales (tendencia + sesgo de timeframe superior + setup estructural), opcionalmente filtradas por una **probabilidad mínima** (scoring).
- Gestiona el riesgo: **volumen** (manual o automático por riesgo), **SL estructural**, **MaxSL en USD**, **trailing de ganancia**, **TP dinámico** y **pérdida diaria máxima**.
- Registra **telemetría** de cada operación (para medir resultados y, en el futuro, aprender pesos dinámicamente).
- **Opera a todas horas**; la sesión solo pondera el scoring, no bloquea.

---

## 1. Conceptos del log (qué significa cada línea)

El bot escribe en la pestaña **"Expertos"** del terminal (y en `MQL5/Logs/YYYYMMDD.log`). Líneas clave:

### Señales y bloqueos

| Línea en el log | Significado |
|-----------------|-------------|
| `>>> BUY SIGNAL` / `>>> SELL SIGNAL` | Se detectó una señal de compra/venta lista para ejecutar. |
| `SEÑAL BUY BLOQUEADA [TENDENCIA LTF]` | Hay setup de compra válido pero la **tendencia local** no acompaña → no se opera. |
| `SEÑAL BUY BLOQUEADA [SESGO HTF]` | La tendencia local acompaña pero el **sesgo del timeframe superior** no → no se opera. |
| `SEÑAL SELL BLOQUEADA [...]` | Igual que arriba, en dirección de venta. |
| `ORDEN BLOQUEADA: SL estructural inválido` | Falta un Stop Loss estructural válido → la orden **no se envía** (fail-safe de seguridad). |
| `ORDEN BLOQUEADA: TP estructural inválido` | Falta un Take Profit estructural válido → la orden **no se envía**. |
| `Trade bloqueado por RiskManager` | Se llegó al límite de **pérdida diaria** o de **trades del día** → no se opera. |

### Gestión de la posición

| Línea en el log | Significado |
|-----------------|-------------|
| `TRAILING SL: movido a X (protege Y USD)` | Se subió el Stop Loss protegiendo ganancia (trailing). |
| `TRAILING TP: extendido a X` | Se amplió el Take Profit porque la tendencia continúa. |
| `MaxSL BUY: $A → $B (precio → precio)` | La pérdida en sl era mayor a `InpMaxSL`, se ajustó el SL al límite. `$A` era la pérdida estimada, `$B` el tope. |

### Capa de probabilidad (scoring)

| Línea en el log | Significado |
|-----------------|-------------|
| `PROB` / probabilidades en el panel | Probabilidad calculada de Buy y de Sell (%). Si el scoring está desactivado, se muestran como referencia informativa. |
| `Sesion : LONDON_NEWYORK (f 1.00)` | Sesión actual y **factor de ponderación** (0.00 a 1.00) aplicado al peso de sesión. |

### Telemetría (para medir resultados)

| Línea en el log | Significado |
|-----------------|-------------|
| `TP_TEL|ENTRADA|ticket=... dir=BUY precio=... sl=... tp=... vol=...` | Registro de la **apertura** de una operación con todos sus parámetros y marca de tiempo. |
| `TP_TEL|CIERRE|... profit=... neto=... motivo=SL/TP/manual` | Registro del **cierre** de una operación, con resultado. `motivo` indica por qué cerró (SL, TP, manual...). |
| `TP_TEL|RESULTADO|senal=... neto=... horas=...` | Resultado consolidado de la operación: resultado neto (profit+swap+comisión) y duración en horas. |

> **Medir el impacto de las noticias:** el terminal no expone el calendario económico al lenguaje MQL5 de forma confiable, así que el EA **no bloquea ni lee noticias automáticamente**. La forma de medir su impacto es **cruzar las marcas de tiempo de `TP_TEL|ENTRADA`** contra cualquier calendario externo (ForexFactory, investing.com, etc.): verás si las operaciones cerca de eventos de alto impacto tienden a fallar más.

---

## 2. Inputs: qué significan y qué valores manejar

> **Regla general:** un input en **0.0** casi siempre significa **"modo automático"** o **"desactivado"** según el caso (se indica en cada fila). Léelo antes de cambiarlo.

### 2.1 Volumen y riesgo

| Input | Default | Qué significa | Valores | Guía |
|-------|---------|---------------|---------|------|
| `InpVolumenManual` | `0.0` | Volumen en lotes. **0.0 = automático** (se calcula según riesgo). | `0.0` o `> 0` (por lotes) | `0.0` para automático; ejemplo manual: `0.01` (micro) |
| `InpMaxTrades` | `0` | Máximo de operaciones por día. **0 = ilimitado**. | `0` o número entero | `0` para sin límite; `5` si quieres máximo 5/día |
| `InpMaxPerdida` | `50.0` | **Pérdida diaria máxima en USD**. Cuando se alcanza, el bot deja de operar ese día. | `> 0` (USD) | Empieza conservador: `20`–`50` USD según tu cuenta |

### 2.2 Alerta

| Input | Default | Qué significa | Valores | Guía |
|-------|---------|---------------|---------|------|
| `InpAlertaSonido` | `true` | Reproduce sonido + alerta al ejecutar una orden. | `true` / `false` | `true` recomendado |

### 2.3 Trailing de ganancia (proteger ganancia)

> El trailing **solo mejora** el SL: nunca lo retrocede. El **TP solo se extiende**, nunca se reduce. Respeta los niveles de stop/freeze del broker.

| Input | Default | Qué significa | Valores | Guía |
|-------|---------|---------------|---------|------|
| `InpTrailMinProfit` | `0.0` | Ganancia mínima (USD) para **activar** el trailing. **0.0 = desactivado**. | `0.0` o `> 0` (USD) | `0.0` para desactivar; `10` para activar cuando haya $10 |
| `InpTrailBreakevenOffset` | `1.0` | Ganancia (USD) protegida como mínimo cuando el trailing se activa (traslada a breakeven + $1). | `> 0` (USD) | `1.0`–`5.0` |
| `InpTrailStep` | `5.0` | **Cada cuántos USD** se vuelve a evaluar y proteger más. | `> 0` (USD) | `5.0`–`20.0` |
| `InpTrailStepIncrease` | `5.0` | **Cuántos USD** se sube el SL en cada step. Con step=5 e increase=5, sube 5 cada 5. | `> 0` (USD) | Igual o mayor a step |
| `InpTrailTP` | `true` | Si `true`, extiende el **TP** cuando la tendencia continúa. | `true` / `false` | `true` para aprovechar tendencias |

### 2.4 Límite de Stop Loss por operación

| Input | Default | Qué significa | Valores | Guía |
|-------|---------|---------------|---------|------|
| `InpMaxSL` | `0.0` | **Máximo SL en USD** por operación. **0.0 = valor calculado** (el SL estructural, sin tope). Si la pérdida en USD del SL estructural supera este tope, se acerca el SL al límite. | `0.0` o `> 0` (USD) | `0.0` para respetar el SL estructural; `20` para tope de $20/operación |

### 2.5 Capa de probabilidad (scoring ponderado)

> El scoring es un **filtro adicional** opcional después de la señal clásica. **`InpScoreThreshold = 0.0` desactiva** el filtro y el bot se comporta como antes (booleano puro).

| Input | Default | Qué significa | Valores | Guía |
|-------|---------|---------------|---------|------|
| `InpScoreThreshold` | `0.0` | **Probabilidad mínima (%)** para emitir señal. **0.0 = desactivado** (no filtra). Es el "F7" del panel: si la probabilidad calculada está por debajo, no señala. | `0.0`, o `50`–`100` | **Empieza en `0.0`** (neutral). Para filtrar: `66`–`75` solo señales altamente alineadas |
| `InpW_Tendencia` | `1.0` | **Peso** de la tendencia local en el cálculo de probabilidad. | `0` o `> 0` (relativo) | `1.0` (neutro). Sube a `1.5` si quieres priorizar la tendencia local |
| `InpW_Htf` | `1.0` | **Peso** del sesgo del timeframe superior. | `0` o `> 0` (relativo) | `1.0` (neutro) |
| `InpW_Setup` | `1.0` | **Peso** del setup estructural. | `0` o `> 0` (relativo) | `1.0` (neutro) |
| `InpW_Sesion` | `0.0` | **Peso** de la ventana de sesión. `0.0` = **inactivo** (la sesión no puntúa). El feature de sesión aporta un **factor 0.00–1.00** según el momento: solape Londres+NY=1.0, inicio=0.8, media=0.5, cierre=0.3, fuera de ventanas=0.0. | `0.0`, o `> 0` (relativo) | **Empieza en `0.0`** (sin sesgo). Actívalo (`1.0`) cuando quieras que las horas de alta liquidez pesen más |

**Cómo funcionan los pesos juntos** (ejemplo con los tres activos):

```
Si tendencia+HTF+setup a favor:  P = (1+1+1)/(3)        = 100%
Si 2 de 3 a favor:              P = (1+1)/(3)          = 66.7%
Si 1 de 3 a favor:              P = (1)/(3)            = 33.3%
```

**IMPORTANTE — valores recomendados para empezar (sin sesgo):**

- `InpScoreThreshold = 0.0` (arranca **informativo**, no filtra)
- `InpW_Tendencia = 1.0`, `InpW_Htf = 1.0`, `InpW_Setup = 1.0` (equitativos, **sin sesgo** entre ellos)
- `InpW_Sesion = 0.0` (sesión inactiva)

> **Por qué estos valores:** los pesos `1.0/1.0/1.0` son **neutrales** entre features. No cambies los pesos hasta tener **datos reales etiquetados**. Con threshold en 0, el scoring es informativo y te deja **recolectar una base honesta e imparcial** para decidir después con datos, no con intuición.

---

## 3. Hoja de ruta de los pesos

- **Hoy:** pesos **estáticos** (los inputs de la sección 2.5) y threshold manual. Esto es el *andamiaje*.
- **Futuro (Fase 3.5b — pesos dinámicos / Naive Bayes):** cuando haya **~100+ operaciones etiquetadas** (que la telemetría `TP_TEL|*` ya registra), los pesos pasarán a **aprenderse de los datos**:
  - `P(feature | ganadora) = ganadoras_con_feature / ganadoras`
  - `P(feature | perdedora) = perdedoras_con_feature / perdedoras`
  - El peso de cada feature derivará de **cuánto discrimina** ganar/perder en tu data real.
  - Dos implementaciones posibles: **reentrenamiento manual** (un comando) o **auto-reentrenamiento con umbral** (cada N operaciones, con validación anti-sobreajuste).
  - El módulo `TP_ProbabilityScorer` se reutiliza tal cual; solo cambia quién define los pesos.

---

## 4. Configuración inicial recomendada (no-trader-friendly)

| Concepto | Recomendación |
|----------|---------------|
| Volumen | `InpVolumenManual = 0.0` (automático por riesgo) |
| Trades/día | `InpMaxTrades = 0` (ilimitado) o `5` si quieres conservador |
| Pérdida diaria | `InpMaxPerdida = 50.0` USD (ajusta según tu cuenta) |
| Trailing | `InpTrailMinProfit = 10.0`, step `5.0`, increase `5.0`, TP `true` |
| MaxSL | `InpMaxSL = 20.0` USD (tope por operación) |
| Scoring | Threshold `0.0`, pesos `1.0/1.0/1.0/0.0` (neutral / informativo) |

> Ajusta `InpMaxPerdida` y `InpMaxSL` al tamaño de tu cuenta. **Empieza con la cuenta demo** y deja que la telemetría acumule datos.

---

## 5. Seguridad (fail-safes)

- **Sin SL estructural válido → no se envía la orden** (nunca opera sin protección).
- **Sin TP estructural válido → no se envía la orden**.
- El trailing **nunca** mueve el SL hacia atrás; el TP **nunca** se reduce.
- Se respetan los **niveles de stop/freeze** del broker.
- **Protección multi-instancia:** si dos instancias del EA corren en el mismo símbolo con el mismo `Magic Number`, una se bloquea automáticamente (evita duplicar señales y distorsionar pérdida diaria).

---

## 6. Notas de la versión

- **v1.00**: scooping probabilístico ponderado, sesión variable, telemetría por operación, contadores de evaluación, MaxSL en USD, trailing SL/TP, protección multi-instancia.
