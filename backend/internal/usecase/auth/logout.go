// Package auth — caso de uso Logout.
// US-AUT-01: revocación idempotente del refresh token actual.
package auth

import (
	"context"

	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/usecase/auth/crypto"
)

// Logout revoca el refresh token del usuario autenticado.
// Es idempotente: si el token no existe o ya fue revocado, no retorna error.
func (s *Service) Logout(ctx context.Context, refreshToken, usuarioID string) error {
	tokenHash := crypto.HashToken(refreshToken)

	stored, err := s.tokens.FindByHash(ctx, tokenHash)
	if err != nil || stored == nil {
		return nil // idempotente — ya estaba revocado o no existía
	}

	// Verificar que el token pertenece al usuario que hace logout
	if stored.UsuarioID != usuarioID {
		return shared.NewPermissionError()
	}

	return s.tokens.RevokeByID(ctx, stored.ID)
}
