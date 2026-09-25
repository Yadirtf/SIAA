// Package geo — caso de uso para validación seca de geometría (US-GEO-04).
package geo

import (
	"context"

	domainGeo "github.com/siaa/backend/internal/domain/geo"
)

// ValidarGeometriaCmd contiene los parámetros de validación enviados por el cliente.
type ValidarGeometriaCmd struct {
	Coordenadas [][2]float64
	MinAreaM2   float64
	MaxAreaM2   float64
}

// ValidarGeometria ejecuta la verificación geométrica de polígonos sin persistir datos (AC-05, T-GEO-04.3).
func (s *Service) ValidarGeometria(ctx context.Context, cmd ValidarGeometriaCmd) domainGeo.ResultadoValidacionGeometria {
	return domainGeo.ValidarGeometriaPoligono(cmd.Coordenadas, cmd.MinAreaM2, cmd.MaxAreaM2)
}
