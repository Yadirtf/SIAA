// Package geo — cálculos de buffer geodésico y generación centroide + radio.
// Satisface US-GEO-08 (AC-01..AC-03), US-GEO-09 (AC-01..AC-03), RF-GEO-005, RF-GEO-010.
// ADR-04: coordenadas en orden estricto [longitud, latitud].
package geo

import (
	"fmt"
	"math"

	"github.com/siaa/backend/internal/domain/shared"
)

// GenerarPoligonoCentroideRadio genera un polígono circular aproximado con al menos 16 vértices
// a partir de un centroide y un radio en metros (US-GEO-09 AC-01).
func GenerarPoligonoCentroideRadio(centroide GeoPoint, radioMetros float64, numVertices int) (GeoPolygon, error) {
	if radioMetros <= 0 {
		return GeoPolygon{}, shared.NewValidationError(
			"El radio debe ser un número positivo en metros",
			shared.FieldError{Campo: "radioMetros", Error: "RADIO_INVALIDO"},
		)
	}
	if numVertices < 16 {
		numVertices = 16
	}

	lat0 := centroide.Latitud()
	lon0 := centroide.Longitud()
	lat0Rad := toRadians(lat0)
	cosLat := math.Cos(lat0Rad)
	if math.Abs(cosLat) < 1e-6 {
		cosLat = 1e-6
	}

	vertices := make([]GeoPoint, 0, numVertices+1)
	step := 2.0 * math.Pi / float64(numVertices)

	for i := 0; i < numVertices; i++ {
		theta := float64(i) * step
		dx := radioMetros * math.Cos(theta)
		dy := radioMetros * math.Sin(theta)

		dLat := dy / (RadioTierraWGS84 * math.Pi / 180.0)
		dLon := dx / (RadioTierraWGS84 * cosLat * math.Pi / 180.0)

		pt, err := NewGeoPoint(lon0+dLon, lat0+dLat)
		if err != nil {
			return GeoPolygon{}, err
		}
		vertices = append(vertices, pt)
	}

	return NewGeoPolygon(vertices)
}

// CalcularBufferGeodesico expande un polígono hacia el exterior en una distancia fija en metros.
// Utiliza una proyección equirrectangular métrica centrada en el centroide del polígono,
// desplazando cada arista a lo largo de su normal exterior y calculando la intersección
// de las aristas expandidas para formar el nuevo contorno (US-GEO-08 AC-01, AC-02).
func CalcularBufferGeodesico(poly GeoPolygon, bufferMetros float64) (GeoPolygon, error) {
	if bufferMetros <= 0 {
		return poly, nil
	}
	if bufferMetros > 50.0 {
		return GeoPolygon{}, shared.NewValidationError(
			fmt.Sprintf("El buffer de %.2f metros excede el límite máximo permitido de 50 metros", bufferMetros),
			shared.FieldError{Campo: "bufferMetros", Error: "BUFFER_EXCEDE_MAXIMO"},
		)
	}

	vertices := poly.Vertices()
	n := len(vertices)
	if n < 4 {
		return GeoPolygon{}, shared.NewValidationError(
			"El polígono base no contiene suficientes vértices para calcular buffer",
			shared.FieldError{Campo: "geometria", Error: "POLIGONO_INVALIDO"},
		)
	}

	// Trabajar con vértices únicos (excluyendo el último vértice de cierre)
	m := n - 1
	centroid := CalcularCentroide(poly)
	lat0 := centroid.Latitud()
	lon0 := centroid.Longitud()
	lat0Rad := toRadians(lat0)
	cosLat := math.Cos(lat0Rad)
	if math.Abs(cosLat) < 1e-6 {
		cosLat = 1e-6
	}

	metersPerDegLat := RadioTierraWGS84 * math.Pi / 180.0
	metersPerDegLon := metersPerDegLat * cosLat

	// Proyectar vértices a metros en coordenadas locales
	xs := make([]float64, m)
	ys := make([]float64, m)
	for i := 0; i < m; i++ {
		xs[i] = (vertices[i].Longitud() - lon0) * metersPerDegLon
		ys[i] = (vertices[i].Latitud() - lat0) * metersPerDegLat
	}

	// Determinar orientación (área con signo): > 0 antihorario (CCW), < 0 horario (CW)
	var areaSign float64
	for i := 0; i < m; i++ {
		next := (i + 1) % m
		areaSign += xs[i]*ys[next] - xs[next]*ys[i]
	}
	ccw := areaSign > 0

	// Calcular normales exteriores normalizadas para cada arista
	nx := make([]float64, m)
	ny := make([]float64, m)
	for i := 0; i < m; i++ {
		next := (i + 1) % m
		dx := xs[next] - xs[i]
		dy := ys[next] - ys[i]
		length := math.Hypot(dx, dy)
		if length < 1e-7 {
			length = 1e-7
		}
		if ccw {
			// Normal exterior hacia la derecha del vector de avance en CCW: (dy, -dx)
			nx[i] = dy / length
			ny[i] = -dx / length
		} else {
			// Normal exterior en CW: (-dy, dx)
			nx[i] = -dy / length
			ny[i] = dx / length
		}
	}

	// Expandir cada vértice desplazándolo a lo largo de la bisectriz exterior de sus dos aristas adyacentes
	bufferedVertices := make([]GeoPoint, 0, m+1)
	for i := 0; i < m; i++ {
		prev := (i - 1 + m) % m
		// Vector normal promedio en el vértice
		bx := nx[prev] + nx[i]
		by := ny[prev] + ny[i]
		blen := math.Hypot(bx, by)
		if blen < 1e-6 {
			bx = nx[i]
			by = ny[i]
			blen = 1.0
		} else {
			bx /= blen
			by /= blen
		}

		// Factor de escala miter para que la distancia perpendicular a cada arista sea exactamente bufferMetros
		dot := nx[i]*bx + ny[i]*by
		scale := 1.0
		if dot > 0.1 {
			scale = 1.0 / dot
		}
		if scale > 2.5 { // Limitar esquinas muy agudas (miter limit)
			scale = 2.5
		}

		offsetX := xs[i] + bx*bufferMetros*scale
		offsetY := ys[i] + by*bufferMetros*scale

		// Desproyectar a WGS84
		newLon := lon0 + (offsetX / metersPerDegLon)
		newLat := lat0 + (offsetY / metersPerDegLat)

		pt, err := NewGeoPoint(newLon, newLat)
		if err != nil {
			return GeoPolygon{}, err
		}
		bufferedVertices = append(bufferedVertices, pt)
	}

	return NewGeoPolygon(bufferedVertices)
}
