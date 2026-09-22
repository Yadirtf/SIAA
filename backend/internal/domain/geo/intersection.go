// Package geo — detección y cálculo geométrico de solapamientos espaciales.
// RF-GEO-007, US-GEO-05, AC-01..AC-05, T-GEO-05.1, T-GEO-05.2.
package geo

import (
	"math"
)

// SolapamientoEspacio representa el resultado de evaluar el conflicto de solapamiento
// entre el espacio que se está delimitando y otro espacio activo existente en el mismo bloque y piso.
type SolapamientoEspacio struct {
	EspacioID          string  `json:"espacioId"`
	EspacioCodigo      string  `json:"espacioCodigo"`
	EspacioNombre      string  `json:"espacioNombre"`
	AreaSolapadaM2     float64 `json:"areaSolapadaM2"`
	PorcentajeSolapado float64 `json:"porcentajeSolapado"` // % respecto al área del espacio nuevo
	BloqueaGuardado    bool    `json:"bloqueaGuardado"`    // true si PorcentajeSolapado > 50.0 (AC-03)
}

// Point2D representa una coordenada proyectada en metros en un plano euclidiano local.
type Point2D struct {
	X float64
	Y float64
}

// CalcularAreaSolapadaGeodesica calcula el área de intersección en m² y el porcentaje de solapamiento
// relativo a poly1 (espacio nuevo o en edición) frente a poly2 (espacio existente con el que intersecta).
// T-GEO-05.2, AC-01, AC-03.
func CalcularAreaSolapadaGeodesica(poly1, poly2 GeoPolygon) (areaInterseccionM2 float64, porcentajeSolapado float64) {
	v1 := poly1.Vertices()
	v2 := poly2.Vertices()
	if len(v1) < 4 || len(v2) < 4 {
		return 0, 0
	}

	// Punto de referencia para proyección local plana: primer vértice de poly1
	refLon := v1[0].Longitud()
	refLat := v1[0].Latitud()

	pts1 := sanitizePoints(projectPolygon(v1, refLon, refLat))
	pts2 := sanitizePoints(projectPolygon(v2, refLon, refLat))

	if len(pts1) < 3 || len(pts2) < 3 {
		return 0, 0
	}

	// Optimización: si las cajas delimitadoras no se intersectan, área es cero
	if !boundingBoxesOverlap(pts1, pts2) {
		return 0, 0
	}

	area1 := polygonArea2D(pts1)
	if area1 <= 1e-6 {
		return 0, 0
	}

	interArea := intersectPolygonsArea(pts1, pts2)
	if interArea < 1e-4 {
		return 0, 0
	}

	// Porcentaje respecto al espacio nuevo (poly1)
	pct := (interArea / area1) * 100.0
	if pct > 100.0 {
		pct = 100.0
	}

	return interArea, pct
}

func projectPolygon(vertices []GeoPoint, refLon, refLat float64) []Point2D {
	const deg2rad = math.Pi / 180.0
	latRad := refLat * deg2rad
	cosLat := math.Cos(latRad)

	n := len(vertices)
	if n > 1 && vertices[0].Longitud() == vertices[n-1].Longitud() && vertices[0].Latitud() == vertices[n-1].Latitud() {
		n-- // Excluir el vértice de cierre repetido para triangulación euclidiana
	}

	pts := make([]Point2D, n)
	for i := 0; i < n; i++ {
		lon := vertices[i].Longitud()
		lat := vertices[i].Latitud()
		pts[i] = Point2D{
			X: (lon - refLon) * deg2rad * RadioTierraWGS84 * cosLat,
			Y: (lat - refLat) * deg2rad * RadioTierraWGS84,
		}
	}
	return pts
}

func sanitizePoints(pts []Point2D) []Point2D {
	if len(pts) == 0 {
		return nil
	}
	res := make([]Point2D, 0, len(pts))
	for i := 0; i < len(pts); i++ {
		curr := pts[i]
		if len(res) == 0 {
			res = append(res, curr)
			continue
		}
		prev := res[len(res)-1]
		dist2 := (curr.X-prev.X)*(curr.X-prev.X) + (curr.Y-prev.Y)*(curr.Y-prev.Y)
		if dist2 > 1e-8 {
			res = append(res, curr)
		}
	}
	// Revisar si el último coincide con el primero
	if len(res) > 2 {
		first := res[0]
		last := res[len(res)-1]
		dist2 := (last.X-first.X)*(last.X-first.X) + (last.Y-first.Y)*(last.Y-first.Y)
		if dist2 < 1e-8 {
			res = res[:len(res)-1]
		}
	}
	return res
}

