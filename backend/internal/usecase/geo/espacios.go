// Package geo — casos de uso para gestión de espacios físicos y actualización de buffer.
// Satisface US-GEO-01, US-GEO-04, US-GEO-08 (AC-01..AC-03).
package geo

import (
	"context"
	"fmt"
	"strings"

	"github.com/siaa/backend/internal/domain/geo"
	"github.com/siaa/backend/internal/domain/shared"
	applog "github.com/siaa/backend/internal/platform/log"
	"github.com/siaa/backend/internal/repository"
)

// CrearEspacio implementa AC-01, AC-02, AC-03, AC-04 de US-GEO-01.
func (s *Service) CrearEspacio(ctx context.Context, cmd CrearEspacioCmd) (*geo.Espacio, error) {
	if cmd.Estado == "" {
		cmd.Estado = geo.EstadoActivo
	}
	if cmd.NivelValidacion == "" {
		cmd.NivelValidacion = geo.NivelAula
	}
	if cmd.BufferMetros <= 0 {
		cmd.BufferMetros = 10.0 // buffer por defecto
	}

	if err := geo.ValidarEspacio(cmd.SedeID, cmd.Codigo, cmd.Nombre, cmd.Tipo, cmd.Estado, cmd.Capacidad); err != nil {
		return nil, err
	}

	sede, err := s.sedeRepo.FindByID(ctx, cmd.SedeID)
	if err != nil {
		return nil, fmt.Errorf("verificar sede de espacio: %w", err)
	}
	if sede == nil {
		return nil, shared.NewNotFoundError("Sede", cmd.SedeID)
	}

	if cmd.BloqueID != nil && strings.TrimSpace(*cmd.BloqueID) != "" {
		bloque, err := s.bloqueRepo.FindByID(ctx, *cmd.BloqueID)
		if err != nil {
			return nil, fmt.Errorf("verificar bloque de espacio: %w", err)
		}
		if bloque == nil {
			return nil, shared.NewNotFoundError("Bloque", *cmd.BloqueID)
		}
		if bloque.SedeID != cmd.SedeID {
			return nil, shared.NewValidationError("Jerarquía inválida", shared.FieldError{
				Campo: "bloqueId",
				Error: "El bloque indicado no pertenece a la sede especificada",
			})
		}
	}

	existente, err := s.espacioRepo.FindByCodigo(ctx, cmd.Codigo)
	if err != nil {
		return nil, fmt.Errorf("verificar codigo espacio: %w", err)
	}
	if existente != nil {
		return nil, &shared.DomainError{
			Code:    shared.ErrConflictoUnicidad,
			Message: fmt.Sprintf("Ya existe un espacio con el código '%s'", cmd.Codigo),
		}
	}

	now := s.clk.Now()
	espacio := &geo.Espacio{
		SedeID:              cmd.SedeID,
		Torre:               cmd.Torre,
		BloqueID:            cmd.BloqueID,
		Piso:                cmd.Piso,
		Codigo:              cmd.Codigo,
		Nombre:              cmd.Nombre,
		Capacidad:           cmd.Capacidad,
		Tipo:                cmd.Tipo,
		FacultadResponsable: cmd.FacultadResponsable,
		Estado:              cmd.Estado,
		NivelValidacion:     cmd.NivelValidacion,
		BufferMetros:        cmd.BufferMetros,
		VersionGeometria:    0,
		Activo:              cmd.Estado == geo.EstadoActivo,
		Eliminado:           false,
		CreadoEn:            now,
		ActualizadoEn:       now,
	}

	if err := s.espacioRepo.Create(ctx, espacio); err != nil {
		return nil, fmt.Errorf("guardar espacio: %w", err)
	}

	s.auditar(ctx, "espacio", espacio.ID, "ESPACIO_CREADO", cmd.Actor, nil, espacio)
	return espacio, nil
}

// ListarEspacios lista espacios filtrados.
func (s *Service) ListarEspacios(ctx context.Context, filter repository.EspacioFilter) ([]*geo.Espacio, error) {
	return s.espacioRepo.List(ctx, filter)
}

// ObtenerEspacioPorID obtiene un espacio por su identificador.
func (s *Service) ObtenerEspacioPorID(ctx context.Context, id string) (*geo.Espacio, error) {
	espacio, err := s.espacioRepo.FindByID(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("obtener espacio: %w", err)
	}
	if espacio == nil {
		return nil, shared.NewNotFoundError("Espacio", id)
	}
	return espacio, nil
}

