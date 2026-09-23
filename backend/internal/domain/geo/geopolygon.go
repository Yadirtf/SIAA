// Package geo — tipos de polígonos geoespaciales y métodos de levantamiento.
// ADR-04: coordenadas en orden GeoJSON [longitud, latitud].
// RF-GEO-002, AC-06, AC-07, T-GEO-02.1.
package geo

import (
	"encoding/json"
	"fmt"

	"github.com/siaa/backend/internal/domain/shared"
)

// MetodoCaptura define la técnica empleada para levantar la geometría del espacio.
type MetodoCaptura string

const (
	MetodoRecorridoPerimetral MetodoCaptura = "RECORRIDO_PERIMETRAL"
	MetodoToqueMapa           MetodoCaptura = "TOQUE_MAPA"
	MetodoMixto               MetodoCaptura = "MIXTO"
	MetodoImportacion         MetodoCaptura = "IMPORTACION"
)

// EsMetodoCapturaValido valida si el método de captura es soportado.
func EsMetodoCapturaValido(m MetodoCaptura) bool {
	switch m {
	case MetodoRecorridoPerimetral, MetodoToqueMapa, MetodoMixto, MetodoImportacion:
		return true
	default:
		return false
	}
}

// GeoPolygon representa un polígono GeoJSON cerrado sobre la superficie terrestre.
type GeoPolygon struct {
	anilloExterior []GeoPoint
}

// NewGeoPolygon construye un polígono validado.
// AC-06: si el primer y último vértice no coinciden, cierra el anillo automáticamente repitiendo el primero.
// Exige al menos 3 vértices distintos.
func NewGeoPolygon(vertices []GeoPoint) (GeoPolygon, error) {
	if len(vertices) < 3 {
		return GeoPolygon{}, &shared.DomainError{
			Code:    shared.ErrGeometriaInvalida,
			Message: fmt.Sprintf("Un polígono requiere al menos 3 vértices distintos, recibidos: %d", len(vertices)),
			Fields: []shared.FieldError{
				{Campo: "vertices", Error: "VERTICES_INSUFICIENTES"},
			},
		}
	}

	copia := make([]GeoPoint, len(vertices))
	copy(copia, vertices)

	primerPunto := copia[0]
	ultimoPunto := copia[len(copia)-1]

	// AC-06: cerrar polígono si no está cerrado
	if primerPunto.Longitud() != ultimoPunto.Longitud() || primerPunto.Latitud() != ultimoPunto.Latitud() {
		copia = append(copia, primerPunto)
	}

	// Debe haber al menos 4 puntos en un anillo cerrado (3 distintos + cierre)
	if len(copia) < 4 {
		return GeoPolygon{}, &shared.DomainError{
			Code:    shared.ErrGeometriaInvalida,
			Message: "El polígono cerrado debe contener al menos 3 vértices distintos",
			Fields: []shared.FieldError{
				{Campo: "vertices", Error: "VERTICES_INSUFICIENTES"},
			},
		}
	}

	// Validar que no existan aristas que se crucen entre sí (auto-intersección / forma de X)
	if hasSelfIntersections(copia) {
		return GeoPolygon{}, &shared.DomainError{
			Code:    shared.ErrGeometriaInvalida,
			Message: "El polígono es inválido: contiene bordes cruzados (auto-intersección). Asegúrese de trazar los vértices en orden perimetral continuo.",
			Fields: []shared.FieldError{
				{Campo: "vertices", Error: "AUTO_INTERSECCION_DETECTADA"},
			},
		}
	}

	copia = asegurarSentidoAntihorario(copia)

	return GeoPolygon{anilloExterior: copia}, nil
}

func ccw(a, b, c GeoPoint) float64 {
	return (b.Longitud()-a.Longitud())*(c.Latitud()-a.Latitud()) - (b.Latitud()-a.Latitud())*(c.Longitud()-a.Longitud())
}

