// Package http — rutas de justificaciones (EP-07), reportes (EP-08) y bitácora (RF-AUD-003).
package http

import (
	"net/http"

	"github.com/labstack/echo/v4"
	echoMiddleware "github.com/labstack/echo/v4/middleware"

	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/platform/config"
	"github.com/siaa/backend/internal/repository"
	"github.com/siaa/backend/internal/transport/http/handler"
	mw "github.com/siaa/backend/internal/transport/http/middleware"
)

// HandlersSeguimiento agrupa los handlers de justificaciones, reportes y auditoría.
type HandlersSeguimiento struct {
	Justificaciones *handler.JustificacionesHandler
	Reportes        *handler.ReportesHandler
	Auditoria       *handler.AuditoriaHandler
}

func registerSeguimientoRoutes(
	api *echo.Group,
	cfg *config.Config,
	auditoria repository.AuditoriaRepository,
	registry *RouteRegistry,
	h *HandlersSeguimiento,
) {
	if h == nil {
		return
	}
	proteger := func(g *echo.Group, prefijo, metodo, ruta string, fn echo.HandlerFunc, perm rbac.Permission, extra ...echo.MiddlewareFunc) {
		g.Add(metodo, ruta, fn, append([]echo.MiddlewareFunc{mw.RequirePermission(perm, auditoria)}, extra...)...)
		registry.RegisterPermission(metodo, "/api/v1"+prefijo+ruta, perm)
	}

	if j := h.Justificaciones; j != nil {
		g := api.Group("/justificaciones", mw.JWTAuth(cfg), mw.RateLimiterByUser(120))
		// Hasta 3 soportes de 10 MB más los campos del formulario.
		proteger(g, "/justificaciones", http.MethodPost, "", j.Radicar, rbac.PermJustificacionCrear, echoMiddleware.BodyLimit("32M"))
		proteger(g, "/justificaciones", http.MethodGet, "", j.Listar, rbac.PermJustificacionLeer)
		proteger(g, "/justificaciones", http.MethodGet, "/:id", j.Obtener, rbac.PermJustificacionLeer)
		proteger(g, "/justificaciones", http.MethodGet, "/:id/soportes/:soporteId", j.DescargarSoporte, rbac.PermJustificacionLeer)
		proteger(g, "/justificaciones", http.MethodPatch, "/:id", j.Revisar, rbac.PermJustificacionAprobar)
	}
	if r := h.Reportes; r != nil {
		g := api.Group("/reportes", mw.JWTAuth(cfg), mw.RateLimiterByUser(120))
		proteger(g, "/reportes", http.MethodGet, "/cumplimiento", r.Cumplimiento, rbac.PermReporteLeer)
		proteger(g, "/reportes", http.MethodGet, "/cumplimiento/exportar", r.ExportarCumplimiento, rbac.PermReporteExportar)
	}
	if a := h.Auditoria; a != nil {
		g := api.Group("/auditoria", mw.JWTAuth(cfg), mw.RateLimiterByUser(120))
		proteger(g, "/auditoria", http.MethodGet, "", a.Consultar, rbac.PermAuditoriaLeer)
		proteger(g, "/auditoria", http.MethodGet, "/exportar", a.Exportar, rbac.PermAuditoriaLeer)
	}
}
