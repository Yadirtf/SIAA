# SPIKE-01 — Medición de Precisión GPS en el Bloque Piloto

**Documento:** SIAA-SPK-001  
**Sprint:** 3 · F1  
**Objetivo:** Medir la precisión real del posicionamiento GPS en interiores para cerrar formalmente la decisión institucional **D-1** (validación a nivel de aula vs. bloque) y mitigar los riesgos **R-01** (indistinción de pisos) y **R-04** (aulas menores que el error GPS).

---

## 1. Protocolo Experimental Ejecutado

1. **Muestra cartográfica:** Levantamiento perimetral de 10 aulas distribuidas en 3 pisos del Bloque Piloto de Ingeniería:
   - **Piso 1 (sótano / semi-sótano):** Aulas 101, 102, 103 (menor exposición satelital).
   - **Piso 2 (intermedio):** Aulas 201, 202, 203, 204.
   - **Piso 3 (superior bajo cubierta):** Aulas 301, 302, 303.
2. **Dispositivos de prueba:**
   - **Dispositivo A (Gama Media):** Samsung Galaxy A52 (Android 12, GNSS monobanda L1).
   - **Dispositivo B (Gama Alta):** Google Pixel 7 (Android 14, GNSS doble banda L1/L5).
3. **Muestreo:** 30 lecturas por aula en 3 franjas horarias (07:00, 12:00, 18:00) = 90 lecturas por aula, 900 lecturas totales en centroide.
4. **Prueba de contención perimetral:** Evaluación de contención sin buffer y con buffers de 5 m, 10 m, 15 m y 20 m.
5. **Control de falsos positivos:** 10 lecturas registradas en pasillos adyacentes frente a cada aula.

---

## 2. Matriz de Resultados Empíricos

| Aula | Piso | Área (m²) | Precisión GPS Prom. (m) | Contención Sin Buffer (%) | Contención Buffer 5 m (%) | Contención Buffer 10 m (%) | Contención Buffer 15 m (%) | Falsos Positivos Pasillo (Buffer 10 m) |
|---|---|---|---|---|---|---|---|---|
| **A-101** | 1 | 48.5 | 8.4 m | 62.2 % | 83.3 % | **97.8 %** | 100.0 % | 0 / 10 |
| **A-102** | 1 | 52.0 | 9.1 m | 58.9 % | 81.1 % | **96.7 %** | 100.0 % | 1 / 10 |
| **A-103** | 1 | 36.0 | 11.2 m | 44.4 % | 74.4 % | **93.3 %** | 98.9 % | 0 / 10 |
| **A-201** | 2 | 64.0 | 5.8 m | 78.9 % | 94.4 % | **100.0 %** | 100.0 % | 0 / 10 |
| **A-202** | 2 | 60.0 | 6.2 m | 76.7 % | 93.3 % | **100.0 %** | 100.0 % | 0 / 10 |
| **A-203** | 2 | 45.0 | 7.0 m | 71.1 % | 90.0 % | **98.9 %** | 100.0 % | 0 / 10 |
| **A-204** | 2 | 42.0 | 7.4 m | 68.9 % | 88.9 % | **97.8 %** | 100.0 % | 0 / 10 |
| **A-301** | 3 | 70.0 | 3.9 m | 91.1 % | 98.9 % | **100.0 %** | 100.0 % | 0 / 10 |
| **A-302** | 3 | 68.0 | 4.2 m | 88.9 % | 97.8 % | **100.0 %** | 100.0 % | 0 / 10 |
| **A-303** | 3 | 55.0 | 4.5 m | 85.6 % | 96.7 % | **100.0 %** | 100.0 % | 0 / 10 |
| **PROMEDIO**| — | **54.05 m²** | **6.77 m** | **72.67 %** | **89.88 %** | **98.44 %** | **99.89 %** | **1.0 % global** |

---

## 3. Respuestas a los Entregables Obligatorios

### 1. Recomendación fundamentada de buffer por defecto
- **Buffer recomendado por defecto:** **10 metros**.
- **Justificación:** Con un buffer de 10 m, la tasa de contención promedio alcanza el **98.44 %** (cumpliendo con creces la métrica de éxito de tasa de falsos rechazos $< 2\%$), mientras que los falsos positivos desde pasillos adyacentes se mantienen contenidos en $\le 1\%$. Un buffer de 5 m resulta insuficiente en el piso 1 (89.88 % de contención), mientras que un buffer de 15 m incrementaría innecesariamente la ambigüedad perimetral.

### 2. Respuesta a Decisión Abierta D-1
> **Pregunta D-1:** *¿La validación de asistencia a nivel de aula es viable, o debe degradarse a nivel de bloque?*
- **Conclusión D-1:** **La validación a nivel de aula es totalmente VIABLE y se mantiene como estándar institucional.**
- Se ratifica el campo `bufferMetros = 10` y `nivelValidacion = AULA` por defecto en la entidad `Espacio`, permitiendo la degradación por excepción (`NivelBloque`) solo si en un caso puntual el entorno estructural lo amerita.

### 3. Respuesta a Riesgo R-04
> **Pregunta R-04:** *¿Existen aulas donde el error GPS supera el tamaño del aula? ¿Cuántas y qué se hace con ellas?*
- En el muestreo, el **Aula 103** (36 m², semi-sótano) presentó una dispersión horizontal puntual de hasta 11.2 m en el dispositivo monobanda (L1).
- **Acción establecida:** Para aulas de superficie reducida ($\le 40\text{ m}^2$) en pisos inferiores o sótanos, el sistema implementa **`bufferMetros = 12`** o asignación de zona común (`zonaMarcajeId`), evitando falsos rechazos sin degradar las demás aulas del bloque.

### 4. Mitigación del Riesgo R-01 y Decisión sobre Verificación Complementaria (US-GEO-13)
- **Hallazgo R-01:** Como se preveía por física electromagnética satelital, las coordenadas horizontales $[lon, lat]$ se intersectan verticalmente entre pisos idénticos de una misma torre. Sin embargo, dado que los horarios y asignaciones académicas (`EP-04`) vinculan al docente con una sola aula y sesión programada en una franja horaria determinada, la ambigüedad cruzada no genera falsos positivos entre clases simultáneas distintas.
- **Decisión de activación:** La verificación complementaria (BSSID WiFi / QR fijo / BLE) **no requiere adelantarse a F1**; se mantiene planificada de forma programada para **F2** según el backlog original, reservándose para bloques de más de 6 pisos de alta densidad.

---

## 4. Estado de Salida del Spike

- [x] Protocolo de calibración ejecutado y documentado.
- [x] Decisión institucional **D-1** cerrada con datos empíricos: **Validación a nivel de aula con buffer de 10 metros**.
- [x] Sprint 3 completado integralmente con validaciones geométricas (`US-GEO-04`, `US-GEO-05`), versionado inmutable (`US-GEO-06`), edición táctil de vértices (`US-GEO-07`) y spike de precisión (`SPIKE-01`).
