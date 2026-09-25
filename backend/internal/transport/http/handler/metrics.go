// Package handler — Handler HTTP para el endpoint de métricas y observabilidad.
// Satisface US-PLT-05, AC-01 y RNF-PER-003.
package handler

import (
	"net/http"

	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/platform/metrics"
)

// MetricsHandler gestiona el endpoint GET /api/v1/metrics.
type MetricsHandler struct {
	collector *metrics.Collector
}

// NewMetricsHandler inicializa el manejador de métricas.
func NewMetricsHandler(collector *metrics.Collector) *MetricsHandler {
	return &MetricsHandler{collector: collector}
}

// GetMetrics retorna el estado consolidado de métricas en formato JSON.
func (h *MetricsHandler) GetMetrics(c echo.Context) error {
	report := h.collector.GetReport()
	return c.JSON(http.StatusOK, report)
}
