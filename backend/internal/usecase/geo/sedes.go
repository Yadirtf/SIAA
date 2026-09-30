// Package geo — casos de uso para la gestión de sedes físicas (US-GEO-01).
package geo

import (
	"context"
	"fmt"

	"github.com/siaa/backend/internal/domain/geo"
	"github.com/siaa/backend/internal/domain/shared"
)

// CrearSede registra una nueva sede física en el sistema.
func (s *Service) CrearSede(ctx context.Context, cmd CrearSedeCmd) (*geo.Sede, error) {
	if err := geo.ValidarSede(cmd.Codigo, cmd.Nombre); err != nil {
		return nil, err
	}

	existente, err := s.sedeRepo.FindByCodigo(ctx, cmd.Codigo)
	if err != nil {
		return nil, fmt.Errorf("verificar codigo sede: %w", err)
	}
	if existente != nil {
		return nil, &shared.DomainError{
			Code:    shared.ErrConflictoUnicidad,
			Message: fmt.Sprintf("Ya existe una sede con el código '%s'", cmd.Codigo),
		}
	}

	now := s.clk.Now()
	sede := &geo.Sede{
		Codigo:        cmd.Codigo,
		Nombre:        cmd.Nombre,
		Direccion:     cmd.Direccion,
		Activo:        true,
		Eliminado:     false,
		CreadoEn:      now,
		ActualizadoEn: now,
	}

	if err := s.sedeRepo.Create(ctx, sede); err != nil {
		return nil, fmt.Errorf("guardar sede: %w", err)
	}

	s.auditar(ctx, "sede", sede.ID, "SEDE_CREADA", cmd.Actor, nil, sede)
	return sede, nil
}

// ListarSedes retorna todas las sedes registradas activas.
func (s *Service) ListarSedes(ctx context.Context) ([]*geo.Sede, error) {
	return s.sedeRepo.List(ctx)
}

// ObtenerSedePorID busca una sede por su identificador único.
func (s *Service) ObtenerSedePorID(ctx context.Context, id string) (*geo.Sede, error) {
	sede, err := s.sedeRepo.FindByID(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("obtener sede: %w", err)
	}
	if sede == nil {
		return nil, shared.NewNotFoundError("Sede", id)
	}
	return sede, nil
}
