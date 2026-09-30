// Package academico — resolución de parámetros efectivos al generar sesiones (RN-002).
package academico

import (
	"context"

	"github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/domain/geo"
)

// parametrosEfectivos consulta la cascada jerárquica para la asignación. Si no hay resolutor
// configurado o la consulta falla, devuelve nil y la sesión se congela con los valores por defecto.
func (s *Service) parametrosEfectivos(ctx context.Context, sedePeriodo string, asig *academico.Asignacion, espacio *geo.Espacio) map[string]interface{} {
	if s.resolutor == nil {
		return nil
	}
	ambito := AmbitoParametros{
		SedeID:       sedePeriodo,
		FacultadID:   asig.FacultadID(),
		EspacioID:    asig.EspacioID(),
		AsignacionID: asig.ID(),
	}
	if espacio != nil {
		if espacio.SedeID != "" {
			ambito.SedeID = espacio.SedeID
		}
		if espacio.BloqueID != nil {
			ambito.BloqueID = *espacio.BloqueID
		}
	}
	valores, err := s.resolutor(ctx, ambito)
	if err != nil {
		if s.log != nil {
			s.log.Error("no se pudieron resolver los parámetros efectivos; se usan valores por defecto")
		}
		return nil
	}
	return valores
}
