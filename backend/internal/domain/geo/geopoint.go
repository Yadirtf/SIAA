// Package geo — tipos fundamentales de coordenadas y polígonos.
// ADR-04: coordenadas obligatorias en orden [longitud, latitud].
// RF-GEO-002, RF-GEO-012, T-GEO-02.1.
package geo

import (
	"encoding/json"
	"fmt"

	"github.com/siaa/backend/internal/domain/shared"
)

// GeoPoint representa un punto geográfico inmutable en el sistema WGS84.
// ADR-04: el orden es estrictamente [longitud, latitud].
type GeoPoint struct {
	longitud float64
	latitud  float64
}

// NewGeoPoint es el único constructor permitido para crear un GeoPoint.
// Valida rangos: longitud ∈ [-180, 180], latitud ∈ [-90, 90].
// Invariante ADR-04: primer argumento es LONGITUD, segundo argumento es LATITUD.
func NewGeoPoint(longitud, latitud float64) (GeoPoint, error) {
	var fields []shared.FieldError
	if longitud < -180 || longitud > 180 {
		fields = append(fields, shared.FieldError{
			Campo: "longitud",
			Error: fmt.Sprintf("Longitud %.6f fuera de rango válido [-180, 180]", longitud),
		})
	}
	if latitud < -90 || latitud > 90 {
		fields = append(fields, shared.FieldError{
			Campo: "latitud",
			Error: fmt.Sprintf("Latitud %.6f fuera de rango válido [-90, 90]", latitud),
		})
	}
	if len(fields) > 0 {
		return GeoPoint{}, shared.NewValidationError("Coordenada geográfica fuera de rango", fields...)
	}
	return GeoPoint{longitud: longitud, latitud: latitud}, nil
}

// Longitud retorna la longitud geográfica en grados decimales.
func (p GeoPoint) Longitud() float64 {
	return p.longitud
}

// Latitud retorna la latitud geográfica en grados decimales.
func (p GeoPoint) Latitud() float64 {
	return p.latitud
}

// Coordinates retorna el par [longitud, latitud] en formato GeoJSON.
func (p GeoPoint) Coordinates() [2]float64 {
	return [2]float64{p.longitud, p.latitud}
}

// MarshalJSON serializa el punto como un array GeoJSON [lon, lat].
func (p GeoPoint) MarshalJSON() ([]byte, error) {
	return json.Marshal([]float64{p.longitud, p.latitud})
}

// UnmarshalJSON deserializa un array GeoJSON [lon, lat].
func (p *GeoPoint) UnmarshalJSON(data []byte) error {
	var coords []float64
	if err := json.Unmarshal(data, &coords); err != nil {
		return fmt.Errorf("GeoPoint JSON invalido: %w", err)
	}
	if len(coords) != 2 {
		return fmt.Errorf("GeoPoint requiere exactamente 2 elementos [lon, lat], recibidos: %d", len(coords))
	}
	pt, err := NewGeoPoint(coords[0], coords[1])
	if err != nil {
		return err
	}
	*p = pt
	return nil
}
