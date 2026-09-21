// Package middleware — control de acceso basado en roles.
// T-ROL-01.3, T-ROL-01.4: verifica que el usuario tenga el permiso declarado en la ruta.
package middleware

import (
	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/domain/shared"
)

// RequirePermission verifica que el usuario autenticado tenga el permiso requerido.
// Debe aplicarse DESPUÉS de JWTAuth en la cadena de middlewares.
// Si la ruta no declara permiso, el sistema lo detecta en arranque (T-ROL-01.4).
func RequirePermission(perm rbac.Permission) echo.MiddlewareFunc {
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
				return shared.NewPermissionError()
			}

			return next(c)
		}
	}
}
