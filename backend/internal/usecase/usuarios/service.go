// Package usuarios implementa la gestión administrativa de usuarios (RF-ROL, US-ROL-01..05):
// alta, edición, activación, asignación de roles y ámbitos e importación CSV.
//
//   - service.go    → Service, actor y auditoría (este archivo)
//   - validacion.go → reglas de roles, ámbitos y anti-escalamiento
//   - crear.go      → alta individual con contraseña o invitación por correo
//   - editar.go     → datos, estado, roles y ámbitos
//   - consultar.go  → listado filtrado por alcance y detalle
//   - importar.go   → importación masiva CSV
package usuarios

import (
	"context"

	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/repository"
)

// Invitador envía al usuario el enlace para definir su contraseña (flujo de recuperación).
type Invitador interface {
	SolicitarRecuperacion(ctx context.Context, correo string) error
}

// RevocadorSesiones cierra las sesiones de un usuario desactivado (US-AUT-07).
type RevocadorSesiones interface {
	RevocarSesionesUsuario(ctx context.Context, actorID, usuarioID, motivo string) error
}

// Actor es quien ejecuta la operación, con su rol activo y alcance (RF-ROL-003).
type Actor struct {
	UsuarioID string
	RolActivo string
	Alcance   rbac.Alcance
}

// Service orquesta la gestión de usuarios.
type Service struct {
	usuarios  repository.UsuarioRepository
	roles     repository.RolRepository
	auditoria repository.AuditoriaRepository
	clock     shared.Clock
	invitador Invitador
	revocador RevocadorSesiones
	minClave  int
}

// NewService crea el servicio de gestión de usuarios. minClave es la longitud mínima de contraseña.
func NewService(usuarios repository.UsuarioRepository, roles repository.RolRepository, auditoria repository.AuditoriaRepository, clock shared.Clock, minClave int) *Service {
	return &Service{usuarios: usuarios, roles: roles, auditoria: auditoria, clock: clock, minClave: minClave}
}

// WithInvitador conecta el envío de invitaciones por correo.
func (s *Service) WithInvitador(i Invitador) *Service {
	s.invitador = i
	return s
}

// WithRevocador conecta el cierre de sesiones al desactivar usuarios.
func (s *Service) WithRevocador(r RevocadorSesiones) *Service {
	s.revocador = r
	return s
}

// auditar registra el cambio con valor anterior y nuevo (RF-ROL-005).
func (s *Service) auditar(ctx context.Context, actor Actor, usuarioID, accion string, antes, despues interface{}) {
	if s.auditoria == nil {
		return
	}
	_ = s.auditoria.Create(ctx, &repository.AuditEntry{
		ID:            shared.NewID(),
		Entidad:       "Usuario",
		EntidadID:     usuarioID,
		Accion:        accion,
		ActorID:       actor.UsuarioID,
		RolActivo:     actor.RolActivo,
		ValorAnterior: antes,
		ValorNuevo:    despues,
		CreadoEn:      s.clock.Now(),
	})
}
