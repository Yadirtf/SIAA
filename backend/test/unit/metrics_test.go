// Pruebas unitarias para Observabilidad y Métricas.
// Satisface US-PLT-05, AC-01 y RNF-PER-003.
package unit_test

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/platform/metrics"
	"github.com/siaa/backend/internal/transport/http/handler"
	mw "github.com/siaa/backend/internal/transport/http/middleware"
)

func TestMetrics_CollectorPercentilesAndErrorRate(t *testing.T) {
	c := metrics.NewCollector()

	// Simular 100 peticiones con diferentes duraciones
	for i := 1; i <= 100; i++ {
		duration := time.Duration(i) * time.Millisecond
		isError := i > 90 // 10% tasa de error
		c.RecordRequest("POST /api/v1/marcajes", duration, isError)
	}

	c.RecordMarcajeResultado("VALIDO")
	c.RecordMarcajeResultado("VALIDO")
	c.RecordMarcajeResultado("RETARDO")
	c.RecordMarcajeResultado("FUERA_DE_AREA")

	c.SetDBStats(15, 85) // 15% saturación

	report := c.GetReport()

	if report.SolicitudesTotal != 100 {
		t.Errorf("solicitudesTotal esperada 100, obtuvo %d", report.SolicitudesTotal)
	}

	if report.ErroresTotal != 10 {
		t.Errorf("erroresTotal esperado 10, obtuvo %d", report.ErroresTotal)
	}

	if report.TasaError < 0.099 || report.TasaError > 0.101 {
		t.Errorf("tasaError esperada ~0.10, obtuvo %f", report.TasaError)
	}

	rm, ok := report.Rutas["POST /api/v1/marcajes"]
	if !ok {
		t.Fatalf("no se encontró ruta POST /api/v1/marcajes en el reporte")
	}

	if rm.Latencia.P50Ms < 45 || rm.Latencia.P50Ms > 55 {
		t.Errorf("p50 esperado ~50ms, obtuvo %f", rm.Latencia.P50Ms)
	}

	if rm.Latencia.P95Ms < 90 || rm.Latencia.P95Ms > 96 {
		t.Errorf("p95 esperado ~95ms, obtuvo %f", rm.Latencia.P95Ms)
	}

	if report.BaseDatos.SaturacionPorcentaje < 14.9 || report.BaseDatos.SaturacionPorcentaje > 15.1 {
		t.Errorf("saturacion DB esperada 15%%, obtuvo %f", report.BaseDatos.SaturacionPorcentaje)
	}

	if report.ResultadosMarcaje["VALIDO"] != 2 {
		t.Errorf("conteo VALIDO esperado 2, obtuvo %d", report.ResultadosMarcaje["VALIDO"])
	}
}

func TestMetrics_EndpointReturns200WithFullSchema(t *testing.T) {
	collector := metrics.NewCollector()
	collector.RecordRequest("GET /api/v1/health", 5*time.Millisecond, false)
	collector.SetDBStats(2, 18)

	e := echo.New()
	e.Use(mw.MetricsMiddleware(collector))

	h := handler.NewMetricsHandler(collector)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/metrics", nil)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)

	if err := h.GetMetrics(c); err != nil {
		t.Fatalf("GetMetrics falló: %v", err)
	}

	if rec.Code != http.StatusOK {
		t.Fatalf("código HTTP esperado 200, obtuvo %d", rec.Code)
	}

	var report metrics.MetricsReport
	if err := json.Unmarshal(rec.Body.Bytes(), &report); err != nil {
		t.Fatalf("error deserializando reporte JSON: %v", err)
	}

	if report.BaseDatos.ConexionesActivas != 2 {
		t.Errorf("conexiones activas esperadas 2, obtuvo %d", report.BaseDatos.ConexionesActivas)
	}
}
