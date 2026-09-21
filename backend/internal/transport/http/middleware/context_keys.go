// Package middleware — claves de contexto compartidas entre todos los middlewares.
// Centralizar estas constantes evita errores de typo al leer el contexto de Echo.
package middleware

// Claves de cabecera HTTP
const (
	HeaderCorrelationID = "X-Correlation-Id"
)

// Claves del contexto de Echo (c.Get / c.Set)
const (
	CtxCorrelationID = "correlationId"
	CtxUsuarioID     = "usuarioId"
	CtxClaims        = "jwtClaims"
)
