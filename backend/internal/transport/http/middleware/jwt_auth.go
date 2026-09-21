// Package middleware — autenticación JWT Bearer.
// T-AUT-01.6: verifica el token de acceso y carga los claims en el contexto de Echo.
package middleware

import (
	"strings"

	"github.com/golang-jwt/jwt/v5"
	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/platform/config"
	"github.com/siaa/backend/internal/usecase/auth"
)

// JWTAuth verifica el token de acceso Bearer y carga los claims en el contexto.
// Cualquier ruta protegida debe aplicar este middleware antes de RequirePermission.
func JWTAuth(cfg *config.Config) echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			header := c.Request().Header.Get("Authorization")
			if !strings.HasPrefix(header, "Bearer ") {
				return shared.NewAuthError(shared.ErrTokenExpirado, "Token de acceso requerido")
			}
			rawToken := strings.TrimPrefix(header, "Bearer ")

			claims := &auth.JWTClaims{}
			token, err := jwt.ParseWithClaims(rawToken, claims, func(t *jwt.Token) (interface{}, error) {
				if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
					return nil, echo.ErrUnauthorized
				}
				return []byte(cfg.JWTSecret), nil
			})

			if err != nil || !token.Valid {
				if err != nil && strings.Contains(err.Error(), "expired") {
					return shared.NewAuthError(shared.ErrTokenExpirado, "Token de acceso expirado")
				}
				return shared.NewAuthError(shared.ErrTokenRevocado, "Token de acceso inválido")
			}

			c.Set(CtxClaims, claims)
			c.Set(CtxUsuarioID, claims.UsuarioID)
			return next(c)
		}
	}
}

// GetClaims extrae los claims JWT del contexto de Echo.
// Retorna false si el usuario no está autenticado.
func GetClaims(c echo.Context) (*auth.JWTClaims, bool) {
	claims, ok := c.Get(CtxClaims).(*auth.JWTClaims)
	return claims, ok
}
