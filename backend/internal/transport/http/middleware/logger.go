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
			status := estadoFinal(c, err)

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

// estadoFinal es el estado que recibe el cliente: si el handler devolvió un error que aún no
// se escribió, es el que asignará ErrorHandler (401, 403, 423, 429…), no el 200 por defecto.
func estadoFinal(c echo.Context, err error) int {
	if err != nil && !c.Response().Committed {
		return EstadoHTTP(err)
	}
	return c.Response().Status
}
