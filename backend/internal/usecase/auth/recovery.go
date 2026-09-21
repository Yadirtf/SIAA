// Package auth — casos de uso de recuperación de contraseña.
// US-AUT-04: solicitud + confirmación con token de un solo uso.
package auth

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/repository"
	"github.com/siaa/backend/internal/usecase/auth/crypto"
)

// SolicitarRecuperacion genera y envía un enlace de recuperación de contraseña.
// La respuesta es SIEMPRE igual, exista o no el correo (AC-02 anti-enumeración).
func (s *Service) SolicitarRecuperacion(ctx context.Context, correo string) error {
	correo = strings.ToLower(strings.TrimSpace(correo))
	usuario, _ := s.usuarios.FindByCorreo(ctx, correo)

	// Respuesta idéntica si el correo no existe — no se revela información
	if usuario == nil || !usuario.Activo {
		return nil
	}

	// Generar token de un solo uso
	rawToken := crypto.GenerateSecureToken(32)
	tokenHash := crypto.HashToken(rawToken)

	expira := s.clock.Now().Add(time.Duration(s.cfg.RecoveryTokenMinutes) * time.Minute)
	rt := &repository.RecoveryToken{
		ID:        shared.NewID(),
		UsuarioID: usuario.ID,
		TokenHash: tokenHash,
		ExpiraEn:  expira,
		Usado:     false,
		CreadoEn:  s.clock.Now(),
	}
	if err := s.recovery.Create(ctx, rt); err != nil {
		return fmt.Errorf("crear token de recuperación: %w", err)
	}

	// Envío de correo en background para no bloquear la respuesta al cliente
	go func() {
		_ = s.mailer.SendRecovery(context.Background(), correo, rawToken)
	}()

	return nil
}

// ConfirmarRecuperacion establece la nueva contraseña usando el token de un solo uso.
// Revoca todas las sesiones activas del usuario al completar.
func (s *Service) ConfirmarRecuperacion(ctx context.Context, token, nuevaPassword string) error {
	// Validar política de contraseña — AC-05
	if err := crypto.ValidatePassword(nuevaPassword, s.cfg.PasswordMinLength); err != nil {
		return err
	}

	tokenHash := crypto.HashToken(token)
	rt, err := s.recovery.FindByHash(ctx, tokenHash)
	if err != nil || rt == nil || rt.Usado || s.clock.Now().After(rt.ExpiraEn) {
		return shared.NewAuthError(shared.ErrTokenExpirado,
			"El enlace de recuperación es inválido o ha expirado")
	}

	// Hashear nueva contraseña
	hash, err := crypto.HashArgon2id(nuevaPassword)
	if err != nil {
		return fmt.Errorf("hashear contraseña: %w", err)
	}

	// Actualizar contraseña y revocar todas las sesiones activas
	if err := s.usuarios.UpdatePassword(ctx, rt.UsuarioID, hash); err != nil {
		return fmt.Errorf("actualizar contraseña: %w", err)
	}
	if err := s.tokens.RevokeByUsuario(ctx, rt.UsuarioID); err != nil {
		return fmt.Errorf("revocar sesiones: %w", err)
	}
	if err := s.recovery.MarkUsed(ctx, rt.ID); err != nil {
		return fmt.Errorf("marcar token usado: %w", err)
	}

	// Auditoría
	_ = s.auditoria.Create(ctx, &repository.AuditEntry{
		ID:        shared.NewID(),
		Entidad:   "usuario",
		EntidadID: rt.UsuarioID,
		Accion:    "PASSWORD_RECUPERADA",
		ActorID:   rt.UsuarioID,
		CreadoEn:  s.clock.Now(),
	})

	return nil
}
