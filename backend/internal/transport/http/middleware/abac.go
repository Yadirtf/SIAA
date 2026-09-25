// Package middleware — Control de acceso basado en atributos y ámbitos (ABAC).
// Satisface US-ROL-02, AC-02..AC-06 y RF-ROL-003.
package middleware

import (
	"fmt"

	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/usecase/auth"
)

// EnforceScopeFilter aplica obligatoriamente los ámbitos del usuario autenticado en consultas de backend.
// Si el cliente manipula el parámetro y solicita un recurso fuera de su ámbito, se rechaza con HTTP 403.
// Si el cliente omite el filtro, se inyecta automáticamente el ID del ámbito asignado al usuario.
// Superadministrador y usuarios sin restricción de ámbito operan de forma irrestricta (AC-06).
func EnforceScopeFilter(claims *auth.JWTClaims, scopeType rbac.ScopeType, requestedID string) (string, error) {
	if claims == nil {
		return requestedID, nil
	}

	// Superadministrador opera sin restricciones de ámbito (AC-06)
	if claims.RolActivo == string(rbac.RolSuperadmin) || len(claims.Ambitos) == 0 {
		return requestedID, nil
	}

	// Filtrar los ámbitos del usuario que coincidan con el tipo de recurso solicitado
	var allowedIDs []string
	for _, s := range claims.Ambitos {
		if s.Tipo == scopeType {
			allowedIDs = append(allowedIDs, s.ID)
		}
	}

	// Si el usuario no tiene restricciones sobre este tipo de recurso en particular, permitir
	if len(allowedIDs) == 0 {
		return requestedID, nil
	}

	// Si el cliente envió un ID específico, validar que esté dentro de sus ámbitos permitidos
	if requestedID != "" {
		for _, allowed := range allowedIDs {
			if allowed == requestedID {
				return requestedID, nil
			}
		}
		// Intento de acceso a ámbito no asignado -> HTTP 403 (AC-02, CA-010)
		return "", shared.NewAuthError(
			shared.ErrAmbitoDenegado,
			fmt.Sprintf("Acceso denegado: no tiene autorización sobre el recurso %s", requestedID),
		)
	}

	// Si el cliente no envió filtro, forzar obligatoriamente el primer ámbito del usuario (AC-03, AC-04)
	return allowedIDs[0], nil
}

// ValidateResourceScope verifica si un recurso puntual ya cargado pertenece al ámbito del usuario autenticado.
func ValidateResourceScope(claims *auth.JWTClaims, scopeType rbac.ScopeType, resourceID string) error {
	if claims == nil || claims.RolActivo == string(rbac.RolSuperadmin) || len(claims.Ambitos) == 0 {
		return nil
	}

	if !rbac.IsInScope(claims.Ambitos, scopeType, resourceID) {
		return shared.NewAuthError(
			shared.ErrAmbitoDenegado,
			fmt.Sprintf("Acceso denegado al recurso %s fuera de su ámbito asignado", resourceID),
		)
	}

	return nil
}
