// Package middleware — Control de acceso basado en atributos y ámbitos (ABAC).
// Satisface US-ROL-02, AC-02..AC-06 y RF-ROL-003.
package middleware

import (
	"fmt"

	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/usecase/auth"
)

// AccesoTotal indica si el usuario del token opera sin restricción de ámbito. Solo los roles
// institucionales (superadministrador, administrador institucional, auditor) la tienen; una
// lista de ámbitos vacía en cualquier otro rol significa que no ve nada (AC-06).
func AccesoTotal(claims *auth.JWTClaims) bool {
	return claims != nil && rbac.EsRolGlobal(claims.RolActivo)
}

// ErrorAmbito construye el 403 auditado por acceso a un recurso fuera del ámbito (AC-02, CA-010).
func ErrorAmbito(recursoID string) error {
	return shared.NewAuthError(
		shared.ErrAmbitoDenegado,
		fmt.Sprintf("Acceso denegado: no tiene autorización sobre el recurso %s", recursoID),
	)
}

// ValidateResourceScope verifica si un recurso puntual ya cargado pertenece al ámbito del
// usuario autenticado. Sin ámbitos y sin rol institucional, el acceso se niega.
func ValidateResourceScope(claims *auth.JWTClaims, scopeType rbac.ScopeType, resourceID string) error {
	if claims == nil || AccesoTotal(claims) {
		return nil
	}
	if !rbac.IsInScope(claims.Ambitos, scopeType, resourceID) {
		return ErrorAmbito(resourceID)
	}
	return nil
}
