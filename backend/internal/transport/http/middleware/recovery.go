// Package middleware — recuperación de pánico con respuesta 500 estructurada.
// Evita que un panic en un handler derrumbe todo el servidor.
package middleware

import (
	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/domain/shared"
	applog "github.com/siaa/backend/internal/platform/log"
)

// Recovery recupera de pánicos y devuelve un error 500 estructurado.
// Loguea el panic con el correlationId para facilitar el debugging.
func Recovery(log *applog.Logger) echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) (returnErr error) {
			defer func() {
				if r := recover(); r != nil {
					correlationID, _ := c.Get(CtxCorrelationID).(string)
					log.Error("panic recuperado",
						applog.Extra(r),
						applog.CorrelationID(correlationID),
					)
					returnErr = &shared.DomainError{
						Code:    shared.ErrInterno,
						Message: "Error interno del servidor",
					}
				}
			}()
			return next(c)
		}
	}
}
