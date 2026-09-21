// Package http configura el enrutador principal y registra todas las rutas.
// T-PLT-01.3, T-ROL-01.4: toda ruta debe declarar su permiso o ser marcada pública.
// En caso contrario el servicio NO arranca.
package http

import (
	"net/http"
	"time"

	"github.com/labstack/echo/v4"
	echoMiddleware "github.com/labstack/echo/v4/middleware"

	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/platform/config"
	applog "github.com/siaa/backend/internal/platform/log"
	"github.com/siaa/backend/internal/repository"
	"github.com/siaa/backend/internal/transport/http/handler"
	mw "github.com/siaa/backend/internal/transport/http/middleware"
)

// NewRouter crea y configura el servidor Echo con todos los middlewares y rutas,
// e impone la verificación de rutas al arranque exigida por T-ROL-01.4 y AC-03.
func NewRouter(
	cfg *config.Config,
	log *applog.Logger,
	health *handler.HealthHandler,
	authH *handler.AuthHandler,
	openapiH *handler.OpenAPIHandler,
	rolesH *handler.RolesHandler,
	auditoria repository.AuditoriaRepository,
	registry *RouteRegistry,
) (*echo.Echo, error) {
	if registry == nil {
		registry = NewRouteRegistry()
	}

	e := echo.New()
	e.HideBanner = true
	e.HidePort = true

	// ─── Middlewares globales ────────────────────────────────
	e.Use(mw.Recovery(log))
	e.Use(mw.CorrelationID())
	e.Use(mw.RequestLogger(log))
	e.Use(echoMiddleware.TimeoutWithConfig(echoMiddleware.TimeoutConfig{
		Timeout: 30 * time.Second,
	}))
	e.Use(echoMiddleware.CORSWithConfig(echoMiddleware.CORSConfig{
		AllowOrigins:     []string{"https://*.siaa.edu.co"},
		AllowHeaders:     []string{echo.HeaderOrigin, echo.HeaderContentType, echo.HeaderAuthorization, mw.HeaderCorrelationID, "Idempotency-Key"},
		AllowMethods:     []string{http.MethodGet, http.MethodPost, http.MethodPatch, http.MethodPut, http.MethodDelete},
		ExposeHeaders:    []string{mw.HeaderCorrelationID},
		AllowCredentials: false,
		MaxAge:           86400,
	}))

	// Error handler centralizado
	e.HTTPErrorHandler = mw.ErrorHandler(log)

	// ─── Validador ────────────────────────────────────────────
	e.Validator = newValidator()

	// ─── Rutas ───────────────────────────────────────────────
	api := e.Group("/api/v1")

	// OpenAPI 3.1 (pública, US-PLT-01 AC-06, T-PLT-01.9)
	if openapiH != nil {
		api.GET("/openapi.json", openapiH.Spec)
		registry.MarkPublic(http.MethodGet, "/api/v1/openapi.json")
	}

	// Salud (públicas, sin autenticación)
	api.GET("/health", health.Health)
	registry.MarkPublic(http.MethodGet, "/api/v1/health")
	api.GET("/health/ready", health.Ready)
	registry.MarkPublic(http.MethodGet, "/api/v1/health/ready")

	// Autenticación (públicas con límite estricto de 20 req/min por origen — US-AUT-02 AC-03)
	authGroup := api.Group("/auth")
	authRateLimit := 20
	if cfg.RateLimitPerMinute > 0 && cfg.RateLimitPerMinute < 20 {
		authRateLimit = cfg.RateLimitPerMinute
	}
	authGroup.Use(mw.RateLimiterByIP(authRateLimit))
	authGroup.POST("/login", authH.Login)
	registry.MarkPublic(http.MethodPost, "/api/v1/auth/login")
	authGroup.POST("/refresh", authH.Refresh)
	registry.MarkPublic(http.MethodPost, "/api/v1/auth/refresh")
	authGroup.POST("/recuperar", authH.SolicitarRecuperacion)
	registry.MarkPublic(http.MethodPost, "/api/v1/auth/recuperar")
	authGroup.POST("/recuperar/confirmar", authH.ConfirmarRecuperacion)
	registry.MarkPublic(http.MethodPost, "/api/v1/auth/recuperar/confirmar")

	// Autenticación (requiere token válido y tasa de 120 req/min por usuario — US-AUT-02 AC-04)
	authProtected := api.Group("/auth", mw.JWTAuth(cfg), mw.RateLimiterByUser(120))
	authProtected.POST("/logout", authH.Logout)
	registry.MarkPublic(http.MethodPost, "/api/v1/auth/logout")

	// Administración de usuarios (requiere token válido y tasa de 120 req/min por usuario)
	usuariosProtected := api.Group("/usuarios", mw.JWTAuth(cfg), mw.RateLimiterByUser(120))
	// Desbloqueo administrativo auditado (US-AUT-02 AC-02, T-AUT-02.3)
	usuariosProtected.POST("/:id/desbloquear", authH.DesbloquearUsuario, mw.RequirePermission(rbac.PermUsuarioEditar, auditoria))
	registry.RegisterPermission(http.MethodPost, "/api/v1/usuarios/:id/desbloquear", rbac.PermUsuarioEditar)

	// Roles y permisos del sistema — US-ROL-01 AC-01
	if rolesH != nil {
		rolesProtected := api.Group("/roles", mw.JWTAuth(cfg), mw.RateLimiterByUser(120))
		rolesProtected.GET("", rolesH.ListarRoles, mw.RequirePermission(rbac.PermRolLeer, auditoria))
		registry.RegisterPermission(http.MethodGet, "/api/v1/roles", rbac.PermRolLeer)
	}

	// ─── Verificación al arranque — T-ROL-01.4, AC-03 ─────────
	// Toda ruta bajo /api/v1 DEBE declarar su permiso o estar explícitamente marcada como pública.
	if err := registry.VerifyAllRoutes(e); err != nil {
		return nil, err
	}

	return e, nil
}
