// Package http configura el enrutador principal y registra todas las rutas.
// T-PLT-01.3, T-ROL-01.4: toda ruta debe declarar su permiso o ser marcada pública.
// En caso contrario el servicio NO arranca.
package http

import (
	"net/http"
	"strings"
	"time"

	"github.com/labstack/echo/v4"
	echoMiddleware "github.com/labstack/echo/v4/middleware"

	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/platform/config"
	applog "github.com/siaa/backend/internal/platform/log"
	"github.com/siaa/backend/internal/platform/metrics"
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
	geoH *handler.GeoHandler,
	acaH *handler.AcademicoHandler,
	parametroH *handler.ParametroHandler,
	marcajeH *handler.MarcajeHandler,
	marcajeAdminH *handler.MarcajeAdminHandler,
	marcajeSyncH *handler.MarcajeSyncHandler,
	usuariosH *handler.UsuariosHandler,
	seguimiento *HandlersSeguimiento,
	auditoria repository.AuditoriaRepository,
	registry *RouteRegistry,
) (*echo.Echo, error) {
	if registry == nil {
		registry = NewRouteRegistry()
	}

	e := echo.New()
	// La IP del cliente (límite de tasa y auditoría) solo se toma de X-Forwarded-For cuando la
	// petición llega desde un proxy de red privada (Traefik); así un cliente no puede
	// falsificar la cabecera para esquivar el límite de 20 intentos/min (US-AUT-02 AC-03).
	e.IPExtractor = echo.ExtractIPFromXFFHeader()
	e.HideBanner = true
	e.HidePort = true

	// ─── Middlewares globales ────────────────────────────────
	e.Use(mw.Recovery(log))
	e.Use(mw.CorrelationID())
	e.Use(mw.RequestLogger(log))
	e.Use(echoMiddleware.ContextTimeoutWithConfig(echoMiddleware.ContextTimeoutConfig{
		Timeout: 30 * time.Second,
	}))
	origins := cfg.CORSAllowedOrigins
	if len(origins) == 0 {
		if cfg.Env != "production" {
			origins = []string{"*"}
		} else {
			origins = []string{"https://*.siaa.edu.co"}
		}
	}

	// Soporte para Chrome Private Network Access (PNA)
	e.Use(func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			if c.Request().Header.Get("Access-Control-Request-Private-Network") == "true" {
				c.Response().Header().Set("Access-Control-Allow-Private-Network", "true")
			}
			return next(c)
		}
	})

	e.Use(echoMiddleware.CORSWithConfig(echoMiddleware.CORSConfig{
		AllowOriginFunc: func(origin string) (bool, error) {
			if cfg.Env != "production" {
				return true, nil
			}
			for _, allowed := range origins {
				if allowed == "*" || allowed == origin {
					return true, nil
				}
				if strings.HasPrefix(allowed, "https://*.") {
					baseDomain := strings.TrimPrefix(allowed, "https://*.")
					if strings.HasPrefix(origin, "https://") && strings.HasSuffix(origin, "."+baseDomain) {
						return true, nil
					}
				}
			}
			return false, nil
		},
		AllowHeaders: []string{
			echo.HeaderOrigin,
			echo.HeaderContentType,
			echo.HeaderAuthorization,
			echo.HeaderAccept,
			mw.HeaderCorrelationID,
			"Idempotency-Key",
			"X-Requested-With",
			"Access-Control-Request-Headers",
			"Access-Control-Request-Method",
			"Access-Control-Request-Private-Network",
		},
		AllowMethods: []string{
			http.MethodGet,
			http.MethodPost,
			http.MethodPatch,
			http.MethodPut,
			http.MethodDelete,
			http.MethodOptions,
		},
		ExposeHeaders:    []string{mw.HeaderCorrelationID, "X-Total-Count"},
		AllowCredentials: true,
		MaxAge:           86400,
	}))

	// Error handler centralizado
	e.HTTPErrorHandler = mw.ErrorHandler(log)

	// ─── Validador ────────────────────────────────────────────
	e.Validator = newValidator()

	// ─── Rutas ───────────────────────────────────────────────
	api := e.Group("/api/v1")

	// Métricas y Observabilidad (pública, US-PLT-05 AC-01, RNF-PER-003)
	collector := metrics.NewCollector()
	e.Use(mw.MetricsMiddleware(collector))
	// CA-010: todo 403 por ámbito queda en la bitácora de auditoría.
	e.Use(mw.AuditarAmbitoDenegado(auditoria))
	metricsH := handler.NewMetricsHandler(collector)
	api.GET("/metrics", metricsH.GetMetrics)
	registry.MarkPublic(http.MethodGet, "/api/v1/metrics")

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
	authGroup.POST("/totp/verificar", authH.VerificarTOTP)
	registry.MarkPublic(http.MethodPost, "/api/v1/auth/totp/verificar")

	// Autenticación (requiere token válido y tasa de 120 req/min por usuario — US-AUT-02 AC-04)
	authProtected := api.Group("/auth", mw.JWTAuth(cfg), mw.RateLimiterByUser(120))
	authProtected.POST("/logout", authH.Logout)
	registry.MarkPublic(http.MethodPost, "/api/v1/auth/logout")
	authProtected.POST("/devices", authH.RegistrarDispositivo)
	registry.MarkPublic(http.MethodPost, "/api/v1/auth/devices")
	authProtected.POST("/contexto", authH.CambiarContexto)
	registry.MarkPublic(http.MethodPost, "/api/v1/auth/contexto")
	authProtected.POST("/totp/setup", authH.SetupTOTP)
	registry.MarkPublic(http.MethodPost, "/api/v1/auth/totp/setup")
	authProtected.POST("/totp/activar", authH.ActivarTOTP)
	registry.MarkPublic(http.MethodPost, "/api/v1/auth/totp/activar")

	registerUsuarioRoutes(api, cfg, auditoria, registry, authH, usuariosH)

	// Roles y permisos del sistema — US-ROL-01 AC-01, US-ROL-03 AC-01..05
	if rolesH != nil {
		rolesProtected := api.Group("/roles", mw.JWTAuth(cfg), mw.RateLimiterByUser(120))
		rolesProtected.GET("", rolesH.ListarRoles, mw.RequirePermission(rbac.PermRolLeer, auditoria))
		registry.RegisterPermission(http.MethodGet, "/api/v1/roles", rbac.PermRolLeer)
		rolesProtected.POST("", rolesH.CrearRol, mw.RequirePermission(rbac.PermRolCrear, auditoria))
		registry.RegisterPermission(http.MethodPost, "/api/v1/roles", rbac.PermRolCrear)
		rolesProtected.PUT("/:id", rolesH.ActualizarRol, mw.RequirePermission(rbac.PermRolEditar, auditoria))
		registry.RegisterPermission(http.MethodPut, "/api/v1/roles/:id", rbac.PermRolEditar)
		rolesProtected.DELETE("/:id", rolesH.EliminarRol, mw.RequirePermission(rbac.PermRolEliminar, auditoria))
		registry.RegisterPermission(http.MethodDelete, "/api/v1/roles/:id", rbac.PermRolEliminar)
	}

	// ─── Jerarquía física y cartografía — US-GEO-01 ──────────
	if geoH != nil {
		// Sedes
		sedesProtected := api.Group("/sedes", mw.JWTAuth(cfg), mw.RateLimiterByUser(120))
		sedesProtected.GET("", geoH.ListarSedes, mw.RequirePermission(rbac.PermAulaLeer, auditoria))
		registry.RegisterPermission(http.MethodGet, "/api/v1/sedes", rbac.PermAulaLeer)
		sedesProtected.POST("", geoH.CrearSede, mw.RequirePermission(rbac.PermSedeAdministrar, auditoria))
		registry.RegisterPermission(http.MethodPost, "/api/v1/sedes", rbac.PermSedeAdministrar)
		sedesProtected.GET("/:id", geoH.ObtenerSede, mw.RequirePermission(rbac.PermAulaLeer, auditoria))
		registry.RegisterPermission(http.MethodGet, "/api/v1/sedes/:id", rbac.PermAulaLeer)

		// Bloques
		bloquesProtected := api.Group("/bloques", mw.JWTAuth(cfg), mw.RateLimiterByUser(120))
		bloquesProtected.GET("", geoH.ListarBloques, mw.RequirePermission(rbac.PermAulaLeer, auditoria))
		registry.RegisterPermission(http.MethodGet, "/api/v1/bloques", rbac.PermAulaLeer)
		bloquesProtected.POST("", geoH.CrearBloque, mw.RequirePermission(rbac.PermBloqueAdministrar, auditoria))
		registry.RegisterPermission(http.MethodPost, "/api/v1/bloques", rbac.PermBloqueAdministrar)
		bloquesProtected.GET("/:id", geoH.ObtenerBloque, mw.RequirePermission(rbac.PermAulaLeer, auditoria))
		registry.RegisterPermission(http.MethodGet, "/api/v1/bloques/:id", rbac.PermAulaLeer)
		bloquesProtected.POST("/:id/clonar-piso", geoH.ClonarPiso, mw.RequirePermission(rbac.PermAulaCrear, auditoria))
		registry.RegisterPermission(http.MethodPost, "/api/v1/bloques/:id/clonar-piso", rbac.PermAulaCrear)

		// Espacios
		espaciosProtected := api.Group("/espacios", mw.JWTAuth(cfg), mw.RateLimiterByUser(120))
		espaciosProtected.GET("", geoH.ListarEspacios, mw.RequirePermission(rbac.PermAulaLeer, auditoria))
		registry.RegisterPermission(http.MethodGet, "/api/v1/espacios", rbac.PermAulaLeer)
		espaciosProtected.GET("/exportar", geoH.ExportarGeoJSON, mw.RequirePermission(rbac.PermAulaLeer, auditoria))
		registry.RegisterPermission(http.MethodGet, "/api/v1/espacios/exportar", rbac.PermAulaLeer)
		espaciosProtected.POST("/importar/preview", geoH.PreviewImportarGeoJSON, mw.RequirePermission(rbac.PermAulaCrear, auditoria))
		registry.RegisterPermission(http.MethodPost, "/api/v1/espacios/importar/preview", rbac.PermAulaCrear)
		espaciosProtected.POST("/importar", geoH.ConfirmarImportarGeoJSON, mw.RequirePermission(rbac.PermAulaCrear, auditoria))
		registry.RegisterPermission(http.MethodPost, "/api/v1/espacios/importar", rbac.PermAulaCrear)
		espaciosProtected.GET("/solapamientos", geoH.InformeSolapamientos, mw.RequirePermission(rbac.PermAulaLeer, auditoria))
		registry.RegisterPermission(http.MethodGet, "/api/v1/espacios/solapamientos", rbac.PermAulaLeer)
		espaciosProtected.POST("", geoH.CrearEspacio, mw.RequirePermission(rbac.PermAulaCrear, auditoria))
		registry.RegisterPermission(http.MethodPost, "/api/v1/espacios", rbac.PermAulaCrear)
		espaciosProtected.GET("/:id", geoH.ObtenerEspacio, mw.RequirePermission(rbac.PermAulaLeer, auditoria))
		registry.RegisterPermission(http.MethodGet, "/api/v1/espacios/:id", rbac.PermAulaLeer)
		espaciosProtected.PATCH("/:id", geoH.ActualizarEspacio, mw.RequirePermission(rbac.PermAulaEditar, auditoria))
		registry.RegisterPermission(http.MethodPatch, "/api/v1/espacios/:id", rbac.PermAulaEditar)
		espaciosProtected.PATCH("/:id/buffer", geoH.ActualizarBuffer, mw.RequirePermission(rbac.PermAulaEditar, auditoria))
		registry.RegisterPermission(http.MethodPatch, "/api/v1/espacios/:id/buffer", rbac.PermAulaEditar)
		espaciosProtected.PUT("/:id/geometria", geoH.ActualizarGeometria, mw.RequirePermission(rbac.PermAulaEditarGeometria, auditoria))
		registry.RegisterPermission(http.MethodPut, "/api/v1/espacios/:id/geometria", rbac.PermAulaEditarGeometria)
		espaciosProtected.GET("/:id/geometria/versiones", geoH.ListarVersionesGeometria, mw.RequirePermission(rbac.PermAulaLeer, auditoria))
		registry.RegisterPermission(http.MethodGet, "/api/v1/espacios/:id/geometria/versiones", rbac.PermAulaLeer)
		espaciosProtected.GET("/:id/geometria/versiones/:version", geoH.ObtenerVersionGeometria, mw.RequirePermission(rbac.PermAulaLeer, auditoria))
		registry.RegisterPermission(http.MethodGet, "/api/v1/espacios/:id/geometria/versiones/:version", rbac.PermAulaLeer)
		espaciosProtected.POST("/validar-geometria", geoH.ValidarGeometria, mw.RequirePermission(rbac.PermAulaLeer, auditoria))
		registry.RegisterPermission(http.MethodPost, "/api/v1/espacios/validar-geometria", rbac.PermAulaLeer)
		espaciosProtected.DELETE("/:id", geoH.EliminarEspacio, mw.RequirePermission(rbac.PermAulaEliminar, auditoria))
		registry.RegisterPermission(http.MethodDelete, "/api/v1/espacios/:id", rbac.PermAulaEliminar)
	}

	registerAcademicoRoutes(api, cfg, auditoria, registry, acaH)

	// ─── Parametrización jerárquica — EP-05, US-PAR-01, US-PAR-03 ─────
	if parametroH != nil {
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

	// ─── Motor de marcaje — EP-06 (US-MAR-01..15) ─────────────
	registerMarcajeRoutes(api, cfg, auditoria, registry, marcajeH, marcajeAdminH, marcajeSyncH)

	// ─── Justificaciones, reportes y bitácora — EP-07, EP-08, RF-AUD-003 ─────
	registerSeguimientoRoutes(api, cfg, auditoria, registry, seguimiento)

	// ─── Verificación al arranque — T-ROL-01.4, AC-03 ─────────
	// Toda ruta bajo /api/v1 DEBE declarar su permiso o estar explícitamente marcada como pública.
	if err := registry.VerifyAllRoutes(e); err != nil {
		return nil, err
	}

	return e, nil
}
