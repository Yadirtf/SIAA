// Package http — registro de rutas para el motor de marcajes (EP-06).
// Satisface US-MAR-01..US-MAR-15, T-ROL-01.4 y contratos de la API.
package http

import (
	"net/http"

	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/platform/config"
	"github.com/siaa/backend/internal/repository"
	"github.com/siaa/backend/internal/transport/http/handler"
	mw "github.com/siaa/backend/internal/transport/http/middleware"
)

func registerMarcajeRoutes(
	api *echo.Group,
	cfg *config.Config,
	auditoria repository.AuditoriaRepository,
	registry *RouteRegistry,
	marcajeH *handler.MarcajeHandler,
	marcajeAdminH *handler.MarcajeAdminHandler,
	marcajeSyncH *handler.MarcajeSyncHandler,
) {
	if marcajeH == nil {
		return
	}

	marcajes := api.Group("/marcajes", mw.JWTAuth(cfg), mw.RateLimiterByUser(120))
	// POST /marcajes (US-MAR-01, US-MAR-03, US-MAR-04, US-MAR-05)
	marcajes.POST("", marcajeH.Crear, mw.RequirePermission(rbac.PermMarcajeCrear, auditoria))
	registry.RegisterPermission(http.MethodPost, "/api/v1/marcajes", rbac.PermMarcajeCrear)

	// POST /marcajes/sync (US-MAR-11)
	if marcajeSyncH != nil {
		marcajes.POST("/sync", marcajeSyncH.SyncOffline, mw.RequirePermission(rbac.PermMarcajeCrear, auditoria))
		registry.RegisterPermission(http.MethodPost, "/api/v1/marcajes/sync", rbac.PermMarcajeCrear)
	}

	if marcajeAdminH != nil {
		// GET /marcajes (US-MAR-09)
		marcajes.GET("", marcajeAdminH.ListarMarcajes, mw.RequirePermission(rbac.PermMarcajeLeer, auditoria))
		registry.RegisterPermission(http.MethodGet, "/api/v1/marcajes", rbac.PermMarcajeLeer)

		// PATCH /marcajes/:id (US-MAR-09)
		marcajes.PATCH("/:id", marcajeAdminH.AjustarMarcaje, mw.RequirePermission(rbac.PermMarcajeAjustar, auditoria))
		registry.RegisterPermission(http.MethodPatch, "/api/v1/marcajes/:id", rbac.PermMarcajeAjustar)

		// POST /marcajes/manual (US-MAR-09)
		marcajes.POST("/manual", marcajeAdminH.CrearManual, mw.RequirePermission(rbac.PermMarcajeAjustar, auditoria))
		registry.RegisterPermission(http.MethodPost, "/api/v1/marcajes/manual", rbac.PermMarcajeAjustar)
	}

	// Rutas propias del usuario autenticado (/api/v1/me/...)
	me := api.Group("/me", mw.JWTAuth(cfg), mw.RateLimiterByUser(120))
	me.GET("/sesiones/activa", marcajeH.SesionActiva, mw.RequirePermission(rbac.PermMarcajeCrear, auditoria))
	registry.RegisterPermission(http.MethodGet, "/api/v1/me/sesiones/activa", rbac.PermMarcajeCrear)

	me.GET("/sesiones/hoy", marcajeH.SesionesHoy, mw.RequirePermission(rbac.PermMarcajeCrear, auditoria))
	registry.RegisterPermission(http.MethodGet, "/api/v1/me/sesiones/hoy", rbac.PermMarcajeCrear)

	me.GET("/historial", marcajeH.Historial, mw.RequirePermission(rbac.PermMarcajeLeer, auditoria))
	registry.RegisterPermission(http.MethodGet, "/api/v1/me/historial", rbac.PermMarcajeLeer)

	if marcajeAdminH != nil {
		sesiones := api.Group("/sesiones", mw.JWTAuth(cfg), mw.RateLimiterByUser(120))
		// POST /sesiones/:id/ventana-estudiantil (US-MAR-13)
		sesiones.POST("/:id/ventana-estudiantil", marcajeAdminH.VentanaEstudiantil, mw.RequirePermission(rbac.PermMarcajeCrear, auditoria))
		registry.RegisterPermission(http.MethodPost, "/api/v1/sesiones/:id/ventana-estudiantil", rbac.PermMarcajeCrear)

		// POST /sesiones/:id/lista-manual (US-MAR-14)
		sesiones.POST("/:id/lista-manual", marcajeAdminH.ListaManual, mw.RequirePermission(rbac.PermMarcajeCrear, auditoria))
		registry.RegisterPermission(http.MethodPost, "/api/v1/sesiones/:id/lista-manual", rbac.PermMarcajeCrear)
	}
}
