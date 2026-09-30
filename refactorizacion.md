# SIAA — Parámetros y Protocolo de Refactorización Modular (`refactorizacion.md`)

> **Propósito:**  
> Este documento establece los parámetros formales, criterios métricos y buenas prácticas de desarrollo para refactorizar archivos monolíticos o sobredimensionados en el proyecto **SIAA (Sistema Integrado de Asistencia Académica)**, transformando código sobrecargado en una **arquitectura de rompecabezas** escalable y mantenible.

---

## 1. Justificación y Filosofía de Refactorización

En proyectos de software de misión crítica con múltiples capas (Backend Go, Web Flutter, Móvil Flutter), el crecimiento descontrolado de un archivo genera:
* **Efecto dominó:** Modificar un formulario o un botón en un archivo de +500 líneas puede romper la navegación, la inicialización de BLoC o el ciclo de vida del mapa.
* **Dificultad de lectura y mantenimiento:** Los desarrolladores y agentes de IA pierden contexto al navegar cientos de líneas no relacionadas con el problema puntual.
* **Pruebas complejas:** Es imposible testear componentes visuales de forma aislada si están embebidos en funciones privadas `_buildAlgo()` dentro de un Screen gigante.

**La Regla de Oro:**  
> *"Si tocas una pieza del rompecabezas para corregir un bug o mejorar un diseño, ninguna otra pieza del sistema debe ser afectada."*

---

## 2. Parámetros Métricos para Refactorización

Cualquier archivo en el repositorio debe evaluarse contra estos 5 parámetros objetivos:

| Parámetro | Límite Verde (Óptimo) | Límite Amarillo (Alerta) | Límite Rojo (Refactor Obligatorio) |
|---|---|---|---|
| **Líneas de Código (LOC)** | $\le 180$ líneas | $181 - 250$ líneas | $> 250$ líneas (Tope 300) |
| **Responsabilidades por Archivo** | 1 sola (SRP) | 1 principal + 1 auxiliar | $\ge 2$ responsabilidades disjuntas |
| **Diálogos / Formularios Embebidos** | 0 en el Screen (archivos propios) | N/A | $\ge 1$ diálogo declarado inline |
| **Widgets de Tarjeta / Item Embebidos** | 0 en el Screen (archivos propios) | N/A | $\ge 1$ tarjeta compleja inline |
| **Entidades por Repositorio (Backend)** | 1 entidad por archivo | N/A | $\ge 2$ entidades en el mismo archivo |

---

## 3. Catálogo de Patrones de Refactorización

### 3.1 Patrón: Descomposición de Diálogos y Modales (*Dialog Extraction*)
* **Anti-patrón:** Métodos privados `_mostrarDialogoCrearX()` de 60–100 líneas dentro de un `State<Screen>`.
* **Solución Refactorizada:**
  - Crear carpeta `widgets/dialogs/`.
  - Crear `crear_x_dialog.dart` como un `StatelessWidget` o `StatefulWidget` autónomo.
  - La invocación se realiza mediante una función estática o llamando a `showDialog` pasando el widget independiente:
    ```dart
    final resultado = await showDialog<TipoResultado>(
      context: context,
      builder: (ctx) => const CrearXDialog(),
    );
    ```

### 3.2 Patrón: Descomposición de Tarjetas y Celdas de Lista (*Card Component Extraction*)
* **Anti-patrón:** `itemBuilder: (context, index) { ... 80 líneas de BoxDecoration, Column, Row, Icons y botones ... }`.
* **Solución Refactorizada:**
  - Crear carpeta `widgets/cards/`.
  - Extraer a `x_card.dart` o `x_list_tile.dart` que recibe la entidad inmutable y los callbacks necesarios (`onTap`, `onEdit`, `onDelete`).
  - El Screen principal solo pasa datos y reacciona al evento.

### 3.3 Patrón: Descomposición de Paneles de Control y Filtros (*Panel Extraction*)
* **Anti-patrón:** Bloques extensos de selectores en cascada (ej: Sede $\rightarrow$ Bloque) mezclados con la barra de herramientas y la lista de contenido.
* **Solución Refactorizada:**
  - Crear carpeta `widgets/panels/`.
  - Extraer a `jerarquia_selector_panel.dart` que expone callbacks limpios (`onSedeChanged`, `onBloqueChanged`).

