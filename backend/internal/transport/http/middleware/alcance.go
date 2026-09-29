// Package middleware — alcance efectivo del usuario autenticado (RF-ROL-003, CA-010).
package middleware

import (
	"time"

	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/repository"
)

// AlcanceDe calcula el alcance del usuario del token. Sin token el alcance es vacío (no ve nada).
func AlcanceDe(c echo.Context) rbac.Alcance {
	claims, ok := GetClaims(c)
	if !ok {
		return rbac.Alcance{}
	}
	perms := make([]rbac.Permission, len(claims.Permisos))
	for i, p := range claims.Permisos {
		perms[i] = rbac.Permission(p)
	}
	return rbac.NuevoAlcance(claims.RolActivo, perms, claims.UsuarioID, claims.Ambitos)
}

// FiltroAlcanceDe traduce el alcance del usuario al filtro de consulta de repositorio.
func FiltroAlcanceDe(c echo.Context) *repository.FiltroAlcance {
	return repository.FiltroDeAlcance(AlcanceDe(c))
}

// AuditarAmbitoDenegado registra en la bitácora cada respuesta 403 por ámbito (CA-010):
// cualquier handler o caso de uso que devuelva ErrAmbitoDenegado queda auditado aquí.
func AuditarAmbitoDenegado(auditoria repository.AuditoriaRepository) echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			err := next(c)
			de, ok := shared.AsDomainError(err)
			if !ok || de.Code != shared.ErrAmbitoDenegado || auditoria == nil {
				return err
			}
			entrada := &repository.AuditEntry{
				ID:            shared.NewID(),
				Entidad:       "autorizacion",
				Accion:        "AMBITO_DENEGADO",
				CorrelationID: c.Response().Header().Get(HeaderCorrelationID),
				IPOrigen:      c.RealIP(),
				AgenteUsuario: c.Request().UserAgent(),
				ValorNuevo: map[string]string{
					"ruta":    c.Path(),
					"url":     c.Request().URL.String(),
					"metodo":  c.Request().Method,
					"mensaje": de.Message,
				},
				CreadoEn: time.Now().UTC(),
			}
			if claims, ok := GetClaims(c); ok {
				entrada.EntidadID = claims.UsuarioID
				entrada.ActorID = claims.UsuarioID
				entrada.RolActivo = claims.RolActivo
			}
			_ = auditoria.Create(c.Request().Context(), entrada)
			return err
		}
	}
}
