// Package http configura el enrutador principal y registra todas las rutas.
// T-PLT-01.3, T-ROL-01.4: toda ruta debe declarar su permiso o ser marcada pública.
package http

import (
	"net/http"
	"time"

	"github.com/labstack/echo/v4"
	echoMiddleware "github.com/labstack/echo/v4/middleware"

	"github.com/siaa/backend/internal/platform/config"
	applog "github.com/siaa/backend/internal/platform/log"
	"github.com/siaa/backend/internal/transport/http/handler"
	mw "github.com/siaa/backend/internal/transport/http/middleware"
)

// NewRouter crea y configura el servidor Echo con todos los middlewares y rutas.
func NewRouter(
	cfg *config.Config,
	log *applog.Logger,
	health *handler.HealthHandler,
	authH *handler.AuthHandler,
) *echo.Echo {
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

	// Salud (públicas, sin autenticación)
	api.GET("/health", health.Health)
	api.GET("/health/ready", health.Ready)

	// Autenticación (públicas)
	authGroup := api.Group("/auth")
	authGroup.Use(mw.RateLimiter(cfg.RateLimitPerMinute))
	authGroup.POST("/login", authH.Login)
	authGroup.POST("/refresh", authH.Refresh)
	authGroup.POST("/recuperar", authH.SolicitarRecuperacion)
	authGroup.POST("/recuperar/confirmar", authH.ConfirmarRecuperacion)

	// Autenticación (requiere token válido)
	authProtected := api.Group("/auth", mw.JWTAuth(cfg))
	authProtected.POST("/logout", authH.Logout)

	// TODO Sprint 2+: registrar aquí el resto de rutas con sus permisos
	// Cada ruta DEBE declarar RequirePermission(perm) o ser marcada pública.
	// El router verifica en el arranque que no quede ninguna ruta sin declarar.

	return e
}
