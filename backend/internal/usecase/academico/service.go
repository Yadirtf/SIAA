// Package academico — casos de uso para la estructura académica, horarios y asignaciones (EP-04).
package academico

import (
	"context"
	"errors"

	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/domain/shared"
	applog "github.com/siaa/backend/internal/platform/log"
	"github.com/siaa/backend/internal/repository"
)

var (
	ErrPeriodoNoEncontrado    = errors.New("periodo no encontrado")
	ErrFacultadNoEncontrada   = errors.New("facultad no encontrada")
	ErrProgramaNoEncontrado   = errors.New("programa no encontrado")
	ErrAsignaturaNoEncontrada = errors.New("asignatura no encontrada")
	ErrGrupoNoEncontrado      = errors.New("grupo no encontrado")
	ErrAsignacionNoEncontrada = errors.New("asignación no encontrada")
	ErrExcepcionNoEncontrada  = errors.New("excepción no encontrada")
	ErrFueraDeAmbitoFacultad  = errors.New("el usuario no tiene alcance sobre la facultad especificada (US-ACA-03 AC-07 ABAC)")
	ErrColisionDetectada      = errors.New("se detectó un conflicto de horarios o solapamiento")
)

type ContextoActor struct {
	UsuarioID string
	Rol       string
	Scopes    []rbac.Scope
}

type Service struct {
	periodoRepo    repository.PeriodoRepository
	estructuraRepo repository.EstructuraRepository
	asignacionRepo repository.AsignacionRepository
	excepcionRepo  repository.CalendarioExcepcionRepository
	usuarioRepo    repository.UsuarioRepository
	espacioRepo    repository.EspacioRepository
	sesionRepo     repository.SesionRepository
	auditoriaRepo  repository.AuditoriaRepository
	clk            shared.Clock
	log            *applog.Logger
}

func NewService(
	periodoRepo repository.PeriodoRepository,
	estructuraRepo repository.EstructuraRepository,
	asignacionRepo repository.AsignacionRepository,
	excepcionRepo repository.CalendarioExcepcionRepository,
	usuarioRepo repository.UsuarioRepository,
	espacioRepo repository.EspacioRepository,
	auditoriaRepo repository.AuditoriaRepository,
	clk shared.Clock,
	log *applog.Logger,
) *Service {
	return &Service{
		periodoRepo:    periodoRepo,
		estructuraRepo: estructuraRepo,
		asignacionRepo: asignacionRepo,
		excepcionRepo:  excepcionRepo,
		usuarioRepo:    usuarioRepo,
		espacioRepo:    espacioRepo,
		auditoriaRepo:  auditoriaRepo,
		clk:            clk,
		log:            log,
	}
}

// WithSesiones inyecta el repositorio de sesiones en el servicio académico.
func (s *Service) WithSesiones(sesionRepo repository.SesionRepository) *Service {
	s.sesionRepo = sesionRepo
	return s
}

func (s *Service) auditar(ctx context.Context, entidad, entidadID, accion string, actor ContextoActor, valAnt, valNuevo interface{}) {
	if s.auditoriaRepo == nil {
		return
	}
	entry := &repository.AuditEntry{
		Entidad:       entidad,
		EntidadID:     entidadID,
		Accion:        accion,
		ActorID:       actor.UsuarioID,
		RolActivo:     actor.Rol,
		ValorAnterior: valAnt,
		ValorNuevo:    valNuevo,
		CreadoEn:      s.clk.Now(),
	}
	_ = s.auditoriaRepo.Create(ctx, entry)
}
