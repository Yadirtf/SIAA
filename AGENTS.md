# SIAA — Directrices del Agente (`AGENTS.md`)

Este repositorio cuenta con el manual y protocolo exhaustivo de desarrollo en [agente.md](file:///c:/Users/pc/Desktop/SIAA/agente.md).

## Resumen de Reglas de Oro Obligatorias:
1. **Principio del Rompecabezas (Modularidad Extrema):** Cada archivo debe tener una sola responsabilidad (SRP).
2. **Límite Estricto de Tamaño de Archivo:** Máximo 250 a 300 líneas. Si un archivo supera este límite, debe descomponerse en widgets, servicios o helpers independientes.
3. **Cero Mocks Engañosos:** Toda funcionalidad debe conectarse a endpoints y base de datos MongoDB real.
4. **Backend First:** El backend Go es la autoridad para validación topológica, seguridad RBAC y persistencia. El frontend Flutter se encarga de la experiencia interactiva, telemetría y estado BLoC.
5. **Trazabilidad:** Seguir siempre las especificaciones técnicas de [`SIAA-Backlog-Historias-de-Usuario-y-Plan-Tecnico.md`](file:///c:/Users/pc/Desktop/SIAA/SIAA-Backlog-Historias-de-Usuario-y-Plan-Tecnico.md) y [`document_text.txt`](file:///c:/Users/pc/Desktop/SIAA/document_text.txt).
6. **Verificación:** Ejecutar `go test ./...` y `flutter test` antes de dar cualquier tarea por terminada.
