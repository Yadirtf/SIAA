# Pruebas de Carga de Pico Horario — SIAA (US-PLT-05)

Este módulo contiene el escenario de prueba de carga automatizado para simular el momento de mayor concurrencia del campus (pico de marcaje de las 7:00 AM).

## Criterios de Aceptación (SRS §5.3, RNF-PER-001, RNF-PER-003):
- **Tasa sostenida:** 300 solicitudes por segundo durante 10 minutos.
- **Latencia p95:** ≤ 2.0 segundos.
- **Tasa de error global:** ≤ 0.1 % (1 error por cada 1000 solicitudes).
- **Consultas geoespaciales:** Cero escaneos de colección (`COLLSCAN`) en MongoDB (US-PLT-05 AC-03).

## Ejecución con k6:
```bash
k6 run infra/load-test/k6-pico-horario.js
```

## Ejecución con el Runner Nativo en Go:
```bash
go run infra/load-test/load_test_runner.go -url http://localhost:8080/api/v1/health -rps 300 -duration 600
```

## Verificación de Planes de Consulta MongoDB (AC-03):
Para verificar que las consultas espaciales utilizan los índices `2dsphere` y no realizan `COLLSCAN`:
```javascript
// En mongosh:
db.espacios.explain("executionStats").find({
  geometria: {
    $geoIntersects: {
      $geometry: {
        type: "Point",
        coordinates: [-74.08175, 4.60971]
      }
    }
  }
})
```
Verificar en la salida:
- `stage: "IXSCAN"`
- `indexName: "geometria_2dsphere"` o `geometriaBuffer_2dsphere"`
- `totalDocsExamined`: bajo (sin escaneo de colección completa).
