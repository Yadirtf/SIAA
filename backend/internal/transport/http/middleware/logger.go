// Package middleware — logging estructurado de peticiones HTTP.
// T-PLT-01.4, RNF-MAN-005: una línea de log JSON por petición con métrica de latencia.
package middleware

import (
	"time"

	"github.com/labstack/echo/v4"

	applog "github.com/siaa/backend/internal/platform/log"
)

// RequestLogger emite una línea de log estructurado JSON por petición HTTP.
// Incluye: método, path, status, latencia, correlationId y usuarioId.
func RequestLogger(log *applog.Logger) echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			start := time.Now()

			err := next(c)

			correlationID, _ := c.Get(CtxCorrelationID).(string)
			usuarioID, _ := c.Get(CtxUsuarioID).(string)

			duration := time.Since(start).Milliseconds()
			status := c.Response().Status
			if err != nil {
				if he, ok := err.(*echo.HTTPError); ok {
					status = he.Code
				}
			}

			log.Info("request",
				applog.CorrelationID(correlationID),
				applog.UsuarioID(usuarioID),
				applog.Method(c.Request().Method),
				applog.Path(c.Request().URL.Path),
				applog.Status(status),
				applog.DurationMs(duration),
			)

			return err
		}
	}
}
