// Package geo — validador geométrico de polígonos sin persistencia (US-GEO-04).
// RF-GEO-006, RF-GEO-010, AC-01..AC-05, T-GEO-04.1..T-GEO-04.3.
package geo

import (
	"fmt"
)

// Constantes de motivos de rechazo geométrico (US-GEO-04, AC-01..AC-04).
const (
	MotivoVerticesInsuficientes = "VERTICES_INSUFICIENTES"
	MotivoPoligonoNoSimple      = "POLIGONO_NO_SIMPLE"
	MotivoAreaFueraDeRango      = "AREA_FUERA_DE_RANGO"
	MotivoCoordenadasInvalidas  = "COORDENADAS_INVALIDAS"
)

// Límites de área por defecto (US-GEO-04 AC-04: 6 m² a 5.000 m²).
const (
	DefaultMinAreaM2 = 6.0
	DefaultMaxAreaM2 = 5000.0
)

// ConflictoSegmento representa un par de aristas no contiguas que se cruzan entre sí (AC-02).
type ConflictoSegmento struct {
	AristaA [2][2]float64 `json:"aristaA"`
	AristaB [2][2]float64 `json:"aristaB"`
}

// ResultadoValidacionGeometria contiene el diagnóstico detallado de la geometría sin persistir (AC-05).
type ResultadoValidacionGeometria struct {
	Valido              bool                `json:"valido"`
	Codigo              string              `json:"codigo,omitempty"`
	Mensaje             string              `json:"mensaje,omitempty"`
	AreaMetrosCuadrados float64             `json:"areaMetrosCuadrados"`
	PerimetroMetros     float64             `json:"perimetroMetros"`
	Centroide           *GeoPoint           `json:"centroide,omitempty"`
	PoligonoCerrado     bool                `json:"poligonoCerrado"`
	SegmentosConflicto  []ConflictoSegmento `json:"segmentosConflicto,omitempty"`
	Advertencias        []string            `json:"advertencias,omitempty"`
}

// ValidarGeometriaPoligono evalúa una lista de coordenadas [lon, lat] contra los criterios AC-01..AC-04.
// Es una función pura de dominio que no produce efectos secundarios ni persistencia (AC-05).
func ValidarGeometriaPoligono(coords [][2]float64, minArea, maxArea float64) ResultadoValidacionGeometria {
	if minArea <= 0 {
		minArea = DefaultMinAreaM2
	}
	if maxArea <= 0 {
		maxArea = DefaultMaxAreaM2
	}

	// AC-01: mínimo 3 vértices
	if len(coords) < 3 {
		return ResultadoValidacionGeometria{
			Valido:  false,
			Codigo:  MotivoVerticesInsuficientes,
			Mensaje: fmt.Sprintf("Un polígono requiere al menos 3 vértices distintos, recibidos: %d", len(coords)),
		}
	}

	// Validar y construir GeoPoints
	vertices := make([]GeoPoint, len(coords))
	uniqueMap := make(map[string]struct{})
	for i, c := range coords {
		pt, err := NewGeoPoint(c[0], c[1])
		if err != nil {
			return ResultadoValidacionGeometria{
				Valido:  false,
				Codigo:  MotivoCoordenadasInvalidas,
				Mensaje: fmt.Sprintf("Coordenada en índice %d inválida: %v", i, err),
			}
		}
		vertices[i] = pt
		key := fmt.Sprintf("%.7f,%.7f", pt.Longitud(), pt.Latitud())
		uniqueMap[key] = struct{}{}
	}

	if len(uniqueMap) < 3 {
		return ResultadoValidacionGeometria{
			Valido:  false,
			Codigo:  MotivoVerticesInsuficientes,
			Mensaje: fmt.Sprintf("Se requieren al menos 3 vértices únicos diferentes, recibidos: %d", len(uniqueMap)),
		}
	}

	var advertencias []string
	poligonoCerrado := true

	// AC-03: cierre automático si no coincide el primer y último punto
	primerPunto := vertices[0]
	ultimoPunto := vertices[len(vertices)-1]
	if primerPunto.Longitud() != ultimoPunto.Longitud() || primerPunto.Latitud() != ultimoPunto.Latitud() {
		vertices = append(vertices, primerPunto)
		advertencias = append(advertencias, "El polígono no estaba cerrado; se cerró automáticamente uniendo el último vértice con el primero (AC-03).")
	}

	// AC-02: detección de auto-intersecciones (polígono no simple)
	conflicts := FindSelfIntersections(vertices)
	if len(conflicts) > 0 {
		return ResultadoValidacionGeometria{
			Valido:             false,
			Codigo:             MotivoPoligonoNoSimple,
			Mensaje:            "El polígono es inválido: contiene bordes cruzados (auto-intersección). Asegúrese de trazar los vértices en orden perimetral continuo.",
			PoligonoCerrado:    poligonoCerrado,
			SegmentosConflicto: conflicts,
			Advertencias:       advertencias,
		}
	}

	// Invariante de orientación: asegurar sentido antihorario
	vertices = asegurarSentidoAntihorario(vertices)
	poly := GeoPolygon{anilloExterior: vertices}

	// Cálculo de métricas geodésicas (WGS84)
	area := CalcularAreaGeodesica(poly)
	perimetro := CalcularPerimetro(poly)
	centroide := CalcularCentroide(poly)

	// AC-04: rango de área configurable
	if area < minArea || area > maxArea {
		return ResultadoValidacionGeometria{
			Valido:              false,
			Codigo:              MotivoAreaFueraDeRango,
			Mensaje:             fmt.Sprintf("El área calculada (%.2f m²) está fuera del rango permitido [%.1f m² - %.1f m²] (AC-04).", area, minArea, maxArea),
			AreaMetrosCuadrados: area,
			PerimetroMetros:     perimetro,
			Centroide:           &centroide,
			PoligonoCerrado:     poligonoCerrado,
			Advertencias:        advertencias,
		}
	}

	// AC-05: resultado exitoso
	return ResultadoValidacionGeometria{
		Valido:              true,
		AreaMetrosCuadrados: area,
		PerimetroMetros:     perimetro,
		Centroide:           &centroide,
		PoligonoCerrado:     poligonoCerrado,
		Advertencias:        advertencias,
	}
}

// FindSelfIntersections detecta todas las parejas de aristas no contiguas que se intersectan.
func FindSelfIntersections(vertices []GeoPoint) []ConflictoSegmento {
	n := len(vertices)
	if n < 4 {
		return nil
	}
	var conflicts []ConflictoSegmento
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
				conflicts = append(conflicts, ConflictoSegmento{
					AristaA: [2][2]float64{vertices[i].Coordinates(), vertices[i+1].Coordinates()},
					AristaB: [2][2]float64{vertices[j].Coordinates(), vertices[j+1].Coordinates()},
				})
			}
		}
	}
	return conflicts
}
