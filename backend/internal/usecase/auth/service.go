// Package auth implementa los casos de uso de autenticación de SIAA.
//
// Organización del paquete:
//   - service.go  → definición del Service y NewService (este archivo)
//   - types.go    → tipos de entrada/salida e interfaces (LoginInput, TokenPair, Mailer…)
//   - login.go    → US-AUT-01: autenticación con correo y contraseña
//   - refresh.go  → US-AUT-01 AC-05/AC-06: rotación y detección de robo de tokens
//   - logout.go   → US-AUT-01: revocación del token de refresco
//   - recovery.go → US-AUT-04: solicitud y confirmación de recuperación
//   - device.go   → US-AUT-03: vinculación y gestión de dispositivos confiables
//   - tokens.go   → emisión de JWT y refresh tokens (interno)
//   - crypto/     → utilidades criptográficas puras (hash, validación)
//
// ADR-02: orquestación pura — el Service delega al dominio y al repositorio.
package auth

import (
	"context"

	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/domain/user"
	"github.com/siaa/backend/internal/platform/config"
	"github.com/siaa/backend/internal/repository"
)

// Service es el punto de entrada del caso de uso de autenticación.
// Sus métodos están distribuidos en archivos separados por responsabilidad.
type Service struct {
	usuarios     repository.UsuarioRepository
	tokens       repository.RefreshTokenRepository
	recovery     repository.RecoveryTokenRepository
	auditoria    repository.AuditoriaRepository
	dispositivos repository.DispositivoRepository
	clock        shared.Clock
	cfg          *config.Config
	mailer       Mailer
}

// NewService crea un nuevo servicio de autenticación con todas sus dependencias.
func NewService(
	usuarios repository.UsuarioRepository,
	tokens repository.RefreshTokenRepository,
	recovery repository.RecoveryTokenRepository,
	auditoria repository.AuditoriaRepository,
	clock shared.Clock,
	cfg *config.Config,
	mailer Mailer,
) *Service {
	return &Service{
		usuarios:  usuarios,
		tokens:    tokens,
		recovery:  recovery,
		auditoria: auditoria,
		clock:     clock,
		cfg:       cfg,
		mailer:    mailer,
	}
}

// WithDispositivos inyecta el repositorio de dispositivos confiables (US-AUT-03).
func (s *Service) WithDispositivos(dispositivos repository.DispositivoRepository) *Service {
	s.dispositivos = dispositivos
	return s
}

// ListarUsuarios retorna los usuarios registrados activos para administración y selección en interfaz.
func (s *Service) ListarUsuarios(ctx context.Context, limite int) ([]*user.Usuario, error) {
	return s.usuarios.Listar(ctx, limite)
}
