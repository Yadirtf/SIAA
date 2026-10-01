// Package geo — edición de sedes y bloques (US-GEO-01): corregir códigos y nombres.
package geo

import (
	"context"
	"fmt"
	"strings"

	"github.com/siaa/backend/internal/domain/geo"
	"github.com/siaa/backend/internal/domain/shared"
)

// ActualizarSede cambia código, nombre y dirección de una sede. El código sigue siendo único.
func (s *Service) ActualizarSede(ctx context.Context, id string, cmd CrearSedeCmd) (*geo.Sede, error) {
	cmd.Codigo, cmd.Nombre = strings.TrimSpace(cmd.Codigo), strings.TrimSpace(cmd.Nombre)
	if err := geo.ValidarSede(cmd.Codigo, cmd.Nombre); err != nil {
		return nil, err
	}
	sede, err := s.ObtenerSedePorID(ctx, id)
	if err != nil {
		return nil, err
	}
	if !strings.EqualFold(sede.Codigo, cmd.Codigo) {
		otra, err := s.sedeRepo.FindByCodigo(ctx, cmd.Codigo)
		if err != nil {
			return nil, fmt.Errorf("verificar codigo sede: %w", err)
		}
		if otra != nil && otra.ID != id {
			return nil, &shared.DomainError{
				Code:    shared.ErrConflictoUnicidad,
				Message: fmt.Sprintf("Ya existe una sede con el código '%s'", cmd.Codigo),
			}
		}
	}
	antes := *sede
	sede.Codigo, sede.Nombre, sede.Direccion = cmd.Codigo, cmd.Nombre, strings.TrimSpace(cmd.Direccion)
	sede.ActualizadoEn = s.clk.Now()
	if err := s.sedeRepo.Update(ctx, sede); err != nil {
		return nil, fmt.Errorf("actualizar sede: %w", err)
	}
	s.auditar(ctx, "sede", id, "SEDE_ACTUALIZADA", cmd.Actor, antes, sede)
	return sede, nil
}

// ActualizarBloque cambia código y nombre de un bloque y permite agregar pisos. La sede no cambia
// y no se quitan pisos, porque puede haber aulas registradas en ellos.
func (s *Service) ActualizarBloque(ctx context.Context, id string, cmd CrearBloqueCmd) (*geo.Bloque, error) {
	bloque, err := s.ObtenerBloquePorID(ctx, id)
	if err != nil {
		return nil, err
	}
	cmd.Codigo, cmd.Nombre = strings.TrimSpace(cmd.Codigo), strings.TrimSpace(cmd.Nombre)
	if err := geo.ValidarBloque(bloque.SedeID, cmd.Codigo, cmd.Nombre); err != nil {
		return nil, err
	}
	if !strings.EqualFold(bloque.Codigo, cmd.Codigo) {
		otro, err := s.bloqueRepo.FindByCodigo(ctx, bloque.SedeID, cmd.Codigo)
		if err != nil {
			return nil, fmt.Errorf("verificar codigo bloque: %w", err)
		}
		if otro != nil && otro.ID != id {
			return nil, &shared.DomainError{
				Code:    shared.ErrConflictoUnicidad,
				Message: fmt.Sprintf("Ya existe un bloque con el código '%s' en esta sede", cmd.Codigo),
			}
		}
	}
	antes := *bloque
	bloque.Codigo, bloque.Nombre = cmd.Codigo, cmd.Nombre
	bloque.Pisos = unirPisos(bloque.Pisos, cmd.Pisos)
	bloque.ActualizadoEn = s.clk.Now()
	if err := s.bloqueRepo.Update(ctx, bloque); err != nil {
		return nil, fmt.Errorf("actualizar bloque: %w", err)
	}
	s.auditar(ctx, "bloque", id, "BLOQUE_ACTUALIZADO", cmd.Actor, antes, bloque)
	return bloque, nil
}

// unirPisos conserva los pisos existentes y agrega los nuevos, sin repetir.
func unirPisos(actuales, nuevos []int) []int {
	vistos := make(map[int]bool, len(actuales)+len(nuevos))
	res := make([]int, 0, len(actuales)+len(nuevos))
	for _, p := range append(append([]int{}, actuales...), nuevos...) {
		if !vistos[p] {
			vistos[p] = true
			res = append(res, p)
		}
	}
	return res
}