func segmentsIntersect(p1, p2, p3, p4 GeoPoint) bool {
	d1 := ccw(p1, p2, p3)
	d2 := ccw(p1, p2, p4)
	d3 := ccw(p3, p4, p1)
	d4 := ccw(p3, p4, p2)

	return ((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
		((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0))
}

func hasSelfIntersections(vertices []GeoPoint) bool {
	n := len(vertices)
	if n < 4 {
		return false
	}
	numEdges := n - 1
	for i := 0; i < numEdges; i++ {
		for j := i + 1; j < numEdges; j++ {
			if j-i <= 1 {
				continue
			}
			if i == 0 && j == numEdges-1 {
				continue
			}
			if segmentsIntersect(vertices[i], vertices[i+1], vertices[j], vertices[j+1]) {
				return true
			}
		}
	}
	return false
}

func asegurarSentidoAntihorario(vertices []GeoPoint) []GeoPoint {
	if len(vertices) < 4 {
		return vertices
	}
	var sum float64
	n := len(vertices) - 1
	for i := 0; i < n; i++ {
		p1 := vertices[i]
		p2 := vertices[i+1]
		sum += (p2.Longitud() - p1.Longitud()) * (p2.Latitud() + p1.Latitud())
	}
	// sum > 0: horario (CW). sum < 0: antihorario (CCW).
	if sum > 0 {
		res := make([]GeoPoint, len(vertices))
		for i := 0; i < n; i++ {
			res[i] = vertices[n-1-i]
		}
		res[n] = res[0]
		return res
	}
	return vertices
}

// Vertices retorna una copia del anillo exterior cerrado de vértices.
func (p GeoPolygon) Vertices() []GeoPoint {
	res := make([]GeoPoint, len(p.anilloExterior))
	copy(res, p.anilloExterior)
	return res
}

// Coordinates retorna las coordenadas en formato GeoJSON standard [][2]float64.
func (p GeoPolygon) Coordinates() [][2]float64 {
	res := make([][2]float64, len(p.anilloExterior))
	for i, pt := range p.anilloExterior {
		res[i] = pt.Coordinates()
	}
	return res
}

// GeoJSONPolygon representa la estructura estándar GeoJSON de tipo Polygon.
type GeoJSONPolygon struct {
	Type        string         `json:"type"`
	Coordinates [][][2]float64 `json:"coordinates"`
}

// ToGeoJSON convierte el GeoPolygon a su representación GeoJSON.
func (p GeoPolygon) ToGeoJSON() GeoJSONPolygon {
	return GeoJSONPolygon{
		Type:        "Polygon",
		Coordinates: [][][2]float64{p.Coordinates()},
	}
}

// MarshalJSON serializa el GeoPolygon como GeoJSON estándar.
func (p GeoPolygon) MarshalJSON() ([]byte, error) {
	return json.Marshal(p.ToGeoJSON())
}

// UnmarshalJSON deserializa un GeoJSON de tipo Polygon a GeoPolygon.
func (p *GeoPolygon) UnmarshalJSON(data []byte) error {
	var geoJSON GeoJSONPolygon
	if err := json.Unmarshal(data, &geoJSON); err != nil {
		return fmt.Errorf("GeoPolygon JSON invalido: %w", err)
	}
	if geoJSON.Type != "Polygon" {
		return fmt.Errorf("tipo GeoJSON invalido: se esperaba 'Polygon', recibido: '%s'", geoJSON.Type)
	}
	if len(geoJSON.Coordinates) == 0 || len(geoJSON.Coordinates[0]) < 3 {
		return fmt.Errorf("coordenadas insuficientes para formar un poligono")
	}

	rawRing := geoJSON.Coordinates[0]
	vertices := make([]GeoPoint, len(rawRing))
	for i, coord := range rawRing {
		pt, err := NewGeoPoint(coord[0], coord[1])
		if err != nil {
			return err
		}
		vertices[i] = pt
	}

	poly, err := NewGeoPolygon(vertices)
	if err != nil {
		return err
	}
	*p = poly
	return nil
}
