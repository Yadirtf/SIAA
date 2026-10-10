// Package middleware — metadatos de origen de cada petición para la bitácora.
// US-AUD-01 AC-02 y AC-04: la IP, el agente de usuario y la sesión se capturan una sola vez,
// de forma transversal, y el registrador de auditoría los añade a cada entrada.
package middleware

import (
	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/platform/auditctx"
)

// MetadatosAuditoria deja en el contexto de la petición su IP (vía el IPExtractor del router,
// que solo confía en X-Forwarded-For desde la red privada), el agente de usuario y el
// correlationId. Debe registrarse después de CorrelationID.
func MetadatosAuditoria() echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			correlationID, _ := c.Get(CtxCorrelationID).(string)
			md := &auditctx.Metadatos{
				IP:            c.RealIP(),
				AgenteUsuario: c.Request().UserAgent(),
				CorrelationID: correlationID,
			}
			c.SetRequest(c.Request().WithContext(auditctx.Con(c.Request().Context(), md)))
			return next(c)
		}
	}
}

// fijarSesionAuditoria registra el actor y el rol activo una vez validado el token.
func fijarSesionAuditoria(c echo.Context, usuarioID, rolActivo string) {
	if md := auditctx.De(c.Request().Context()); md != nil {
		md.FijarSesion(usuarioID, rolActivo)
	}
}
