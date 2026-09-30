// Package middleware — Middleware de instrumentación y telemetría HTTP.
// Satisface US-PLT-05, AC-01 y RNF-PER-003.
package middleware

import (
	"fmt"
	"time"

	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/platform/metrics"
)

// MetricsMiddleware retorna un middleware Echo que registra duración y códigos de estado en el colector.
func MetricsMiddleware(collector *metrics.Collector) echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			start := time.Now()
			err := next(c)
			duration := time.Since(start)

			routePath := c.Path()
			if routePath == "" {
				routePath = c.Request().URL.Path
			}
			routeKey := fmt.Sprintf("%s %s", c.Request().Method, routePath)

			status := c.Response().Status
			isError := status >= 400 || err != nil

			collector.RecordRequest(routeKey, duration, isError)

			return err
		}
	}
}