// ActualizarEspacio modifica atributos del espacio y verifica impacto en sesiones futuras (AC-04, AC-05).
func (s *Service) ActualizarEspacio(ctx context.Context, id string, cmd ActualizarEspacioCmd) (*geo.Espacio, error) {
	espacio, err := s.espacioRepo.FindByID(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("obtener espacio a actualizar: %w", err)
	}
	if espacio == nil {
		return nil, shared.NewNotFoundError("Espacio", id)
	}

	valorAnterior := *espacio

	if cmd.Codigo != nil && *cmd.Codigo != espacio.Codigo {
		existente, err := s.espacioRepo.FindByCodigo(ctx, *cmd.Codigo)
		if err != nil {
			return nil, fmt.Errorf("verificar codigo espacio: %w", err)
		}
		if existente != nil && existente.ID != id {
			return nil, &shared.DomainError{
				Code:    shared.ErrConflictoUnicidad,
				Message: fmt.Sprintf("Ya existe otro espacio con el código '%s'", *cmd.Codigo),
			}
		}
		espacio.Codigo = *cmd.Codigo
	}

	if cmd.SedeID != nil && *cmd.SedeID != espacio.SedeID {
		sede, err := s.sedeRepo.FindByID(ctx, *cmd.SedeID)
		if err != nil || sede == nil {
			return nil, shared.NewNotFoundError("Sede", *cmd.SedeID)
		}
		espacio.SedeID = *cmd.SedeID
	}

	if cmd.BloqueID != nil && *cmd.BloqueID != "" {
		bloque, err := s.bloqueRepo.FindByID(ctx, *cmd.BloqueID)
		if err != nil || bloque == nil {
			return nil, shared.NewNotFoundError("Bloque", *cmd.BloqueID)
		}
		if bloque.SedeID != espacio.SedeID {
			return nil, shared.NewValidationError("Jerarquía inválida", shared.FieldError{
				Campo: "bloqueId",
				Error: "El bloque indicado no pertenece a la sede del espacio",
			})
		}
		espacio.BloqueID = cmd.BloqueID
	} else if cmd.BloqueID != nil && *cmd.BloqueID == "" {
		espacio.BloqueID = nil
	}

	if cmd.Torre != nil {
		espacio.Torre = cmd.Torre
	}
	if cmd.Piso != nil {
		espacio.Piso = cmd.Piso
	}
	if cmd.Nombre != nil && strings.TrimSpace(*cmd.Nombre) != "" {
		espacio.Nombre = *cmd.Nombre
	}
	if cmd.Capacidad != nil && *cmd.Capacidad >= 0 {
		espacio.Capacidad = *cmd.Capacidad
	}
	if cmd.Tipo != nil && geo.EsTipoEspacioValido(*cmd.Tipo) {
		espacio.Tipo = *cmd.Tipo
	}
	if cmd.FacultadResponsable != nil {
		espacio.FacultadResponsable = *cmd.FacultadResponsable
	}
	if cmd.NivelValidacion != nil && geo.EsNivelValidacionValido(*cmd.NivelValidacion) {
		espacio.NivelValidacion = *cmd.NivelValidacion
	}
	if cmd.BufferMetros != nil && *cmd.BufferMetros > 0 {
		_ = espacio.ActualizarBuffer(*cmd.BufferMetros)
	}

	if cmd.Estado != nil && geo.EsEstadoEspacioValido(*cmd.Estado) {
		nuevoEstado := *cmd.Estado
		if (nuevoEstado == geo.EstadoInactivo || nuevoEstado == geo.EstadoMantenimiento) && espacio.Estado == geo.EstadoActivo {
			if s.sesionChecker != nil {
				afectadas, err := s.sesionChecker.CountSesionesFuturasPorEspacio(ctx, id, s.clk.Now())
				if err != nil {
					s.log.Warn("no se pudo verificar sesiones futuras del espacio", applog.Err(err))
				} else if afectadas > 0 && !cmd.ConfirmarImpacto {
					return nil, &shared.DomainError{
						Code:    shared.ErrValidacion,
						Message: fmt.Sprintf("El espacio tiene %d sesiones futuras programadas. Requiere confirmación explícita para pasar a estado %s.", afectadas, nuevoEstado),
						Fields: []shared.FieldError{
							{Campo: "confirmarImpacto", Error: fmt.Sprintf("afecta_%d_sesiones_futuras", afectadas)},
						},
					}
				}
			}
		}
		espacio.Estado = nuevoEstado
		espacio.Activo = nuevoEstado == geo.EstadoActivo
	}

	espacio.ActualizadoEn = s.clk.Now()

	if err := s.espacioRepo.Update(ctx, espacio); err != nil {
		return nil, fmt.Errorf("actualizar espacio: %w", err)
	}

	s.auditar(ctx, "espacio", espacio.ID, "ESPACIO_ACTUALIZADO", cmd.Actor, valorAnterior, espacio)
	return espacio, nil
}

// EliminarEspacio borra lógicamente el espacio (AC-06).
func (s *Service) EliminarEspacio(ctx context.Context, id string, actor ContextoActor) error {
	espacio, err := s.espacioRepo.FindByID(ctx, id)
	if err != nil {
		return fmt.Errorf("obtener espacio a eliminar: %w", err)
	}
	if espacio == nil {
		return shared.NewNotFoundError("Espacio", id)
	}

	if err := s.espacioRepo.SoftDelete(ctx, id); err != nil {
		return fmt.Errorf("borrado logico espacio: %w", err)
	}

	s.auditar(ctx, "espacio", id, "ESPACIO_ELIMINADO", actor, espacio, map[string]interface{}{"eliminado": true})
	return nil
}

// ActualizarBuffer recalcula y persiste el polígono expandido sin recapturar vértices (US-GEO-08 AC-01, AC-02).
func (s *Service) ActualizarBuffer(ctx context.Context, cmd ActualizarBufferCmd) (*geo.Espacio, error) {
	espacio, err := s.espacioRepo.FindByID(ctx, cmd.EspacioID)
	if err != nil {
		return nil, fmt.Errorf("obtener espacio para buffer: %w", err)
	}
	if espacio == nil {
		return nil, shared.NewNotFoundError("Espacio", cmd.EspacioID)
	}

	valorAnterior := *espacio

	if err := espacio.ActualizarBuffer(cmd.BufferMetros); err != nil {
		return nil, err
	}

	if err := s.espacioRepo.Update(ctx, espacio); err != nil {
		return nil, fmt.Errorf("guardar buffer espacio: %w", err)
	}

	s.auditar(ctx, "espacio", espacio.ID, "BUFFER_ACTUALIZADO", cmd.Actor, valorAnterior, espacio)
	return espacio, nil
}
