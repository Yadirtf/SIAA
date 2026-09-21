// Package handler contiene el handler de salud del servicio.
// T-PLT-01.8 — US-PLT-01 AC-02, AC-03
package handler

import (
	"context"
	"net/http"
	"os"
	"time"

	"github.com/labstack/echo/v4"
)

// HealthChecker es la interfaz para verificar el estado de las dependencias.
type HealthChecker interface {
	Ping(ctx context.Context) error
}

// HealthHandler maneja los endpoints de salud del servicio.
type HealthHandler struct {
	mongo   HealthChecker
	version string
	commit  string
	startAt time.Time
}

// NewHealthHandler crea un nuevo handler de salud.
func NewHealthHandler(mongo HealthChecker, version, commit string) *HealthHandler {
	return &HealthHandler{
		mongo:   mongo,
		version: version,
		commit:  commit,
		startAt: time.Now(),
	}
}

// healthResponse es la respuesta del endpoint de salud (AC-02 US-PLT-01).
type healthResponse struct {
	Status         string            `json:"status"`
	Version        string            `json:"version"`
	Commit         string            `json:"commit"`
	UptimeSegundos int64             `json:"uptimeSegundos"`
	Dependencias   map[string]string `json:"dependencias"`
	Hostname       string            `json:"hostname,omitempty"`
}

// Health maneja GET /api/v1/health — siempre responde 200 (AC-02).
func (h *HealthHandler) Health(c echo.Context) error {
	hostname, _ := os.Hostname()
	uptime := int64(time.Since(h.startAt).Seconds())

	return c.JSON(http.StatusOK, healthResponse{
		Status:         "ok",
		Version:        h.version,
		Commit:         h.commit,
		UptimeSegundos: uptime,
		Hostname:       hostname,
		Dependencias: map[string]string{
			"mongo": "ok", // simplificado — ready verifica realmente
		},
	})
}

// Ready maneja GET /api/v1/health/ready — verifica dependencias (AC-03).
// Devuelve 503 si MongoDB no está disponible, 200 si sí.
func (h *HealthHandler) Ready(c echo.Context) error {
	ctx, cancel := context.WithTimeout(c.Request().Context(), 3*time.Second)
	defer cancel()

	mongoStatus := "ok"
	overallStatus := "ok"
	httpStatus := http.StatusOK

	if err := h.mongo.Ping(ctx); err != nil {
		mongoStatus = "error"
		overallStatus = "degradado"
		httpStatus = http.StatusServiceUnavailable
	}

	return c.JSON(httpStatus, healthResponse{
		Status:         overallStatus,
		Version:        h.version,
		Commit:         h.commit,
		UptimeSegundos: int64(time.Since(h.startAt).Seconds()),
		Dependencias: map[string]string{
			"mongo": mongoStatus,
		},
	})
}
