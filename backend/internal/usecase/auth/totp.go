// Package auth — Lógica de enrolamiento y verificación de segundo factor TOTP.
// Satisface US-AUT-05, AC-01..AC-05 y RF-AUT-003.
package auth

import (
	"context"
	"fmt"
	"strings"
	"time"

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

// VerificarTOTP valida el código de segundo factor (o backup code) durante el flujo de inicio de sesión.
// AC-04: Bloquea la cuenta tras 5 intentos fallidos consecutivos.
func (s *Service) VerificarTOTP(ctx context.Context, usuarioID, codigo, dispositivoID string) (*TokenPair, error) {
	u, err := s.usuarios.FindByID(ctx, usuarioID)
	if err != nil || u == nil {
		return nil, shared.NewNotFoundError("Usuario", usuarioID)
	}

	now := s.clock.Now()

	// Verificar bloqueo por intentos fallidos de 2FA — AC-04
	if u.BloqueadoHastaTOTP != nil && now.Before(*u.BloqueadoHastaTOTP) {
		return nil, shared.NewAuthError(shared.ErrCuentaBloqueada,
			fmt.Sprintf("Segundo factor bloqueado por intentos fallidos hasta las %s",
				u.BloqueadoHastaTOTP.Format("15:04")))
	}

	codigoLimpio := strings.ToUpper(strings.TrimSpace(codigo))

	// Intentar validar como código TOTP de 6 dígitos
	esValido := crypto.ValidateTOTPCode(u.TOTPSecreto, codigoLimpio, now)

	// Si no es válido como TOTP, intentar consumir como código de respaldo
	if !esValido && len(codigoLimpio) == 8 {
		hashInput := crypto.HashToken(codigoLimpio)
		for idx, h := range u.BackupCodes {
			if h == hashInput {
				// Consumo de código de respaldo único (AC-03)
				u.BackupCodes = append(u.BackupCodes[:idx], u.BackupCodes[idx+1:]...)
				esValido = true
				break
			}
		}
	}

	if !esValido {
		u.IntentosFallidosTOTP++
		if u.IntentosFallidosTOTP >= 5 {
			bloqueo := now.Add(15 * time.Minute)
			u.BloqueadoHastaTOTP = &bloqueo
			u.IntentosFallidosTOTP = 0
		}
		_ = s.usuarios.Update(ctx, u)
		return nil, shared.NewAuthError(shared.ErrCredencialesInvalidas, "Código de autenticación inválido")
	}

	// Éxito: resetear contadores de fallo y emitir tokens
	u.IntentosFallidosTOTP = 0
	u.BloqueadoHastaTOTP = nil
	_ = s.usuarios.Update(ctx, u)

	return s.emitTokens(ctx, u, dispositivoID)
}
