// Package auth — caso de uso Refresh.
// US-AUT-01, AC-05 (rotación de tokens), AC-06 (detección de robo).
package auth

import (
	"context"
	"fmt"

	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/repository"
	"github.com/siaa/backend/internal/usecase/auth/crypto"
)

// Refresh rota el refresh token y emite un nuevo par de tokens.
// Si el token fue reutilizado (ya revocado), se revoca toda la familia — AC-06.
func (s *Service) Refresh(ctx context.Context, refreshToken, dispositivoID string) (*TokenPair, error) {
	tokenHash := crypto.HashToken(refreshToken)

	stored, err := s.tokens.FindByHash(ctx, tokenHash)
	if err != nil || stored == nil {
		return nil, shared.NewAuthError(shared.ErrTokenRevocado, "Token de refresco inválido")
	}

	// Detectar reutilización de token (posible robo) — AC-06
	if stored.Revocado {
		_ = s.tokens.RevokeByFamilia(ctx, stored.FamiliaID)
		_ = s.auditoria.Create(ctx, &repository.AuditEntry{
			ID:        shared.NewID(),
			Entidad:   "refresh_token",
			EntidadID: stored.ID,
			Accion:    "TOKEN_REUTILIZADO_FAMILIA_REVOCADA",
			ActorID:   stored.UsuarioID,
			CreadoEn:  s.clock.Now(),
		})
		return nil, shared.NewAuthError(shared.ErrTokenRevocado,
			"Token de seguridad comprometido. Por favor inicia sesión nuevamente")
	}

	// Verificar expiración
	if s.clock.Now().After(stored.ExpiraEn) {
		return nil, shared.NewAuthError(shared.ErrTokenExpirado, "Token de refresco expirado")
	}

	// Revocar el token actual (rotación obligatoria — AC-05)
	if err := s.tokens.RevokeByID(ctx, stored.ID); err != nil {
		return nil, fmt.Errorf("revocar token: %w", err)
	}

	// Cargar usuario
	usuario, err := s.usuarios.FindByID(ctx, stored.UsuarioID)
	if err != nil || usuario == nil || !usuario.Activo {
		return nil, shared.NewAuthError(shared.ErrCredencialesInvalidas, "Usuario no disponible")
	}

	// Emitir nuevo par conservando la misma familia
	return s.emitTokensInFamily(ctx, usuario, dispositivoID, stored.FamiliaID)
}
