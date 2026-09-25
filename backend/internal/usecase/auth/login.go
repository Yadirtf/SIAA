// Package auth — caso de uso Login.
// US-AUT-01, AC-01..AC-04, AC-07.
package auth

import (
	"fmt"
	"strings"
	"time"

	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/repository"
	"github.com/siaa/backend/internal/usecase/auth/crypto"
	"golang.org/x/net/context"
)

// Login autentica un usuario con correo y contraseña institucional.
// Devuelve un par de tokens (access + refresh) si las credenciales son válidas.
func (s *Service) Login(ctx context.Context, input LoginInput) (*TokenPair, error) {
	// Normalizar correo
	correo := strings.ToLower(strings.TrimSpace(input.Correo))

	// Validar dominio institucional — AC-07
	if err := s.validateEmailDomain(correo); err != nil {
		return nil, err
	}

	// Buscar usuario — respuesta genérica si no existe (AC-02 anti-enumeración)
	usuario, err := s.usuarios.FindByCorreo(ctx, correo)
	if err != nil || usuario == nil {
		// Simular trabajo de hash para evitar timing attack
		_ = crypto.VerifyArgon2id("dummy", "$argon2id$v=19$m=65536,t=1,p=2$dummysalt$dummyhash")
		return nil, shared.NewAuthError(shared.ErrCredencialesInvalidas, "Credenciales incorrectas")
	}

	// Verificar bloqueo — AC-01 de US-AUT-02
	if usuario.BloqueadoHasta != nil && s.clock.Now().Before(*usuario.BloqueadoHasta) {
		return nil, shared.NewAuthError(shared.ErrCuentaBloqueada,
			fmt.Sprintf("Cuenta bloqueada. Inténtalo de nuevo a las %s",
				usuario.BloqueadoHasta.Format("15:04")))
	}

	// Verificar estado activo — AC-03 US-AUT-01 (rechazado con 403)
	if !usuario.Activo || usuario.Eliminado {
		return nil, shared.NewAuthError(shared.ErrUsuarioInactivo, "Usuario inactivo o eliminado")
	}

	// Verificar contraseña — AC-04
	if !crypto.VerifyArgon2id(input.Password, usuario.PasswordHash) {
		now := s.clock.Now()
		ventanaMinutos := time.Duration(s.cfg.LockoutDurationMin) * time.Minute

		// Ventana deslizante (T-AUT-02.1 / AC-01):
		// Si han transcurrido más de 15 minutos desde el último fallo, reiniciar contador a 1.
		// De lo contrario, incrementar los fallos acumulados.
		intentos := usuario.IntentosFallidos + 1
		if usuario.UltimoFalloEn != nil && now.Sub(*usuario.UltimoFalloEn) > ventanaMinutos {
			intentos = 1
		}

		var bloqueadoHasta *time.Time
		if intentos >= s.cfg.FailedLoginMax {
			t := now.Add(ventanaMinutos)
			bloqueadoHasta = &t

			// Auditoría de cuenta bloqueada — AC-01 US-AUT-02
			_ = s.auditoria.Create(ctx, &repository.AuditEntry{
				ID:        shared.NewID(),
				Entidad:   "usuario",
				EntidadID: usuario.ID,
				Accion:    "BLOQUEO_CUENTA",
				ActorID:   "sistema",
				CreadoEn:  now,
			})
		}

		_ = s.usuarios.UpdateIntentosFallidos(ctx, usuario.ID, intentos, bloqueadoHasta, &now)
		return nil, shared.NewAuthError(shared.ErrCredencialesInvalidas, "Credenciales incorrectas")
	}

	// Autenticación exitosa: resetear contador de intentos
	_ = s.usuarios.ResetIntentosFallidos(ctx, usuario.ID)

	// Emitir par de tokens
	pair, err := s.emitTokens(ctx, usuario, input.DispositivoID)
	if err != nil {
		return nil, err
	}

	// Auditoría de login exitoso
	_ = s.auditoria.Create(ctx, &repository.AuditEntry{
		ID:        shared.NewID(),
		Entidad:   "usuario",
		EntidadID: usuario.ID,
		Accion:    "LOGIN",
		ActorID:   usuario.ID,
		CreadoEn:  s.clock.Now(),
	})

	return pair, nil
}
