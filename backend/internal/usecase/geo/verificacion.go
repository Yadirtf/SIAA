// Package geo — configuración de la verificación complementaria de un espacio (RF-GEO-016).
package geo

import (
	"context"
	"fmt"

	"github.com/siaa/backend/internal/domain/geo"
	"github.com/siaa/backend/internal/domain/shared"
)

// ActualizarVerificacionCmd reemplaza los valores de verificación complementaria del espacio.
type ActualizarVerificacionCmd struct {
	EspacioID    string
	Verificacion geo.VerificacionEspacio
	Actor        ContextoActor
}

// ActualizarVerificacion normaliza, valida y guarda los BSSID, la baliza BLE y el QR del aula.
// Enviar todos los valores vacíos elimina la verificación del espacio.
func (s *Service) ActualizarVerificacion(ctx context.Context, cmd ActualizarVerificacionCmd) (*geo.Espacio, error) {
	v := cmd.Verificacion
	v.Normalizar()
	if err := v.Validar(); err != nil {
		return nil, err
	}

	espacio, err := s.espacioRepo.FindByID(ctx, cmd.EspacioID)
	if err != nil {
		return nil, fmt.Errorf("obtener espacio para verificación: %w", err)
	}
	if espacio == nil {
		return nil, shared.NewNotFoundError("Espacio", cmd.EspacioID)
	}

	valorAnterior := *espacio
	if len(v.Metodos()) == 0 {
		espacio.VerificacionComplementaria = nil
	} else {
		espacio.VerificacionComplementaria = &v
	}
	if err := s.espacioRepo.Update(ctx, espacio); err != nil {
		return nil, fmt.Errorf("guardar verificación del espacio: %w", err)
	}

	s.auditar(ctx, "espacio", espacio.ID, "VERIFICACION_COMPLEMENTARIA_ACTUALIZADA", cmd.Actor, valorAnterior, espacio)
	return espacio, nil
}