func boundingBoxesOverlap(p1, p2 []Point2D) bool {
	minX1, maxX1, minY1, maxY1 := getBounds(p1)
	minX2, maxX2, minY2, maxY2 := getBounds(p2)
	return !(maxX1 < minX2 || maxX2 < minX1 || maxY1 < minY2 || maxY2 < minY1)
}

func getBounds(pts []Point2D) (minX, maxX, minY, maxY float64) {
	minX, maxX = pts[0].X, pts[0].X
	minY, maxY = pts[0].Y, pts[0].Y
	for _, p := range pts[1:] {
		if p.X < minX {
			minX = p.X
		}
		if p.X > maxX {
			maxX = p.X
		}
		if p.Y < minY {
			minY = p.Y
		}
		if p.Y > maxY {
			maxY = p.Y
		}
	}
	return
}

func polygonArea2D(pts []Point2D) float64 {
	n := len(pts)
	if n < 3 {
		return 0
	}
	var sum float64
	for i := 0; i < n; i++ {
		j := (i + 1) % n
		sum += pts[i].X*pts[j].Y - pts[j].X*pts[i].Y
	}
	return 0.5 * math.Abs(sum)
}

func isCCW(pts []Point2D) bool {
	var sum float64
	n := len(pts)
	for i := 0; i < n; i++ {
		j := (i + 1) % n
		sum += (pts[j].X - pts[i].X) * (pts[j].Y + pts[i].Y)
	}
	return sum < 0
}

func ensureCCW(pts []Point2D) []Point2D {
	if !isCCW(pts) {
		rev := make([]Point2D, len(pts))
		for i := range pts {
			rev[i] = pts[len(pts)-1-i]
		}
		return rev
	}
	return pts
}

// Triangulación por Ear Clipping para descomponer cualquier polígono simple (cóncavo o convexo).
func triangulate(pts []Point2D) [][]Point2D {
	pts = ensureCCW(pts)
	n := len(pts)
	if n < 3 {
		return nil
	}
	if n == 3 {
		return [][]Point2D{{pts[0], pts[1], pts[2]}}
	}

	// Si es convexo, usar fan triangulation directa
	if isConvex(pts) {
		triangles := make([][]Point2D, 0, n-2)
		for i := 1; i < n-1; i++ {
			triangles = append(triangles, []Point2D{pts[0], pts[i], pts[i+1]})
		}
		return triangles
	}

	// Ear clipping general
	indices := make([]int, n)
	for i := range indices {
		indices[i] = i
	}

	triangles := make([][]Point2D, 0, n-2)
	count := 2 * len(indices)
	i := 0

	for len(indices) > 3 && count > 0 {
		count--
		curr := indices[i]
		prev := indices[(i+len(indices)-1)%len(indices)]
		next := indices[(i+1)%len(indices)]

		pPrev := pts[prev]
		pCurr := pts[curr]
		pNext := pts[next]

		if isEar(pPrev, pCurr, pNext, pts, indices) {
			triangles = append(triangles, []Point2D{pPrev, pCurr, pNext})
			indices = append(indices[:i], indices[i+1:]...)
			if i >= len(indices) {
				i = 0
			}
			count = 2 * len(indices)
		} else {
			i = (i + 1) % len(indices)
		}
	}

	if len(indices) == 3 {
		triangles = append(triangles, []Point2D{pts[indices[0]], pts[indices[1]], pts[indices[2]]})
	}

	return triangles
}

func isConvex(pts []Point2D) bool {
	n := len(pts)
	if n < 3 {
		return false
	}
	var sign bool
	for i := 0; i < n; i++ {
		p0 := pts[i]
		p1 := pts[(i+1)%n]
		p2 := pts[(i+2)%n]
		cross := (p1.X-p0.X)*(p2.Y-p1.Y) - (p1.Y-p0.Y)*(p2.X-p1.X)
		if i == 0 {
			sign = cross > 0
		} else if (cross > 0) != sign && math.Abs(cross) > 1e-9 {
			return false
		}
	}
	return true
}

