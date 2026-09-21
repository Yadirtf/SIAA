// Package middleware — manejador centralizado de errores HTTP.
// T-PLT-01.5, §9.2: mapea errores de dominio a respuestas HTTP sin exponer detalles internos.
package middleware

import (
	"net/http"

	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/domain/shared"
	applog "github.com/siaa/backend/internal/platform/log"
)

// errorResponse es el cuerpo de error normalizado §9.2.
type errorResponse struct {
	Codigo        string              `json:"codigo"`
	Mensaje       string              `json:"mensaje"`
	Detalles      []shared.FieldError `json:"detalles,omitempty"`
	CorrelationID string              `json:"correlationId"`
}

// ErrorHandler mapea errores de dominio a respuestas HTTP normalizadas.
// Nunca expone detalles de errores internos al cliente.
func ErrorHandler(log *applog.Logger) echo.HTTPErrorHandler {
	return func(err error, c echo.Context) {
		if c.Response().Committed {
			return
		}

		correlationID, _ := c.Get(CtxCorrelationID).(string)

		// Error de dominio tipado
		if de, ok := shared.AsDomainError(err); ok {
			status := domainErrorToHTTP(de.Code)
			_ = c.JSON(status, errorResponse{
				Codigo:        string(de.Code),
				Mensaje:       de.Message,
				Detalles:      de.Fields,
				CorrelationID: correlationID,
			})
			return
		}

		// Error HTTP de Echo (404, 405, etc.)
		if he, ok := err.(*echo.HTTPError); ok {
			_ = c.JSON(he.Code, errorResponse{
				Codigo:        "ERROR_HTTP",
				Mensaje:       http.StatusText(he.Code),
				CorrelationID: correlationID,
			})
			return
		}

		// Error inesperado: se loguea internamente pero NO se expone al cliente
		log.Error("error no controlado",
			applog.Err(err),
			applog.CorrelationID(correlationID),
		)
		_ = c.JSON(http.StatusInternalServerError, errorResponse{
			Codigo:        string(shared.ErrInterno),
			Mensaje:       "Se produjo un error interno. Referencia: " + correlationID,
			CorrelationID: correlationID,
		})
	}
}

// domainErrorToHTTP mapea códigos de error de dominio a códigos HTTP.
func domainErrorToHTTP(code shared.ErrorCode) int {
	switch code {
	case shared.ErrCredencialesInvalidas, shared.ErrTokenExpirado, shared.ErrTokenRevocado:
		return http.StatusUnauthorized
	case shared.ErrCuentaBloqueada:
		return 423 // Locked
	case shared.ErrDosFactorRequerido:
		return http.StatusUnauthorized
	case shared.ErrPermisosDenegados, shared.ErrAmbitoDenegado:
		return http.StatusForbidden
	case shared.ErrValidacion, shared.ErrGeometriaInvalida:
		return http.StatusUnprocessableEntity
	case shared.ErrRecursoNoEncontrado:
		return http.StatusNotFound
	case shared.ErrConflictoHorario, shared.ErrConflictoUnicidad, shared.ErrGeometriaSolapada:
		return http.StatusConflict
	case shared.ErrLimiteTasa:
		return http.StatusTooManyRequests
	default:
		return http.StatusInternalServerError
	}
}
