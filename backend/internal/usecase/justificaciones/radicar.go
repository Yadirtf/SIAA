package justificaciones

import (
	"context"
	"errors"
	"fmt"

	"github.com/siaa/backend/internal/domain/justificacion"
	"github.com/siaa/backend/internal/domain/marcaje"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/repository"
)

// SolicitudRadicar son los datos que envía el docente desde la app (RF-JUS-001).
type SolicitudRadicar struct {
	SesionID    string
	Tipo        justificacion.Tipo
	Descripcion string
	Soportes    []Archivo
}

// Radicar crea la justificación sobre una sesión propia, ya iniciada, sin asistencia válida
// y dentro del plazo. Los soportes se guardan cifrados antes de registrar la novedad.
func (s *Service) Radicar(ctx context.Context, actor Actor, req SolicitudRadicar) (*justificacion.Justificacion, error) {
	ahora := s.clock.Now()
	sesion, err := s.sesiones.FindByID(ctx, req.SesionID)
	if err != nil {
		return nil, fmt.Errorf("buscar sesión: %w", err)
	}
	if sesion == nil {
		return nil, shared.NewNotFoundError("sesión", req.SesionID)
	}
	if !sesion.TieneDocente(actor.UsuarioID) {
		return nil, shared.NewScopeError()
	}
	if ahora.Before(sesion.InicioProgramado()) {
		return nil, shared.NewValidationError("solo se justifican sesiones que ya iniciaron")
	}
	fecha, err := fechaEnZona(sesion.Fecha())
	if err != nil {
		return nil, fmt.Errorf("fecha de sesión inválida: %w", err)
	}
	if !justificacion.DentroDelPlazo(fecha, ahora, s.plazoDias) {
		return nil, shared.NewValidationError(fmt.Sprintf("el plazo para justificar es de %d días hábiles después de la sesión", s.plazoDias))
	}
	entrada, err := s.marcajes.ObtenerPrevio(ctx, sesion.ID(), actor.UsuarioID, marcaje.TipoEntrada)
	if err != nil {
		return nil, fmt.Errorf("consultar asistencia: %w", err)
	}
	if entrada != nil && entrada.EsExitoso() {
		return nil, shared.NewValidationError("la sesión ya tiene asistencia registrada; no requiere justificación")
	}
	if previa, err := s.justificaciones.ObtenerVigente(ctx, sesion.ID(), actor.UsuarioID); err != nil {
		return nil, err
	} else if previa != nil {
		return nil, conflictoVigente()
	}

	adjuntos, err := validarSoportes(req.Soportes)
	if err != nil {
		return nil, err
	}
	j, err := justificacion.Nueva(sesion.ID(), actor.UsuarioID, req.Tipo, req.Descripcion, adjuntos, ahora)
	if err != nil {
		return nil, errorDominio(err)
	}
	j.SedeID = sesion.SedeID()
	j.FacultadID = sesion.FacultadID()
	j.FechaSesion = sesion.Fecha()
	j.NombreSesion = fmt.Sprintf("%s %s-%s", sesion.Fecha(), sesion.HoraInicio(), sesion.HoraFin())

	for i, a := range adjuntos {
		if err := s.adjuntos.Guardar(ctx, a.ID, req.Soportes[i].Contenido); err != nil {
			return nil, err
		}
	}
	if err := s.justificaciones.Crear(ctx, j); err != nil {
		if errors.Is(err, repository.ErrJustificacionModificada) {
			return nil, conflictoVigente()
		}
		return nil, err
	}
	s.auditar(ctx, actor, "JUSTIFICACION_RADICADA", j.ID, nil, j)
	return j, nil
}

func conflictoVigente() error {
	return &shared.DomainError{
		Code:    shared.ErrConflictoUnicidad,
		Message: "Ya existe una justificación en curso o aprobada para esta sesión",
	}
}