func isEar(a, b, c Point2D, allPts []Point2D, indices []int) bool {
	// b debe ser un vértice convexo (giro a la izquierda en CCW)
	cross := (b.X-a.X)*(c.Y-b.Y) - (b.Y-a.Y)*(c.X-b.X)
	if cross <= 1e-9 {
		return false
	}

	// Ningún otro punto del polígono debe estar dentro del triángulo abc
	for _, idx := range indices {
		p := allPts[idx]
		if (p.X == a.X && p.Y == a.Y) || (p.X == b.X && p.Y == b.Y) || (p.X == c.X && p.Y == c.Y) {
			continue
		}
		if pointInTriangle(p, a, b, c) {
			return false
		}
	}
	return true
}

func pointInTriangle(p, a, b, c Point2D) bool {
	cp1 := (b.X-a.X)*(p.Y-a.Y) - (b.Y-a.Y)*(p.X-a.X)
	cp2 := (c.X-b.X)*(p.Y-b.Y) - (c.Y-b.Y)*(p.X-b.X)
	cp3 := (a.X-c.X)*(p.Y-c.Y) - (a.Y-c.Y)*(p.X-c.X)

	hasNeg := (cp1 < -1e-9) || (cp2 < -1e-9) || (cp3 < -1e-9)
	hasPos := (cp1 > 1e-9) || (cp2 > 1e-9) || (cp3 > 1e-9)

	return !(hasNeg && hasPos)
}

// intersectPolygonsArea calcula el área total de intersección triangulando ambos polígonos
// y aplicando Sutherland-Hodgman sobre cada par de triángulos convexos.
func intersectPolygonsArea(p1, p2 []Point2D) float64 {
	triangles1 := triangulate(p1)
	triangles2 := triangulate(p2)

	var totalArea float64
	for _, t1 := range triangles1 {
		for _, t2 := range triangles2 {
			clipped := clipPolygonAgainstConvex(t1, t2)
			if len(clipped) >= 3 {
				totalArea += polygonArea2D(clipped)
			}
		}
	}
	return totalArea
}

// Algoritmo de Sutherland-Hodgman para recortar un polígono contra un polígono convexo (clip).
func clipPolygonAgainstConvex(subject []Point2D, clip []Point2D) []Point2D {
	output := subject
	nClip := len(clip)

	for i := 0; i < nClip; i++ {
		if len(output) == 0 {
			break
		}
		input := output
		output = nil

		c1 := clip[i]
		c2 := clip[(i+1)%nClip]

		nIn := len(input)
		for j := 0; j < nIn; j++ {
			curr := input[j]
			prev := input[(j+nIn-1)%nIn]

			currInside := isInsideEdge(curr, c1, c2)
			prevInside := isInsideEdge(prev, c1, c2)

			if currInside {
				if !prevInside {
					output = append(output, lineIntersection(prev, curr, c1, c2))
				}
				output = append(output, curr)
			} else if prevInside {
				output = append(output, lineIntersection(prev, curr, c1, c2))
			}
		}
	}
	return output
}

func isInsideEdge(pt, c1, c2 Point2D) bool {
	// Para borde orientado CCW de c1 a c2, el punto está "adentro" si queda a la izquierda
	return (c2.X-c1.X)*(pt.Y-c1.Y)-(c2.Y-c1.Y)*(pt.X-c1.X) >= -1e-9
}

func lineIntersection(p1, p2, p3, p4 Point2D) Point2D {
	denom := (p1.X-p2.X)*(p3.Y-p4.Y) - (p1.Y-p2.Y)*(p3.X-p4.X)
	if math.Abs(denom) < 1e-12 {
		return p2
	}
	t := ((p1.X-p3.X)*(p3.Y-p4.Y) - (p1.Y-p3.Y)*(p3.X-p4.X)) / denom
	return Point2D{
		X: p1.X + t*(p2.X-p1.X),
		Y: p1.Y + t*(p2.Y-p1.Y),
	}
}
