// Package auth — segundo factor durante el inicio de sesión (US-AUT-05 AC-01, AC-02, AC-04).
// Ambos flujos exigen el desafío emitido por Login tras validar la contraseña.
package auth

import (
	"context"
	"strings"
	"time"

	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/domain/user"
	"github.com/siaa/backend/internal/repository"
	"github.com/siaa/backend/internal/usecase/auth/crypto"
)

// maxFallosTOTP es el número de códigos incorrectos consecutivos que bloquea la cuenta (AC-04).
const maxFallosTOTP = 5

// VerificarTOTP valida el código (o un código de respaldo) del desafío de login y entrega los tokens.
func (s *Service) VerificarTOTP(ctx context.Context, desafio, codigo, dispositivoID string) (*TokenPair, error) {
	u, didDesafio, err := s.leerDesafio(ctx, desafio, DesafioVerificar)
	if err != nil {
		return nil, err
	}
	now := s.clock.Now()
	codigoLimpio := strings.ToUpper(strings.TrimSpace(codigo))

	esValido := crypto.ValidateTOTPCode(u.TOTPSecreto, codigoLimpio, now)
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
		return nil, s.registrarFalloTOTP(ctx, u, now)
	}

	u.IntentosFallidosTOTP = 0
	u.BloqueadoHastaTOTP = nil
	if err := s.usuarios.Update(ctx, u); err != nil {
		return nil, err
	}
	return s.completarLogin(ctx, u, elegirDispositivo(dispositivoID, didDesafio))
}

// EnrolarTOTP inicia la configuración obligatoria del segundo factor desde el desafío (AC-01).
func (s *Service) EnrolarTOTP(ctx context.Context, desafio string) (*TOTPSetupResult, error) {
	u, _, err := s.leerDesafio(ctx, desafio, DesafioConfigurar)
	if err != nil {
		return nil, err
	}
	return s.SetupTOTP(ctx, u.ID)
}

// ConfirmarEnrolamientoTOTP activa el segundo factor con el primer código y entrega los tokens.
func (s *Service) ConfirmarEnrolamientoTOTP(ctx context.Context, desafio, codigo, dispositivoID string) (*TokenPair, error) {
	u, didDesafio, err := s.leerDesafio(ctx, desafio, DesafioConfigurar)
	if err != nil {
		return nil, err
	}
	if err := s.ActivarTOTP(ctx, u.ID, strings.TrimSpace(codigo)); err != nil {
		return nil, err
	}
	u, err = s.usuarios.FindByID(ctx, u.ID)
	if err != nil || u == nil {
		return nil, shared.NewNotFoundError("Usuario", "")
	}
	return s.completarLogin(ctx, u, elegirDispositivo(dispositivoID, didDesafio))
}

// registrarFalloTOTP cuenta el fallo y, al quinto consecutivo, bloquea la cuenta igual que
// US-AUT-02 (mismo bloqueo que la contraseña, con auditoría).
func (s *Service) registrarFalloTOTP(ctx context.Context, u *user.Usuario, now time.Time) error {
	u.IntentosFallidosTOTP++
	if u.IntentosFallidosTOTP >= maxFallosTOTP {
		minutos := s.cfg.LockoutDurationMin
		if minutos <= 0 {
			minutos = 15
		}
		bloqueo := now.Add(time.Duration(minutos) * time.Minute)
		u.BloqueadoHasta = &bloqueo
		u.BloqueadoHastaTOTP = &bloqueo
		u.IntentosFallidosTOTP = 0
		if s.auditoria != nil {
			_ = s.auditoria.Create(ctx, &repository.AuditEntry{
				ID:         shared.NewID(),
				Entidad:    "usuario",
				EntidadID:  u.ID,
				Accion:     "BLOQUEO_CUENTA",
				ActorID:    "sistema",
				ValorNuevo: map[string]string{"motivo": "segundo factor incorrecto 5 veces"},
				CreadoEn:   now,
			})
		}
	}
	_ = s.usuarios.Update(ctx, u)
	if u.BloqueadoHasta != nil && now.Before(*u.BloqueadoHasta) {
		return shared.NewAuthError(shared.ErrCuentaBloqueada,
			"Cuenta bloqueada. Inténtalo de nuevo a las "+shared.HoraLocal(*u.BloqueadoHasta))
	}
	return shared.NewAuthError(shared.ErrCredencialesInvalidas, "Código de autenticación inválido")
}

// completarLogin emite los tokens y audita el inicio de sesión con segundo factor.
func (s *Service) completarLogin(ctx context.Context, u *user.Usuario, dispositivoID string) (*TokenPair, error) {
	pair, err := s.emitTokens(ctx, u, dispositivoID)
	if err != nil {
		return nil, err
	}
	if s.auditoria != nil {
		_ = s.auditoria.Create(ctx, &repository.AuditEntry{
			ID:         shared.NewID(),
			Entidad:    "usuario",
			EntidadID:  u.ID,
			Accion:     "LOGIN",
			ActorID:    u.ID,
			ValorNuevo: map[string]string{"segundoFactor": "TOTP"},
			CreadoEn:   s.clock.Now(),
		})
	}
	return pair, nil
}

func elegirDispositivo(solicitado, desafio string) string {
	if solicitado != "" {
		return solicitado
	}
	return desafio
}
