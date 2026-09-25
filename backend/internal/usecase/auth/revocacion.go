// Package auth — Cierre de sesión remoto y revocación de tokens.
// Satisface US-AUT-07, AC-01..AC-03 y RF-AUT-006.
package auth

import (
	"context"
	"fmt"
	"strings"

	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/platform/security"
	"github.com/siaa/backend/internal/repository"
)

// RevocarSesionesUsuario revoca todas las sesiones y tokens de un usuario por decisión administrativa.
// AC-01: Invalida inmediatamente todos los refresh tokens.
// AC-02: Los access tokens activos son rechazados en <= 60 s vía lista en memoria.
// AC-03: La operación queda auditada con actor, usuario afectado, motivo y timestamp.
func (s *Service) RevocarSesionesUsuario(ctx context.Context, actorID, targetUsuarioID, motivo string) error {
	targetUsuarioID = strings.TrimSpace(targetUsuarioID)
	if targetUsuarioID == "" {
		return shared.NewValidationError("El identificador de usuario es obligatorio")
	}

	u, err := s.usuarios.FindByID(ctx, targetUsuarioID)
	if err != nil || u == nil {
		return shared.NewNotFoundError("Usuario", targetUsuarioID)
	}

	now := s.clock.Now()

	// 1. Invalida refresh tokens en base de datos — AC-01
	if err := s.tokens.RevokeByUsuario(ctx, targetUsuarioID); err != nil {
		return fmt.Errorf("revocar refresh tokens: %w", err)
	}

	// 2. Actualizar marca de revocación en base de datos
	u.SesionesRevocadasAntes = &now
	_ = s.usuarios.Update(ctx, u)

	// 3. Registrar en lista de revocación en memoria para intercepción de access token en middleware — AC-02
	security.DefaultRevocationManager().RevokeUser(targetUsuarioID, now)

	// 4. Registrar auditoría exhaustiva — AC-03
	if s.auditoria != nil {
		_ = s.auditoria.Create(ctx, &repository.AuditEntry{
			Entidad:   "Usuario",
			EntidadID: targetUsuarioID,
			Accion:    "SESIONES_REVOCADAS_REMOTAMENTE",
			ActorID:   actorID,
			CreadoEn:  now,
			ValorNuevo: map[string]string{
				"usuarioAfectado": targetUsuarioID,
				"correoAfectado":  u.Correo,
				"motivo":          motivo,
				"revocadoEn":      now.Format("2006-01-02T15:04:05Z07:00"),
			},
		})
	}

	return nil
}
