// Package http — rutas de parametrización jerárquica (EP-05, US-PAR-01, US-PAR-03).
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

func registerParametroRoutes(
	api *echo.Group,
	cfg *config.Config,
	auditoria repository.AuditoriaRepository,
	registry *RouteRegistry,
	parametroH *handler.ParametroHandler,
) {
	if parametroH == nil {
		return
	}
	params := api.Group("/parametros", mw.JWTAuth(cfg), mw.RateLimiterByUser(120))
	// GET /parametros?ambito=SEDE&ambito_id=xxx — lista los parámetros de un nivel
	params.GET("", parametroH.ListarPorAmbito, mw.RequirePermission(rbac.PermParametroLeer, auditoria))
	registry.RegisterPermission(http.MethodGet, "/api/v1/parametros", rbac.PermParametroLeer)
	// PUT /parametros — inserta o actualiza un parámetro (US-PAR-01 AC-03)
	params.PUT("", parametroH.GuardarParametro, mw.RequirePermission(rbac.PermParametroEditar, auditoria))
	registry.RegisterPermission(http.MethodPut, "/api/v1/parametros", rbac.PermParametroEditar)
	// GET /parametros/efectivos — resuelve cascada con origen (US-PAR-03 AC-01)
	params.GET("/efectivos", parametroH.ObtenerEfectivos, mw.RequirePermission(rbac.PermParametroLeer, auditoria))
	registry.RegisterPermission(http.MethodGet, "/api/v1/parametros/efectivos", rbac.PermParametroLeer)
}
