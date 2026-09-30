package middleware

import (
	"context"

	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/domain/shared"
)

// VerificadorConsentimiento indica si el usuario aceptó la política de privacidad vigente.
type VerificadorConsentimiento func(ctx context.Context, usuarioID string) (bool, error)

// ExigirConsentimiento bloquea el registro de ubicación de quien no ha aceptado la política
// vigente (Ley 1581, US-LEG-01 AC-05). Con verificador nil no se aplica.
func ExigirConsentimiento(verificar VerificadorConsentimiento) echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			if verificar == nil {
				return next(c)
			}
			claims, ok := GetClaims(c)
			if !ok {
				return next(c)
			}
			acepto, err := verificar(c.Request().Context(), claims.UsuarioID)
			if err != nil {
				return err
			}
			if !acepto {
				return &shared.DomainError{
					Code:    shared.ErrConsentimientoRequerido,
					Message: "Debe aceptar el aviso de privacidad vigente antes de registrar marcajes con ubicación",
				}
			}
			return next(c)
		}
	}
}
