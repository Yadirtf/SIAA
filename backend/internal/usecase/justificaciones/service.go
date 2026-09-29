// Package justificaciones implementa el flujo de novedades del docente (EP-07):
//
//   - service.go   → Service, dependencias, actor y auditoría (este archivo)
//   - radicar.go   → radicación con soportes y reglas de elegibilidad (RF-JUS-001, 003)
//   - soportes.go  → validación y lectura de los soportes cifrados
//   - revisar.go   → flujo de aprobación y notificación (RF-JUS-002, 005)
//   - consultar.go → bandeja por alcance y detalle
package justificaciones

import (
	"context"
	"errors"
	"time"

	"github.com/siaa/backend/internal/domain/justificacion"
	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/repository"
)

// Correo envía las notificaciones del resultado de la revisión (RF-JUS-005).
type Correo interface {
	Enviar(ctx context.Context, para, asunto, cuerpo string) error
}

// Actor es quien opera, con su alcance (RF-ROL-003).
type Actor struct {
	UsuarioID string
	RolActivo string
	Alcance   rbac.Alcance
}

// Service orquesta la radicación y revisión de justificaciones.
type Service struct {
	justificaciones repository.JustificacionRepository
	adjuntos        repository.AdjuntoRepository
	sesiones        repository.SesionRepository
	marcajes        repository.MarcajeRepository
	usuarios        repository.UsuarioRepository
	auditoria       repository.AuditoriaRepository
	clock           shared.Clock
	correo          Correo
	plazoDias       int
}

// NewService crea el servicio con el plazo por defecto de días hábiles.
func NewService(
	justificaciones repository.JustificacionRepository,
	adjuntos repository.AdjuntoRepository,
	sesiones repository.SesionRepository,
	marcajes repository.MarcajeRepository,
	usuarios repository.UsuarioRepository,
	auditoria repository.AuditoriaRepository,
	clock shared.Clock,
) *Service {
	return &Service{
		justificaciones: justificaciones,
		adjuntos:        adjuntos,
		sesiones:        sesiones,
		marcajes:        marcajes,
		usuarios:        usuarios,
		auditoria:       auditoria,
		clock:           clock,
		plazoDias:       justificacion.DiasHabilesPlazo,
	}
}

// WithCorreo habilita la notificación por correo al solicitante.
func (s *Service) WithCorreo(c Correo) *Service {
	s.correo = c
	return s
}

// WithPlazoDias cambia el plazo de radicación en días hábiles (0 conserva el defecto).
func (s *Service) WithPlazoDias(dias int) *Service {
	if dias > 0 {
		s.plazoDias = dias
	}
	return s
}

func (s *Service) auditar(ctx context.Context, actor Actor, accion, id string, antes, despues interface{}) {
	if s.auditoria == nil {
		return
	}
	_ = s.auditoria.Create(ctx, &repository.AuditEntry{
		Entidad:       "justificaciones",
		EntidadID:     id,
		Accion:        accion,
		ActorID:       actor.UsuarioID,
		RolActivo:     actor.RolActivo,
		ValorAnterior: antes,
		ValorNuevo:    despues,
		CreadoEn:      s.clock.Now(),
	})
}

// errorDominio traduce los errores de la entidad a errores de validación (422).
func errorDominio(err error) error {
	for _, e := range []error{
		justificacion.ErrTipoInvalido, justificacion.ErrDescripcionCorta, justificacion.ErrObservacionesCortas,
		justificacion.ErrTransicionInvalida, justificacion.ErrSinSoporte, justificacion.ErrEstadoDestinoInvalido,
	} {
		if errors.Is(err, e) {
			return shared.NewValidationError(err.Error())
		}
	}
	if errors.Is(err, justificacion.ErrRevisorEsSolicitante) {
		return shared.NewPermissionError()
	}
	return err
}

// fechaEnZona interpreta la fecha AAAA-MM-DD de la sesión en la zona institucional.
func fechaEnZona(fecha string) (time.Time, error) {
	return time.ParseInLocation("2006-01-02", fecha, shared.ZonaInstitucional())
}
