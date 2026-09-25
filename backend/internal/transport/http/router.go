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
			for _, allowed := range cfg.CORSAllowedOrigins {
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
		ExposeHeaders:    []string{mw.HeaderCorrelationID},
		AllowCredentials: true,
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
	authProtected.POST("/devices", authH.RegistrarDispositivo)
	registry.MarkPublic(http.MethodPost, "/api/v1/auth/devices")

	// Administración de usuarios (requiere token válido y tasa de 120 req/min por usuario)
	usuariosProtected := api.Group("/usuarios", mw.JWTAuth(cfg), mw.RateLimiterByUser(120))
	// Desbloqueo administrativo auditado (US-AUT-02 AC-02, T-AUT-02.3)
	usuariosProtected.POST("/:id/desbloquear", authH.DesbloquearUsuario, mw.RequirePermission(rbac.PermUsuarioEditar, auditoria))
	registry.RegisterPermission(http.MethodPost, "/api/v1/usuarios/:id/desbloquear", rbac.PermUsuarioEditar)
	usuariosProtected.GET("/:id/dispositivos", authH.ListarDispositivosUsuario, mw.RequirePermission(rbac.PermUsuarioLeer, auditoria))
	registry.RegisterPermission(http.MethodGet, "/api/v1/usuarios/:id/dispositivos", rbac.PermUsuarioLeer)

	// Gestión de dispositivos confiables (US-AUT-03)
	dispositivosProtected := api.Group("/dispositivos", mw.JWTAuth(cfg), mw.RateLimiterByUser(120))
	dispositivosProtected.POST("/:id/aprobar", authH.AprobarDispositivo, mw.RequirePermission(rbac.PermUsuarioEditar, auditoria))
	registry.RegisterPermission(http.MethodPost, "/api/v1/dispositivos/:id/aprobar", rbac.PermUsuarioEditar)
	dispositivosProtected.POST("/:id/revocar", authH.RevocarDispositivo, mw.RequirePermission(rbac.PermUsuarioEditar, auditoria))
	registry.RegisterPermission(http.MethodPost, "/api/v1/dispositivos/:id/revocar", rbac.PermUsuarioEditar)

	// Roles y permisos del sistema — US-ROL-01 AC-01
	if rolesH != nil {
		rolesProtected := api.Group("/roles", mw.JWTAuth(cfg), mw.RateLimiterByUser(120))
		rolesProtected.GET("", rolesH.ListarRoles, mw.RequirePermission(rbac.PermRolLeer, auditoria))
		registry.RegisterPermission(http.MethodGet, "/api/v1/roles", rbac.PermRolLeer)
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

		// Espacios
		espaciosProtected := api.Group("/espacios", mw.JWTAuth(cfg), mw.RateLimiterByUser(120))
		espaciosProtected.GET("", geoH.ListarEspacios, mw.RequirePermission(rbac.PermAulaLeer, auditoria))
		registry.RegisterPermission(http.MethodGet, "/api/v1/espacios", rbac.PermAulaLeer)
		espaciosProtected.GET("/solapamientos", geoH.InformeSolapamientos, mw.RequirePermission(rbac.PermAulaLeer, auditoria))
		registry.RegisterPermission(http.MethodGet, "/api/v1/espacios/solapamientos", rbac.PermAulaLeer)
		espaciosProtected.POST("", geoH.CrearEspacio, mw.RequirePermission(rbac.PermAulaCrear, auditoria))
		registry.RegisterPermission(http.MethodPost, "/api/v1/espacios", rbac.PermAulaCrear)
		espaciosProtected.GET("/:id", geoH.ObtenerEspacio, mw.RequirePermission(rbac.PermAulaLeer, auditoria))
		registry.RegisterPermission(http.MethodGet, "/api/v1/espacios/:id", rbac.PermAulaLeer)
		espaciosProtected.PATCH("/:id", geoH.ActualizarEspacio, mw.RequirePermission(rbac.PermAulaEditar, auditoria))
		registry.RegisterPermission(http.MethodPatch, "/api/v1/espacios/:id", rbac.PermAulaEditar)
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

	// ─── Estructura académica, horarios y asignaciones — EP-04 ──
	if acaH != nil {
		// Periodos (US-ACA-01)
		periodos := api.Group("/periodos", mw.JWTAuth(cfg), mw.RateLimiterByUser(120))
		periodos.GET("", acaH.ListarPeriodos, mw.RequirePermission(rbac.PermHorarioLeer, auditoria))
		registry.RegisterPermission(http.MethodGet, "/api/v1/periodos", rbac.PermHorarioLeer)
		periodos.POST("", acaH.CrearPeriodo, mw.RequirePermission(rbac.PermHorarioCrear, auditoria))
		registry.RegisterPermission(http.MethodPost, "/api/v1/periodos", rbac.PermHorarioCrear)
		periodos.GET("/:id", acaH.ObtenerPeriodo, mw.RequirePermission(rbac.PermHorarioLeer, auditoria))
		registry.RegisterPermission(http.MethodGet, "/api/v1/periodos/:id", rbac.PermHorarioLeer)
		periodos.PUT("/:id", acaH.ActualizarPeriodo, mw.RequirePermission(rbac.PermHorarioCrear, auditoria))
		registry.RegisterPermission(http.MethodPut, "/api/v1/periodos/:id", rbac.PermHorarioCrear)

		// Facultades
		facultades := api.Group("/facultades", mw.JWTAuth(cfg), mw.RateLimiterByUser(120))
		facultades.GET("", acaH.ListarFacultades, mw.RequirePermission(rbac.PermHorarioLeer, auditoria))
		registry.RegisterPermission(http.MethodGet, "/api/v1/facultades", rbac.PermHorarioLeer)
		facultades.POST("", acaH.CrearFacultad, mw.RequirePermission(rbac.PermHorarioCrear, auditoria))
		registry.RegisterPermission(http.MethodPost, "/api/v1/facultades", rbac.PermHorarioCrear)
		facultades.DELETE("/:id", acaH.EliminarFacultad, mw.RequirePermission(rbac.PermHorarioCrear, auditoria))
		registry.RegisterPermission(http.MethodDelete, "/api/v1/facultades/:id", rbac.PermHorarioCrear)

		// Programas
		programas := api.Group("/programas", mw.JWTAuth(cfg), mw.RateLimiterByUser(120))
		programas.GET("", acaH.ListarProgramas, mw.RequirePermission(rbac.PermHorarioLeer, auditoria))
		registry.RegisterPermission(http.MethodGet, "/api/v1/programas", rbac.PermHorarioLeer)
		programas.POST("", acaH.CrearPrograma, mw.RequirePermission(rbac.PermHorarioCrear, auditoria))
		registry.RegisterPermission(http.MethodPost, "/api/v1/programas", rbac.PermHorarioCrear)
		programas.DELETE("/:id", acaH.EliminarPrograma, mw.RequirePermission(rbac.PermHorarioCrear, auditoria))
		registry.RegisterPermission(http.MethodDelete, "/api/v1/programas/:id", rbac.PermHorarioCrear)

		// Asignaturas
		asignaturas := api.Group("/asignaturas", mw.JWTAuth(cfg), mw.RateLimiterByUser(120))
		asignaturas.GET("", acaH.ListarAsignaturas, mw.RequirePermission(rbac.PermHorarioLeer, auditoria))
		registry.RegisterPermission(http.MethodGet, "/api/v1/asignaturas", rbac.PermHorarioLeer)
		asignaturas.POST("", acaH.CrearAsignatura, mw.RequirePermission(rbac.PermHorarioCrear, auditoria))
		registry.RegisterPermission(http.MethodPost, "/api/v1/asignaturas", rbac.PermHorarioCrear)
		asignaturas.DELETE("/:id", acaH.EliminarAsignatura, mw.RequirePermission(rbac.PermHorarioCrear, auditoria))
		registry.RegisterPermission(http.MethodDelete, "/api/v1/asignaturas/:id", rbac.PermHorarioCrear)

		// Grupos
		grupos := api.Group("/grupos", mw.JWTAuth(cfg), mw.RateLimiterByUser(120))
		grupos.GET("", acaH.ListarGrupos, mw.RequirePermission(rbac.PermHorarioLeer, auditoria))
		registry.RegisterPermission(http.MethodGet, "/api/v1/grupos", rbac.PermHorarioLeer)
		grupos.POST("", acaH.CrearGrupo, mw.RequirePermission(rbac.PermHorarioCrear, auditoria))
		registry.RegisterPermission(http.MethodPost, "/api/v1/grupos", rbac.PermHorarioCrear)
		grupos.DELETE("/:id", acaH.EliminarGrupo, mw.RequirePermission(rbac.PermHorarioCrear, auditoria))
		registry.RegisterPermission(http.MethodDelete, "/api/v1/grupos/:id", rbac.PermHorarioCrear)

		// Asignaciones (US-ACA-03)
		asignaciones := api.Group("/asignaciones", mw.JWTAuth(cfg), mw.RateLimiterByUser(120))
		asignaciones.GET("", acaH.ListarAsignaciones, mw.RequirePermission(rbac.PermHorarioLeer, auditoria))
		registry.RegisterPermission(http.MethodGet, "/api/v1/asignaciones", rbac.PermHorarioLeer)
		asignaciones.POST("", acaH.CrearAsignacion, mw.RequirePermission(rbac.PermAsignacionCrear, auditoria))
		registry.RegisterPermission(http.MethodPost, "/api/v1/asignaciones", rbac.PermAsignacionCrear)
		asignaciones.DELETE("/:id", acaH.EliminarAsignacion, mw.RequirePermission(rbac.PermAsignacionCrear, auditoria))
		registry.RegisterPermission(http.MethodDelete, "/api/v1/asignaciones/:id", rbac.PermAsignacionCrear)

		// Calendario de Excepciones (US-ACA-04)
		excepciones := api.Group("/calendario-excepciones", mw.JWTAuth(cfg), mw.RateLimiterByUser(120))
		excepciones.GET("", acaH.ListarExcepciones, mw.RequirePermission(rbac.PermHorarioLeer, auditoria))
		registry.RegisterPermission(http.MethodGet, "/api/v1/calendario-excepciones", rbac.PermHorarioLeer)
		excepciones.POST("", acaH.CrearExcepcion, mw.RequirePermission(rbac.PermHorarioCrear, auditoria))
		registry.RegisterPermission(http.MethodPost, "/api/v1/calendario-excepciones", rbac.PermHorarioCrear)
		excepciones.DELETE("/:id", acaH.EliminarExcepcion, mw.RequirePermission(rbac.PermHorarioCrear, auditoria))
		registry.RegisterPermission(http.MethodDelete, "/api/v1/calendario-excepciones/:id", rbac.PermHorarioCrear)
	}

	// ─── Verificación al arranque — T-ROL-01.4, AC-03 ─────────
	// Toda ruta bajo /api/v1 DEBE declarar su permiso o estar explícitamente marcada como pública.
	if err := registry.VerifyAllRoutes(e); err != nil {
		return nil, err
	}

	return e, nil
}
