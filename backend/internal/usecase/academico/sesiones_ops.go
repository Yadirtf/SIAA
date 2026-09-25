// Package academico — operaciones puntuales sobre sesiones de clase.
// Satisface US-ACA-06 (reasignación puntual), US-ACA-08 (cancelación de sesión) y US-MAR-01 (consulta de sesión).
package academico

import (
	"context"
	"fmt"

	"github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/repository"
)

// ListarSesiones consulta sesiones aplicando los filtros especificados.
func (s *Service) ListarSesiones(ctx context.Context, filter repository.SesionFilter) ([]*academico.Sesion, error) {
	if s.sesionRepo == nil {
		return []*academico.Sesion{}, nil
	}
	return s.sesionRepo.List(ctx, filter)
}

// ObtenerSesionPorID recupera una sesión por su identificador único.
func (s *Service) ObtenerSesionPorID(ctx context.Context, id string) (*academico.Sesion, error) {
	if s.sesionRepo == nil {
		return nil, shared.NewNotFoundError("Sesion", id)
	}
	sesion, err := s.sesionRepo.FindByID(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("obtener sesion: %w", err)
	}
	if sesion == nil {
		return nil, shared.NewNotFoundError("Sesion", id)
	}
	return sesion, nil
}

// CancelarSesion cancela administrativamente una sesión de clase con motivo auditado (US-ACA-08).
func (s *Service) CancelarSesion(ctx context.Context, id, motivo string, actor ContextoActor) error {
	sesion, err := s.ObtenerSesionPorID(ctx, id)
	if err != nil {
		return err
	}

	valAnt := map[string]interface{}{"estado": sesion.Estado()}
	if err := sesion.Cancelar(motivo, s.clk.Now()); err != nil {
		return err
	}

	if err := s.sesionRepo.Update(ctx, sesion); err != nil {
		return fmt.Errorf("actualizar sesion cancelada: %w", err)
	}

	s.auditar(ctx, "sesion", id, "SESION_CANCELADA", actor, valAnt, map[string]interface{}{
		"estado": sesion.Estado(),
		"motivo": motivo,
	})
	return nil
}

// ReasignarAulaSesion actualiza el aula de una sesión puntual y congela la versión de la nueva geometría (US-ACA-06).
func (s *Service) ReasignarAulaSesion(ctx context.Context, sesionID, nuevoEspacioID, motivo string, actor ContextoActor) (*academico.Sesion, error) {
	sesion, err := s.ObtenerSesionPorID(ctx, sesionID)
	if err != nil {
		return nil, err
	}

	espacio, err := s.espacioRepo.FindByID(ctx, nuevoEspacioID)
	if err != nil || espacio == nil {
		return nil, shared.NewNotFoundError("Espacio", nuevoEspacioID)
	}

	valAnt := map[string]interface{}{
		"espacioId":        sesion.EspacioID(),
		"versionGeometria": sesion.EspacioVersionGeometria(),
	}

	sesion.ReasignarEspacio(
		espacio.ID,
		espacio.VersionGeometria,
		espacio.Geometria,
		espacio.GeometriaBuffer,
		s.clk.Now(),
	)

	if err := s.sesionRepo.Update(ctx, sesion); err != nil {
		return nil, fmt.Errorf("actualizar aula de sesion: %w", err)
	}

	s.auditar(ctx, "sesion", sesionID, "AULA_SESION_REASIGNADA", actor, valAnt, map[string]interface{}{
		"nuevoEspacioId":   nuevoEspacioID,
		"versionGeometria": espacio.VersionGeometria,
		"motivo":           motivo,
	})

	return sesion, nil
}

// AsignarDocenteReemplazo designa un docente suplente para una sesión puntual (US-ACA-09).
func (s *Service) AsignarDocenteReemplazo(ctx context.Context, sesionID, nuevoDocenteID, motivo string, actor ContextoActor) (*academico.Sesion, error) {
	if nuevoDocenteID == "" {
		return nil, shared.NewValidationError("El identificador del nuevo docente es obligatorio", shared.FieldError{
			Campo: "docenteId", Error: "REQUERIDO",
		})
	}

	sesion, err := s.ObtenerSesionPorID(ctx, sesionID)
	if err != nil {
		return nil, err
	}

	valAnt := map[string]interface{}{
		"docenteIds": sesion.DocenteIDs(),
	}

	if err := sesion.AsignarDocenteReemplazo(nuevoDocenteID, s.clk.Now()); err != nil {
		return nil, err
	}

	if err := s.sesionRepo.Update(ctx, sesion); err != nil {
		return nil, fmt.Errorf("actualizar docente de sesion: %w", err)
	}

	s.auditar(ctx, "sesion", sesionID, "DOCENTE_REEMPLAZO_ASIGNADO", actor, valAnt, map[string]interface{}{
		"nuevoDocenteId": nuevoDocenteID,
		"motivo":         motivo,
	})

	return sesion, nil
}
