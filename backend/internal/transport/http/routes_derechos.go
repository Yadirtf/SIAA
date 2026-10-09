// Package http — rutas de los derechos del titular (US-LEG-02, RNF-LEG-004).
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

// registerDerechosRoutes publica el canal (público), las rutas del propio titular (con token,
// sin permiso RBAC) y la bandeja de atención (usuario:editar: corregir y suprimir datos de una
// cuenta es gestión de usuarios).
func registerDerechosRoutes(api *echo.Group, cfg *config.Config, auditoria repository.AuditoriaRepository, registry *RouteRegistry, d *handler.DerechosHandler) {
	if d == nil {
		return
	}
	api.GET("/privacidad/derechos", d.Canal, mw.RateLimiterByIP(60))
	registry.MarkPublic(http.MethodGet, "/api/v1/privacidad/derechos")

	propia := func(g *echo.Group, metodo, prefijo, ruta string, fn echo.HandlerFunc) {
		g.Add(metodo, ruta, fn)
		registry.MarkPublic(metodo, "/api/v1"+prefijo+ruta)
	}
	datos := api.Group("/me/datos", mw.JWTAuth(cfg), mw.RateLimiterByUser(10))
	propia(datos, http.MethodGet, "/me/datos", "", d.MisDatos)
	me := api.Group("/me/derechos", mw.JWTAuth(cfg), mw.RateLimiterByUser(30))
	propia(me, http.MethodGet, "/me/derechos", "/solicitudes", d.MisSolicitudes)
	propia(me, http.MethodPost, "/me/derechos", "/solicitudes", d.Radicar)
	propia(me, http.MethodGet, "/me/derechos", "/supresion", d.EvaluarSupresion)

	g := api.Group("/privacidad/solicitudes", mw.JWTAuth(cfg), mw.RateLimiterByUser(120))
	proteger := func(metodo, ruta string, fn echo.HandlerFunc) {
		g.Add(metodo, ruta, fn, mw.RequirePermission(rbac.PermUsuarioEditar, auditoria))
		registry.RegisterPermission(metodo, "/api/v1/privacidad/solicitudes"+ruta, rbac.PermUsuarioEditar)
	}
	proteger(http.MethodGet, "", d.Bandeja)
	proteger(http.MethodPost, "/:id/asumir", d.Asumir)
	proteger(http.MethodPost, "/:id/resolver", d.Resolver)
}
