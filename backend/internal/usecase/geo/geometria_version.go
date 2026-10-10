package geo

import (
	"context"
	"fmt"
	"strconv"

	"github.com/siaa/backend/internal/domain/geo"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/repository"
)

// conflictoVersion construye el 409 de la precondición optimista. Contexto lleva la versión
// vigente para que el cliente recargue y ofrezca reaplicar su edición (US-GEO-10 AC-04).
func conflictoVersion(espacioID string, esperada, vigente int) *shared.DomainError {
	return &shared.DomainError{
		Code: shared.ErrConflictoVersion,
		Message: fmt.Sprintf("La geometría del espacio cambió (versión vigente %d, editada sobre la %d). "+
			"Recargue el espacio y vuelva a aplicar su edición.", vigente, esperada),
		Fields: []shared.FieldError{{Campo: "versionEsperada", Error: "VERSION_DESACTUALIZADA"}},
		Contexto: map[string]string{
			"espacioId":       espacioID,
			"versionEsperada": strconv.Itoa(esperada),
			"versionVigente":  strconv.Itoa(vigente),
		},
	}
}

// verificarVersionEsperada aplica la precondición enviada por el cliente (If-Match o
// versionEsperada). Sin precondición no se exige nada: compatibilidad con clientes previos.
func verificarVersionEsperada(espacio *geo.Espacio, esperada *int) error {
	if esperada == nil || *esperada == espacio.VersionGeometria {
		return nil
	}
	return conflictoVersion(espacio.ID, *esperada, espacio.VersionGeometria)
}

// persistirGeometria guarda el espacio solo si nadie cambió su geometría desde que se leyó.
// Si el repositorio no ofrece compare-and-set se usa la actualización simple.
func (s *Service) persistirGeometria(ctx context.Context, espacio *geo.Espacio, versionLeida int) error {
	cas, ok := s.espacioRepo.(repository.EspacioActualizadorVersionado)
	if !ok {
		if err := s.espacioRepo.Update(ctx, espacio); err != nil {
			return fmt.Errorf("guardar geometria espacio: %w", err)
		}
		return nil
	}
	aplicado, err := cas.UpdateSiVersion(ctx, espacio, versionLeida)
	if err != nil {
		return fmt.Errorf("guardar geometria espacio: %w", err)
	}
	if aplicado {
		return nil
	}
	vigente := versionLeida
	if actual, errF := s.espacioRepo.FindByID(ctx, espacio.ID); errF == nil && actual != nil {
		vigente = actual.VersionGeometria
	}
	return conflictoVersion(espacio.ID, versionLeida, vigente)
}
