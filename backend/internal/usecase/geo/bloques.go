// Package geo — casos de uso para la gestión de bloques físicos (US-GEO-01).
package geo

import (
	"context"
	"fmt"

	"github.com/siaa/backend/internal/domain/geo"
	"github.com/siaa/backend/internal/domain/shared"
)

// CrearBloque registra un nuevo bloque asociado a una sede física.
func (s *Service) CrearBloque(ctx context.Context, cmd CrearBloqueCmd) (*geo.Bloque, error) {
	if err := geo.ValidarBloque(cmd.SedeID, cmd.Codigo, cmd.Nombre); err != nil {
		return nil, err
	}

	sede, err := s.sedeRepo.FindByID(ctx, cmd.SedeID)
	if err != nil {
		return nil, fmt.Errorf("verificar sede: %w", err)
	}
	if sede == nil {
		return nil, shared.NewNotFoundError("Sede", cmd.SedeID)
	}

	existente, err := s.bloqueRepo.FindByCodigo(ctx, cmd.SedeID, cmd.Codigo)
	if err != nil {
		return nil, fmt.Errorf("verificar codigo bloque: %w", err)
	}
	if existente != nil {
		return nil, &shared.DomainError{
			Code:    shared.ErrConflictoUnicidad,
			Message: fmt.Sprintf("Ya existe un bloque con el código '%s' en esta sede", cmd.Codigo),
		}
	}

	now := s.clk.Now()
	bloque := &geo.Bloque{
		SedeID:        cmd.SedeID,
		Codigo:        cmd.Codigo,
		Nombre:        cmd.Nombre,
		Pisos:         cmd.Pisos,
		Activo:        true,
		Eliminado:     false,
		CreadoEn:      now,
		ActualizadoEn: now,
	}

	if err := s.bloqueRepo.Create(ctx, bloque); err != nil {
		return nil, fmt.Errorf("guardar bloque: %w", err)
	}

	s.auditar(ctx, "bloque", bloque.ID, "BLOQUE_CREADO", cmd.Actor, nil, bloque)
	return bloque, nil
}

// ListarBloques retorna los bloques registrados, opcionalmente filtrados por sede.
func (s *Service) ListarBloques(ctx context.Context, sedeID string) ([]*geo.Bloque, error) {
	if sedeID != "" {
		return s.bloqueRepo.ListBySede(ctx, sedeID)
	}
	return s.bloqueRepo.List(ctx)
}

// ObtenerBloquePorID busca un bloque por su ID.
func (s *Service) ObtenerBloquePorID(ctx context.Context, id string) (*geo.Bloque, error) {
	bloque, err := s.bloqueRepo.FindByID(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("obtener bloque: %w", err)
	}
	if bloque == nil {
		return nil, shared.NewNotFoundError("Bloque", id)
	}
	return bloque, nil
}
