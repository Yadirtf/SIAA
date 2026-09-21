// Package middleware — control de acceso basado en roles.
// T-ROL-01.3, T-ROL-01.4, T-ROL-01.6: verifica permisos y audita accesos denegados.
package middleware

import (
	"time"

	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/repository"
)

// RequirePermission verifica que el usuario autenticado tenga el permiso requerido.
// Si no tiene el permiso, deniega con 403 y audita el intento (AC-02, T-ROL-01.6).
func RequirePermission(perm rbac.Permission, auditoria repository.AuditoriaRepository) echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			claims, ok := GetClaims(c)
			if !ok {
				return shared.NewAuthError(shared.ErrTokenExpirado, "Autenticación requerida")
			}

			userPerms := make([]rbac.Permission, len(claims.Permisos))
			for i, p := range claims.Permisos {
				userPerms[i] = rbac.Permission(p)
			}

			if !rbac.HasPermission(userPerms, perm) {
				// Auditoría obligatoria de intento denegado — AC-02, T-ROL-01.6
				if auditoria != nil {
					_ = auditoria.Create(c.Request().Context(), &repository.AuditEntry{
						ID:            shared.NewID(),
						Entidad:       "autorizacion",
						EntidadID:     claims.UsuarioID,
						Accion:        "ACCESO_DENEGADO",
						ActorID:       claims.UsuarioID,
						RolActivo:     claims.RolActivo,
						CorrelationID: c.Response().Header().Get(HeaderCorrelationID),
						IPOrigen:      c.RealIP(),
						AgenteUsuario: c.Request().UserAgent(),
						ValorNuevo: map[string]string{
							"permiso_requerido": string(perm),
							"ruta":              c.Path(),
							"metodo":            c.Request().Method,
						},
						CreadoEn: time.Now().UTC(),
					})
				}
				return shared.NewPermissionError()
			}

			return next(c)
		}
	}
}