### 3.4 Patrón: Separación de Repositorios Monolíticos en Backend (*Repository Splitting*)
* **Anti-patrón:** Un solo archivo `academico.go` o `geo.go` de 900 líneas que implementa 5 interfaces de repositorio distintas (Sede, Bloque, Espacio, Historial).
* **Solución Refactorizada:**
  - Crear un archivo por repositorio dentro de `internal/repository/mongo/impl/`:
    - `sede.go` (~120 líneas)
    - `bloque.go` (~140 líneas)
    - `espacio.go` (~220 líneas)
    - `historial.go` (~150 líneas)
  - Cada archivo maneja únicamente la colección de MongoDB correspondiente a su entidad.

---

## 4. Protocolo de Ejecución de Refactorización Paso a Paso

Para refactorizar un archivo sin introducir regresiones, el agente debe seguir rigurosamente este procedimiento:

```
[1. Inventario & Tests] ──> [2. Crear Archivos Satélite] ──> [3. Reducir Screen/Clase] 
                                                                    │
[6. Git Commit Refactor] <── [5. Verificación Tests]  <── [4. Limpieza de Imports]
```

1. **Paso 1: Inventario y Línea Base de Pruebas:**
   - Ejecutar `go test ./...` y `flutter test` para confirmar que el sistema funciona antes de tocar código.
   - Listar las responsabilidades identificadas en el archivo monolítico y calcular cuántos archivos satélite nacerán.

2. **Paso 2: Crear Archivos Satélite (Piezas del Rompecabezas):**
   - Crear los nuevos widgets o clases en carpetas organizadas (`dialogs/`, `cards/`, `panels/`).
   - Mantener las firmas de datos idénticas: no cambiar tipos de datos ni nombres de eventos durante el refactor.

3. **Paso 3: Reducir el Archivo Orquestador:**
   - Reemplazar el código inline por las llamadas a los nuevos componentes.
   - Verificar que el archivo principal ahora mida **menos de 200 líneas**.

4. **Paso 4: Limpieza de Imports y Exportaciones:**
   - Eliminar dependencias innecesarias en el archivo orquestador.
   - Garantizar que cada componente nuevo solo importe lo estrictamente necesario.

5. **Paso 5: Verificación Automatizada Obligatoria:**
   - Ejecutar suite de pruebas completa:
     - `flutter test` en móvil y web.
     - `go test ./...` en backend.
   - Todos los tests deben pasar en verde (0 errores).

6. **Paso 6: Registro en Git:**
   - Commit con convención semántica: `refactor(area): modularizar [nombre_archivo] en componentes [piezas creadas]`.

---

## 5. Plan Prioritario de Refactorización del Código Base

Archivos identificados que superan el límite de 250 líneas y su plan de descomposición:

### Fase 1 — Frontend Móvil Crítico (Alta Prioridad):
1. **`mobile/lib/features/home/presentation/screens/home_screen.dart` (828 líneas $\rightarrow$ < 160 líneas)**:
   - Extraer `CrearSedeDialog` a `widgets/dialogs/crear_sede_dialog.dart`.
   - Extraer `CrearBloqueDialog` a `widgets/dialogs/crear_bloque_dialog.dart`.
   - Extraer `CrearEspacioDialog` a `widgets/dialogs/crear_espacio_dialog.dart`.
   - Extraer `EspacioCard` a `widgets/cards/espacio_card.dart`.
   - Extraer `JerarquiaSelectorPanel` a `widgets/panels/jerarquia_selector_panel.dart`.
   - Extraer `ModulosSecundariosPanel` a `widgets/panels/modulos_secundarios_panel.dart`.

### Fase 2 — Frontend Web Dashboard (Alta Prioridad):
2. **`web/lib/features/dashboard/presentation/screens/dashboard_screen.dart` (829 líneas $\rightarrow$ < 180 líneas)**:
   - Extraer métricas resumen a `widgets/dashboard_stats_row.dart`.
   - Extraer tabla de actividades a `widgets/recent_activity_table.dart`.
   - Extraer menú lateral de navegación a `widgets/dashboard_sidebar.dart`.

### Fase 3 — Backend Repositorios Mongo (Media Prioridad):
3. **`backend/internal/repository/mongo/impl/geo.go` (807 líneas $\rightarrow$ 4 archivos de ~150-200 líneas)**:
   - Dividir en `sede_mongo.go`, `bloque_mongo.go`, `espacio_mongo.go` y `espacio_hist_mongo.go`.
4. **`backend/internal/repository/mongo/impl/academico.go` (954 líneas $\rightarrow$ 6 archivos de ~160 líneas)**:
   - Dividir en `periodo_mongo.go`, `asignatura_mongo.go`, `docente_mongo.go`, `grupo_mongo.go`, `asignacion_mongo.go` y `excepcion_mongo.go`.
