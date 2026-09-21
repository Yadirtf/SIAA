// Package middleware — propagación del X-Correlation-Id.
// T-PLT-01.3: cada request lleva un ID único para trazabilidad end-to-end.
package middleware

import (
	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
)

// CorrelationID agrega o propaga el header X-Correlation-Id en cada petición.
// Si el cliente envía uno, se conserva; si no, se genera uno nuevo con UUID v4.
func CorrelationID() echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			id := c.Request().Header.Get(HeaderCorrelationID)
			if id == "" {
				id = uuid.New().String()
			}
			c.Set(CtxCorrelationID, id)
			c.Response().Header().Set(HeaderCorrelationID, id)
			return next(c)
		}
	}
}
