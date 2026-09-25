// Package geo — contención punto-en-polígono y distancia mínima punto-polígono.
// T-MAR-03.3, RN-001 paso 8, §11.2, §11.4.
// ADR-04: coordenadas en orden estricto [longitud, latitud].
package geo

import (
	"math"
)

// ContienePunto determina si un GeoPoint se encuentra dentro o en el borde de un GeoPolygon.
// Implementa el algoritmo Ray Casting optimizado con inclusión explícita de bordes y vértices.
// Un punto sobre el contorno o sobre un vértice se define explícitamente como DENTRO (§11.4).
func ContienePunto(poly GeoPolygon, punto GeoPoint) bool {
	vertices := poly.Vertices()
	n := len(vertices)
	if n < 4 {
		return false
	}

	px := punto.Longitud()
	py := punto.Latitud()

	// 1. Verificación previa de vértices y bordes exactos (§11.4 caso Borde exacto)
	for i := 0; i < n-1; i++ {
		p1 := vertices[i]
		p2 := vertices[i+1]

		if puntoSobreSegmento(px, py, p1.Longitud(), p1.Latitud(), p2.Longitud(), p2.Latitud()) {
			return true
		}
	}

	// 2. Algoritmo Ray-Casting (número de intersecciones hacia x positivo)
	inside := false
	for i := 0; i < n-1; i++ {
		x1 := vertices[i].Longitud()
		y1 := vertices[i].Latitud()
		x2 := vertices[i+1].Longitud()
		y2 := vertices[i+1].Latitud()

		// Condición de cruce en Y
		if (y1 > py) != (y2 > py) {
			// Calcular coordenada X de la intersección del rayo horizontal
			xIntersect := (x2-x1)*(py-y1)/(y2-y1) + x1
			if px < xIntersect {
				inside = !inside
			}
		}
	}

	return inside
}

// puntoSobreSegmento verifica con tolerancia si (px, py) reposa exactamente en el segmento (x1,y1)-(x2,y2).
func puntoSobreSegmento(px, py, x1, y1, x2, y2 float64) bool {
	const tol = 1e-9

	// Verificar caja delimitadora del segmento
	minX, maxX := math.Min(x1, x2), math.Max(x1, x2)
	minY, maxY := math.Min(y1, y2), math.Max(y1, y2)

	if px < minX-tol || px > maxX+tol || py < minY-tol || py > maxY+tol {
		return false
	}

	// Producto cruz para colinealidad: (p - p1) x (p2 - p1)
	cross := (px-x1)*(y2-y1) - (py-y1)*(x2-x1)
	return math.Abs(cross) < tol
}

// DistanciaAlPoligono calcula la distancia geodésica mínima en metros entre un punto y el polígono.
// Si el punto está contenido dentro del polígono o en su borde, retorna 0.0.
// Si está fuera, calcula la distancia ortodrómica mínima hacia todas las aristas perimetrales.
func DistanciaAlPoligono(poly GeoPolygon, punto GeoPoint) float64 {
	if ContienePunto(poly, punto) {
		return 0.0
	}

	vertices := poly.Vertices()
	n := len(vertices)
	if n < 4 {
		return math.MaxFloat64
	}

	minDist := math.MaxFloat64

	// Proyección local plana centrada en el punto a evaluar para medir distancia euclidiana precisa
	refLon := punto.Longitud()
	refLat := punto.Latitud()
	const deg2rad = math.Pi / 180.0
	cosLat := math.Cos(refLat * deg2rad)
	metersPerDegLat := RadioTierraWGS84 * deg2rad
	metersPerDegLon := metersPerDegLat * cosLat

	// Punto evaluado en metros locales es (0, 0)
	for i := 0; i < n-1; i++ {
		p1 := vertices[i]
		p2 := vertices[i+1]

		x1 := (p1.Longitud() - refLon) * metersPerDegLon
		y1 := (p1.Latitud() - refLat) * metersPerDegLat
		x2 := (p2.Longitud() - refLon) * metersPerDegLon
		y2 := (p2.Latitud() - refLat) * metersPerDegLat

		d := distanciaPuntoASegmentoMetros(0, 0, x1, y1, x2, y2)
		if d < minDist {
			minDist = d
		}
	}

	return minDist
}

// distanciaPuntoASegmentoMetros calcula la distancia euclidiana mínima en metros entre (px, py) y el segmento (x1,y1)-(x2,y2).
func distanciaPuntoASegmentoMetros(px, py, x1, y1, x2, y2 float64) float64 {
	dx := x2 - x1
	dy := y2 - y1
	segLen2 := dx*dx + dy*dy

	if segLen2 < 1e-12 {
		// Segmento degenerado en un punto
		return math.Hypot(px-x1, py-y1)
	}

	// Proyección parametrizada t ∈ [0, 1]
	t := ((px-x1)*dx + (py-y1)*dy) / segLen2
	if t < 0.0 {
		t = 0.0
	} else if t > 1.0 {
		t = 1.0
	}

	projX := x1 + t*dx
	projY := y1 + t*dy

	return math.Hypot(px-projX, py-projY)
}
