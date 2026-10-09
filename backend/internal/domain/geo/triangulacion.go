// Package geo — triangulación por ear clipping usada para calcular solapamientos (US-GEO-05).
package geo

import "math"

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
