// Package dto — Data Transfer Objects para validación de geometría (US-GEO-04).
package dto

import "github.com/siaa/backend/internal/domain/geo"

// ValidarGeometriaRequest representa la carga útil para la validación seca de geometría (AC-05).
type ValidarGeometriaRequest struct {
	Coordenadas [][2]float64 `json:"coordenadas" validate:"required"`
	MinAreaM2   float64      `json:"minAreaM2,omitempty"`
	MaxAreaM2   float64      `json:"maxAreaM2,omitempty"`
}

// ConflictoSegmentoResponse describe dos aristas que se cruzan entre sí (AC-02).
type ConflictoSegmentoResponse struct {
	AristaA [2][2]float64 `json:"aristaA"`
	AristaB [2][2]float64 `json:"aristaB"`
}

// ValidarGeometriaResponse es la respuesta estructurada de diagnóstico geométrico.
type ValidarGeometriaResponse struct {
	Valido              bool                        `json:"valido"`
	Codigo              string                      `json:"codigo,omitempty"`
	Mensaje             string                      `json:"mensaje,omitempty"`
	AreaMetrosCuadrados float64                     `json:"areaMetrosCuadrados"`
	PerimetroMetros     float64                     `json:"perimetroMetros"`
	Centroide           *CentroideResponse          `json:"centroide,omitempty"`
	PoligonoCerrado     bool                        `json:"poligonoCerrado"`
	SegmentosConflicto  []ConflictoSegmentoResponse `json:"segmentosConflicto,omitempty"`
	Advertencias        []string                    `json:"advertencias,omitempty"`
}

// ValidarGeometriaToResponse mapea el resultado de dominio a DTO de respuesta.
func ValidarGeometriaToResponse(res geo.ResultadoValidacionGeometria) ValidarGeometriaResponse {
	var conflictos []ConflictoSegmentoResponse
	if len(res.SegmentosConflicto) > 0 {
		conflictos = make([]ConflictoSegmentoResponse, len(res.SegmentosConflicto))
		for i, c := range res.SegmentosConflicto {
			conflictos[i] = ConflictoSegmentoResponse{
				AristaA: c.AristaA,
				AristaB: c.AristaB,
			}
		}
	}

	resp := ValidarGeometriaResponse{
		Valido:              res.Valido,
		Codigo:              res.Codigo,
		Mensaje:             res.Mensaje,
		AreaMetrosCuadrados: res.AreaMetrosCuadrados,
		PerimetroMetros:     res.PerimetroMetros,
		PoligonoCerrado:     res.PoligonoCerrado,
		SegmentosConflicto:  conflictos,
		Advertencias:        res.Advertencias,
	}
	if res.Centroide != nil {
		resp.Centroide = &CentroideResponse{
			Tipo:        "Point",
			Coordinates: res.Centroide.Coordinates(),
		}
	}
	return resp
}
