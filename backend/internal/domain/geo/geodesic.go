// Package geo — cálculos geodésicos y esféricos para cartografía de espacios.
// ADR-04: coordenadas en orden estricto [longitud, latitud].
// RF-GEO-002, T-GEO-02.2.
package geo

import (
	"math"
)

// RadioTierraWGS84 define el radio esférico medio de la Tierra en metros según WGS84.
const RadioTierraWGS84 = 6378137.0

func toRadians(grados float64) float64 {
	return grados * math.Pi / 180.0
}

func toDegrees(rad float64) float64 {
	return rad * 180.0 / math.Pi
}

// CalcularDistanciaHaversine calcula la distancia ortodrómica en metros entre dos puntos geográficos.
func CalcularDistanciaHaversine(p1, p2 GeoPoint) float64 {
	lat1Rad := toRadians(p1.Latitud())
	lat2Rad := toRadians(p2.Latitud())
	deltaLat := toRadians(p2.Latitud() - p1.Latitud())
	deltaLon := toRadians(p2.Longitud() - p1.Longitud())

	sinDeltaLat := math.Sin(deltaLat / 2.0)
	sinDeltaLon := math.Sin(deltaLon / 2.0)

	a := sinDeltaLat*sinDeltaLat + math.Cos(lat1Rad)*math.Cos(lat2Rad)*sinDeltaLon*sinDeltaLon
	c := 2.0 * math.Atan2(math.Sqrt(a), math.Sqrt(1.0-a))

	return RadioTierraWGS84 * c
}

// CalcularPerimetro calcula el perímetro total en metros del polígono recorriendo sus aristas.
func CalcularPerimetro(poly GeoPolygon) float64 {
	vertices := poly.Vertices()
	if len(vertices) < 2 {
		return 0
	}

	var perimetro float64
	for i := 0; i < len(vertices)-1; i++ {
		perimetro += CalcularDistanciaHaversine(vertices[i], vertices[i+1])
	}
	return perimetro
}

// CalcularAreaGeodesica calcula el área del polígono en metros cuadrados (m²) sobre la esfera terrestre.
// Utiliza el algoritmo de exceso esférico de Chamberlain-Duquette (2007).
// Para espacios arquitectónicos y campus universitarios, el error relativo es inferior al 0.1%.
func CalcularAreaGeodesica(poly GeoPolygon) float64 {
	vertices := poly.Vertices()
	n := len(vertices)
	if n < 4 { // Un anillo cerrado mínimo tiene 4 puntos (3 únicos + cierre)
		return 0
	}

	var total float64
	for i := 0; i < n-1; i++ {
		p1 := vertices[i]
		p2 := vertices[i+1]

		lon1 := toRadians(p1.Longitud())
		lat1 := toRadians(p1.Latitud())
		lon2 := toRadians(p2.Longitud())
		lat2 := toRadians(p2.Latitud())

		deltaLon := lon2 - lon1
		// Normalizar deltaLon al rango [-π, π]
		for deltaLon > math.Pi {
			deltaLon -= 2 * math.Pi
		}
		for deltaLon < -math.Pi {
			deltaLon += 2 * math.Pi
		}

		total += deltaLon * (2.0 + math.Sin(lat1) + math.Sin(lat2))
	}

	area := math.Abs(total * RadioTierraWGS84 * RadioTierraWGS84 / 2.0)
	return area
}

// CalcularCentroide calcula el centro de gravedad geográfico del polígono.
// Utiliza una proyección local equirrectangular tangente al primer vértice para garantizar precisión
// submétrica en polígonos cerrados de cualquier forma (cóncava o convexa).
func CalcularCentroide(poly GeoPolygon) GeoPoint {
	vertices := poly.Vertices()
	n := len(vertices)
	if n == 0 {
		return GeoPoint{}
	}
	if n < 4 {
		// Degenerado: promedio simple
		var sumLon, sumLat float64
		for _, v := range vertices {
			sumLon += v.Longitud()
			sumLat += v.Latitud()
		}
		pt, _ := NewGeoPoint(sumLon/float64(n), sumLat/float64(n))
		return pt
	}

	refLon := vertices[0].Longitud()
	refLat := vertices[0].Latitud()
	refLatRad := toRadians(refLat)
	cosLat := math.Cos(refLatRad)

	// Proyección local plana centrada en (refLon, refLat)
	// x en grados longitud escalados, y en grados latitud
	m := n - 1 // Cantidad de vértices únicos
	xs := make([]float64, n)
	ys := make([]float64, n)
	for i := 0; i < n; i++ {
		xs[i] = (vertices[i].Longitud() - refLon) * cosLat
		ys[i] = vertices[i].Latitud() - refLat
	}

	var area2D float64
	var cx, cy float64

	for i := 0; i < m; i++ {
		cross := xs[i]*ys[i+1] - xs[i+1]*ys[i]
		area2D += cross
		cx += (xs[i] + xs[i+1]) * cross
		cy += (ys[i] + ys[i+1]) * cross
	}
	area2D *= 0.5

	if math.Abs(area2D) < 1e-12 {
		// Polígono colineal o degenerate: fallback a promedio de vértices únicos
		var sumLon, sumLat float64
		for i := 0; i < m; i++ {
			sumLon += vertices[i].Longitud()
			sumLat += vertices[i].Latitud()
		}
		pt, _ := NewGeoPoint(sumLon/float64(m), sumLat/float64(m))
		return pt
	}

	cx /= (6.0 * area2D)
	cy /= (6.0 * area2D)

	// Desproyectar a coordenadas geográficas WGS84
	finalLon := refLon + cx/cosLat
	finalLat := refLat + cy

	pt, err := NewGeoPoint(finalLon, finalLat)
	if err != nil {
		// Si por alguna anomalía numérica excede rangos, fallback a punto de referencia
		return vertices[0]
	}
	return pt
}
