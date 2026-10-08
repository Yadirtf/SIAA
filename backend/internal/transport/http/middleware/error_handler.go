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
	Contexto      map[string]string   `json:"contexto,omitempty"`
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
				Contexto:      de.Contexto,
				CorrelationID: correlationID,
			})
			return
		}

		// Error HTTP de Echo (404, 405, etc.)
		if he, ok := err.(*echo.HTTPError); ok {
			_ = c.JSON(he.Code, errorResponse{
				Codigo:        codigoPorEstadoHTTP(he.Code),
				Mensaje:       mensajeHTTPError(he),
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
	case shared.ErrPermisosDenegados, shared.ErrAmbitoDenegado, shared.ErrUsuarioInactivo, shared.ErrConsentimientoRequerido:
		return http.StatusForbidden
	case shared.ErrValidacion, shared.ErrGeometriaInvalida:
		return http.StatusUnprocessableEntity
	case shared.ErrRecursoNoEncontrado:
		return http.StatusNotFound
	case shared.ErrConflictoHorario, shared.ErrConflictoUnicidad, shared.ErrGeometriaSolapada,
		shared.ErrEstadoInvalido, shared.ErrConfirmacionRequerida:
		return http.StatusConflict
	case shared.ErrLimiteTasa:
		return http.StatusTooManyRequests
	default:
		return http.StatusInternalServerError
	}
}

// mensajeHTTPError conserva el mensaje explicativo de los errores 4xx (p. ej. el detalle de una
// colisión de horario, RF-ACA-005) para que el cliente pueda mostrar qué pasó y qué hacer
// (RNF-USA-005). Los 5xx nunca exponen detalles internos.
func mensajeHTTPError(he *echo.HTTPError) string {
	if he.Code < http.StatusInternalServerError {
		if msg, ok := he.Message.(string); ok && msg != "" {
			return msg
		}
	}
	return http.StatusText(he.Code)
}

// codigoPorEstadoHTTP traduce el estado HTTP al código del catálogo §9.2 más cercano.
func codigoPorEstadoHTTP(status int) string {
	switch status {
	case http.StatusBadRequest, http.StatusUnprocessableEntity:
		return string(shared.ErrValidacion)
	case http.StatusUnauthorized:
		return string(shared.ErrTokenExpirado)
	case http.StatusForbidden:
		return string(shared.ErrPermisosDenegados)
	case http.StatusNotFound:
		return string(shared.ErrRecursoNoEncontrado)
	case http.StatusConflict:
		return string(shared.ErrConflictoUnicidad)
	case http.StatusTooManyRequests:
		return string(shared.ErrLimiteTasa)
	default:
		return "ERROR_HTTP"
	}
}
