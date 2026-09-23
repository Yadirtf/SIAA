# SIAA — Guía Técnica y Protocolo de Actuación para Agentes de Desarrollo (`agente.md`)

> **Propósito del Documento:**  
> Este documento establece las reglas obligatorias de arquitectura, modularidad, diseño y ejecución para cualquier agente de Inteligencia Artificial o desarrollador que participe en la implementación de sprints, historias de usuario o corrección de bugs en el proyecto **SIAA (Sistema Integrado de Asistencia Académica)**.

---

## 1. Análisis de los Documentos Base del Proyecto

Antes de escribir una sola línea de código, el agente **debe consultar y comprender** los dos documentos rectores ubicados en la raíz del repositorio:

1. **[`document_text.txt`](file:///c:/Users/pc/Desktop/SIAA/document_text.txt) (SIAA-SRS-001 v1.0 — Especificación de Requerimientos de Software):**
   - **Qué contiene:** La línea base funcional (módulos `AUT`, `ROL`, `GEO`, `ACA`, `PAR`, `MAR`, `JUS`, `REP`, `AUD`, `NOT`), los requerimientos no funcionales (rendimiento, seguridad, privacidad legal) y el diseño conceptual de la arquitectura.
   - **Evaluación técnica:** Está **completamente detallado** en cuanto a reglas de negocio (ej. validación geoespacial con buffer, holguras de tiempo, motor de estados de asistencia, índice `2dsphere`). No requiere suposiciones de alcance.

2. **[`SIAA-Backlog-Historias-de-Usuario-y-Plan-Tecnico.md`](file:///c:/Users/pc/Desktop/SIAA/SIAA-Backlog-Historias-de-Usuario-y-Plan-Tecnico.md) (SIAA-BLG-001 v1.0 — Backlog y Plan Técnico):**
   - **Qué contiene:** La traducción ejecutable del SRS dividida en 12 Épicas (`EP-00` a `EP-11`), desglosada en Historias de Usuario (`US-XXX-nn`), Criterios de Aceptación (`AC-nn`), y lo más valioso: **Subtareas Técnicas (`T-XXX-nn.n`)** que detallan endpoints, DTOs, campos de MongoDB, BLoCs y pantallas.
   - **Evaluación técnica:** Las especificaciones son sumamente rigurosas y ejecutables. 

> **Diagnóstico de errores pasados:**  
> Si ciertas historias no funcionaban como se esperaba, **no fue por falta de especificación en los documentos**, sino por:
> 1. Implementaciones superficiales o con datos simulados (*hardcoded IDs* como `esp-aula-101`) que nunca se conectaron a MongoDB real.
> 2. Creación de **archivos gigantes y monolíticos** (+300 a +800 líneas) que acumulaban múltiples responsabilidades, dificultando la depuración e induciendo regresiones.
> 3. Falta de verificación real extremo a extremo (*End-to-End*) entre Backend, Base de Datos y Frontend (Mobile/Web).

---

## 2. Las 5 Reglas de Oro Inviolables del Agente

Cualquier cambio o código generado por el agente **debe obedecer estrictamente** estos cinco principios:

### Regla 1: El Principio del Rompecabezas (Modularidad Extrema y SRP)
* **Todo archivo debe ser una pieza de rompecabezas:** una sola responsabilidad clara y aislada (*Single Responsibility Principle*).
* Si una pantalla necesita un diálogo, el diálogo va en su propio archivo. Si necesita una tarjeta de elemento, va en su propio widget. Si necesita controles de mapa, van separados del visor del mapa.
* **Beneficio operativo:** Cuando se reporte un bug o se requiera un ajuste visual o de cálculo, el agente **únicamente tocará esa pieza del rompecabezas**, dejando el resto de la aplicación intacto.

### Regla 2: Límite Estricto de Tamaño de Archivo (Tope 250 - 300 líneas)
* **Límite sugerido:** Menos de 200 líneas por archivo.
* **Límite de alerta:** 250 líneas.
* **Tope máximo absoluto:** 300 líneas.
* **Acción obligatoria:** Si un archivo supera las 250 líneas, es un *code smell* que debe ser descompuesto en subcomponentes, helpers o extensiones antes de dar por cerrada la tarea.

### Regla 3: Cero Código Ficticio o "Mocks" Engañosos
* **Prohibido usar IDs o entidades ficticias en duro:** Nada de `id: "aula-mock-123"` para simular que algo funciona.
* Toda funcionalidad debe interactuar con las rutas reales del backend y la persistencia en MongoDB.
* Si una pantalla necesita datos que dependen de otra entidad (ej. un Aula que depende de un Bloque, y este de una Sede), el agente debe implementar o consumir el flujo jerárquico completo y real.

### Regla 4: Separación Técnica de Responsabilidades (Backend vs Frontend)
* **El Backend (Go) es la única fuente de verdad y autoridad:**
  - Validaciones de topología, auto-intersección y orientación de anillos (RFC 7946).
  - Cálculo oficial de solapamiento y validación de contención (`PointInPolygon`, `2dsphere`).
  - Seguridad, roles (RBAC), auditoría inmutable y versionado histórico.
* **El Frontend (Flutter Mobile/Web) es la experiencia de usuario y telemetría:**
  - Visualización interactiva, mapas con teselas de alta resolución y micro-animaciones.
  - Captura sensorial (sensores GPS, toques sobre canvas).
  - Feedback visual inmediato (cálculo geodésico preliminar para guiar al usuario mientras traza).
  - Gestión de estado unidireccional y predecible mediante BLoC.

### Regla 5: Verificación Real y Automatizada
* Cada historia o corrección debe acompañarse de sus correspondientes pruebas automatizadas (pruebas unitarias en Go para backend, y en Dart para Flutter).
* Antes de reportar éxito, el agente debe compilar y ejecutar los tests (`go test ./...` y `flutter test`).

---

## 3. Arquitectura de Archivos por Capas (Estructura de Piezas)

Para mantener los archivos bajo el límite de 200–250 líneas, se debe seguir esta distribución:

### 3.1 Frontend (Flutter: `mobile/` y `web/`)

La estructura por funcionalidad (*Feature-First*) debe descomponerse en carpetas granulares:

```text
features/nombre_feature/
├── data/
│   ├── datasources/                 # Llamadas HTTP directas a Dio (< 150 líneas)
│   ├── models/                      # Clases de serialización/deserialización JSON (< 120 líneas)
│   └── repositories/                # Implementación de repositorios consumidos por el BLoC (< 200 líneas)
├── domain/
│   ├── entities/                    # Entidades puras e inmutables (< 100 líneas)
│   └── services/                    # Algoritmos puros (ej. GeodesicCalculator, filtros) (< 200 líneas)
└── presentation/
    ├── bloc/
    │   ├── feature_bloc.dart        # Solo orquestación de handlers (< 250 líneas)
    │   ├── feature_event.dart       # Eventos puros (< 150 líneas)
    │   └── feature_state.dart       # Estados inmutables y copyWith (< 180 líneas)
    ├── screens/
    │   └── feature_screen.dart      # Solo Scaffold y orquestador de widgets (< 200 líneas)
    └── widgets/
        ├── dialogs/                 # Cada modal/diálogo en un archivo propio (< 150 líneas)
        │   ├── crear_sede_dialog.dart
        │   └── confirmar_accion_dialog.dart
        ├── cards/                   # Tarjetas individuales de elementos (< 120 líneas)
        │   ├── espacio_card.dart
        │   └── metrica_card.dart
        ├── map/                     # Subcomponentes del mapa interactivo
        │   ├── map_canvas.dart      # Renderizado de capas (< 200 líneas)
        │   ├── map_controls.dart    # Botones flotantes (< 120 líneas)
        │   └── vertex_marker.dart   # Marcadores específicos (< 100 líneas)
        └── panels/                  # Paneles de control inferiores o laterales (< 200 líneas)
```

### 3.2 Backend (Go: `backend/internal/`)

Sigue Arquitectura Limpia hexagonal (*Ports & Adapters*):

```text
internal/
├── domain/nombre_modulo/
│   ├── entity.go                    # Estructuras de dominio y validaciones básicas (< 180 líneas)
│   └── rules.go                     # Reglas de negocio puras (< 200 líneas)
├── usecase/nombre_modulo/
│   ├── service.go                   # Orquestación de casos de uso (< 250 líneas)
│   └── types.go                     # Comandos (Cmd) y contratos del servicio (< 100 líneas)
├── repository/
│   ├── interfaces.go                # Interfaces de repositorio (< 80 líneas)
│   └── mongo/impl/
│       └── nombre_modulo.go         # Implementación MongoDB pura con BSON (< 250 líneas)
└── transport/http/
    ├── handler/
    │   └── nombre_modulo.go         # Controladores HTTP delgados (parsear DTO -> caso de uso -> responder) (< 200 líneas)
    └── dto/
        └── nombre_modulo.go         # Request / Response structs con validación por tags (< 150 líneas)
```

---

## 4. Protocolo de Trabajo Paso a Paso para cada Sprint o Historia

Cuando el usuario asigne un requerimiento, sprint o corrección, el agente debe seguir estos pasos en orden riguroso:

```
[1. Localizar en Backlog] ─> [2. Diseñar el Rompecabezas] ─> [3. Backend First]
            │
            v
[6. Auditoría de Líneas]  <─ [5. Verificación E2E]   <─ [4. Frontend Modular]
```

### Paso 1: Localizar la Historia en los Documentos Base
1. Buscar en [`SIAA-Backlog-Historias-de-Usuario-y-Plan-Tecnico.md`](file:///c:/Users/pc/Desktop/SIAA/SIAA-Backlog-Historias-de-Usuario-y-Plan-Tecnico.md) el código de la historia (ej: `US-GEO-07`, `US-MAR-01`, etc.).
2. Leer los **Criterios de Aceptación (`AC-nn`)** y las **Subtareas Técnicas (`T-XXX-nn.n`)**.
3. Cruzar con el modelo de datos en `document_text.txt` §6 y reglas de negocio §7.

### Paso 2: Diseñar el Rompecabezas (Mapeo Previo de Archivos)
* Antes de programar, definir qué archivos se van a crear o modificar.
* Preguntarse: *¿Algún archivo superará las 250 líneas si agrego esta lógica?* Si la respuesta es sí, **dividir inmediatamente** en un subwidget o clase de servicio auxiliar.

### Paso 3: Implementar Backend First (Persistencia y Lógica)
1. **Entidad y Repositorio:** Actualizar el modelo de datos e índices requeridos en MongoDB.
2. **Caso de Uso:** Implementar la lógica y validación de reglas de negocio.
3. **Transporte HTTP:** Crear DTO y Handler con códigos HTTP semánticos (`200 OK`, `201 Created`, `400 Bad Request`, `409 Conflict`, `422 Unprocessable Entity`).
4. **Pruebas Backend:** Ejecutar `go test ./...` y verificar cobertura.

### Paso 4: Implementar Frontend (Modular y Desacoplado)
1. **Modelos y Repositorio:** Consumir los DTOs exactos del backend usando `Dio`.
2. **BLoC (Estado Unidireccional):** Eventos atómicos y estados claros.
3. **Widgets Atómicos:** Construir los diálogos, tarjetas, marcadores y botones en archivos separados.
4. **Screen Coordinador:** Ensamblar los widgets atómicos como piezas de rompecabezas.

### Paso 5: Verificación End-to-End en Entorno Real
1. Probar la interacción real con el backend local (`http://localhost:8080`) y la base de datos MongoDB local o Docker.
2. Comprobar casos de éxito y casos borde (errores de red, validaciones de solapamiento, desconexión).

### Paso 6: Auditoría de Tamaño y Modularidad (Checklist de Salida)
Revisar que ningún archivo modificado o creado viole el principio de responsabilidad única o el límite de líneas.

---

## 5. Checklist de Calidad para Cierre de Tarea (Definition of Done)

El agente **no puede dar por completada una tarea** sin certificar los siguientes puntos:

- [ ] **Trazabilidad:** La solución satisface todos los Criterios de Aceptación (`AC-nn`) de la historia de usuario en el backlog.
- [ ] **Límite de líneas:** Ningún archivo nuevo o modificado sobrepasa las 250–300 líneas. Los diálogos, tarjetas y componentes visuales viven en archivos propios.
- [ ] **Integración Real:** No existen datos simulados en duro (*mocks*) para IDs, tokens o geometrías en los flujos principales.
- [ ] **Pruebas Automatizadas:** 
  - Backend: `go test ./...` pasa con éxito (0 fallos).
  - Frontend: `flutter test` pasa con éxito (0 fallos).
- [ ] **Higiene Git:** Commit semántico referenciando la épica e historia de usuario (ejemplo: `feat(geo): [EP-03][US-GEO-07] mensaje explicativo`).

---

## 6. Ejemplo Práctico: Descomposición de un Monolito en Rompecabezas

### Caso de Estudio: `home_screen.dart` (+860 líneas $\rightarrow$ 6 piezas de < 150 líneas)

| Archivo Monolítico Original | Pieza del Rompecabezas Resultante | Responsabilidad Específica | Líneas |
|---|---|---|---|
| `home_screen.dart` | `widgets/dialogs/crear_sede_dialog.dart` | Formulario y validación para registrar Sede | ~70 |
| `home_screen.dart` | `widgets/dialogs/crear_bloque_dialog.dart` | Formulario y validación para registrar Bloque | ~80 |
| `home_screen.dart` | `widgets/dialogs/crear_espacio_dialog.dart` | Formulario y validación para registrar Aula/Espacio | ~110 |
| `home_screen.dart` | `widgets/cards/espacio_card_tile.dart` | Renderizado de tarjeta de aula con botón de cartografía | ~60 |
| `home_screen.dart` | `widgets/panels/jerarquia_selector_panel.dart` | Dropdowns dependientes Sede $\rightarrow$ Bloque $\rightarrow$ Filtro | ~100 |
| `home_screen.dart` | `screens/home_screen.dart` | **Coordinador puro:** Scaffold, AppBar y ensamble de piezas | ~130 |

> **Resultado:** Cualquier cambio futuro al formulario de creación de sedes o al diseño de las tarjetas de espacios se realiza **exclusivamente en su archivo dedicado**, sin riesgo de tocar la navegación, los BLoCs o los otros módulos del sistema.
