// Package auth — Lógica de enrolamiento y verificación de segundo factor TOTP.
// Satisface US-AUT-05, AC-01..AC-05 y RF-AUT-003.
package auth

import (
	"context"
	"fmt"

	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/repository"
	"github.com/siaa/backend/internal/usecase/auth/crypto"
)

// TOTPSetupResult contiene la clave secreta y los 8 códigos de respaldo generados.
type TOTPSetupResult struct {
	SecretKey   string   `json:"secretKey"`
	BackupCodes []string `json:"backupCodes"`
}

// IsRolAdministrativo determina si el rol exige segundo factor obligatorio (US-AUT-05 AC-01, AC-05).
func IsRolAdministrativo(rol rbac.RoleName) bool {
	switch rol {
	case rbac.RolSuperadmin, rbac.RolAdminInst, rbac.RolCoordinador:
		return true
	default:
		return false
	}
}

// SetupTOTP inicia el enrolamiento de 2FA generando secreto y 8 códigos de respaldo (AC-01, AC-03).
func (s *Service) SetupTOTP(ctx context.Context, usuarioID string) (*TOTPSetupResult, error) {
	u, err := s.usuarios.FindByID(ctx, usuarioID)
	if err != nil || u == nil {
		return nil, shared.NewNotFoundError("Usuario", usuarioID)
	}
	// Reconfigurar un segundo factor activo lo dejaría inactivo con solo un access token robado.
	if u.TOTPActivado {
		return nil, &shared.DomainError{Code: shared.ErrConflictoUnicidad,
			Message: "El segundo factor ya está activo; un administrador debe restablecerlo"}
	}

	secret, err := crypto.GenerateTOTPSecret()
	if err != nil {
		return nil, fmt.Errorf("generar secreto TOTP: %w", err)
	}

	plaintextCodes, hashedCodes, err := crypto.GenerateBackupCodes(8)
	if err != nil {
		return nil, fmt.Errorf("generar códigos de respaldo: %w", err)
	}

	u.TOTPSecreto = secret
	u.BackupCodes = hashedCodes
	u.TOTPActivado = false // Pendiente de confirmación con código válido
	u.IntentosFallidosTOTP = 0

	if err := s.usuarios.Update(ctx, u); err != nil {
		return nil, fmt.Errorf("persistir setup TOTP: %w", err)
	}

	return &TOTPSetupResult{
		SecretKey:   secret,
		BackupCodes: plaintextCodes,
	}, nil
}

// ActivarTOTP confirma el enrolamiento validando el primer código de 6 dígitos (AC-01, AC-02).
func (s *Service) ActivarTOTP(ctx context.Context, usuarioID, codigo string) error {
	u, err := s.usuarios.FindByID(ctx, usuarioID)
	if err != nil || u == nil {
		return shared.NewNotFoundError("Usuario", usuarioID)
	}

	if u.TOTPSecreto == "" {
		return shared.NewValidationError("No hay un proceso de configuración TOTP pendiente")
	}

	now := s.clock.Now()
	if !crypto.ValidateTOTPCode(u.TOTPSecreto, codigo, now) {
		return shared.NewValidationError("Código TOTP inválido; ingrese el código de 6 dígitos actual")
	}

	u.TOTPActivado = true
	u.IntentosFallidosTOTP = 0
	u.BloqueadoHastaTOTP = nil

	if err := s.usuarios.Update(ctx, u); err != nil {
		return fmt.Errorf("activar TOTP: %w", err)
	}

	if s.auditoria != nil {
		_ = s.auditoria.Create(ctx, &repository.AuditEntry{
			Entidad:   "Usuario",
			EntidadID: u.ID,
			Accion:    "TOTP_ACTIVADO",
			ActorID:   u.ID,
			CreadoEn:  now,
			ValorNuevo: map[string]string{
				"usuarioID": u.ID,
				"correo":    u.Correo,
			},
		})
	}

	return nil
}
