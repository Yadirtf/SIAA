package unit

import (
	"math"
	"testing"

	"github.com/siaa/backend/internal/domain/geo"
)

// Helper para crear polígono rectangular centrado
func makeRect(centerLon, centerLat, widthMeters, heightMeters float64) geo.GeoPolygon {
	const deg2rad = math.Pi / 180.0
	cosLat := math.Cos(centerLat * deg2rad)

	deltaLon := (widthMeters / 2.0) / (geo.RadioTierraWGS84 * cosLat) / deg2rad
	deltaLat := (heightMeters / 2.0) / geo.RadioTierraWGS84 / deg2rad

	p1, _ := geo.NewGeoPoint(centerLon-deltaLon, centerLat-deltaLat)
	p2, _ := geo.NewGeoPoint(centerLon+deltaLon, centerLat-deltaLat)
	p3, _ := geo.NewGeoPoint(centerLon+deltaLon, centerLat+deltaLat)
	p4, _ := geo.NewGeoPoint(centerLon-deltaLon, centerLat+deltaLat)

	poly, _ := geo.NewGeoPolygon([]geo.GeoPoint{p1, p2, p3, p4, p1})
	return poly
}

func TestGeo_Intersection_SinSolapamiento(t *testing.T) {
	// Dos rectángulos separados por ~100 metros
	poly1 := makeRect(-74.08175, 4.60971, 20, 10)
	poly2 := makeRect(-74.08050, 4.60971, 20, 10)

	areaInter, pct := geo.CalcularAreaSolapadaGeodesica(poly1, poly2)
	if areaInter != 0 || pct != 0 {
		t.Fatalf("Esperado solapamiento 0, obtenido area=%.2f, pct=%.2f%%", areaInter, pct)
	}
}

func TestGeo_Intersection_Identicos(t *testing.T) {
	// Dos polígonos idénticos de 20x10 = 200 m²
	poly1 := makeRect(-74.08175, 4.60971, 20, 10)
	poly2 := makeRect(-74.08175, 4.60971, 20, 10)

	areaInter, pct := geo.CalcularAreaSolapadaGeodesica(poly1, poly2)
	if math.Abs(pct-100.0) > 0.5 {
		t.Fatalf("Esperado solapamiento ~100%%, obtenido %.2f%% (area=%.2f)", pct, areaInter)
	}
}

func TestGeo_Intersection_SolapamientoParcial50Porciento(t *testing.T) {
	// Dos rectángulos de 20m de ancho desplazados 10m en X
	// El solapamiento es exactamente la mitad del ancho (50%)
	const deg2rad = math.Pi / 180.0
	centerLat := 4.60971
	centerLon := -74.08175
	cosLat := math.Cos(centerLat * deg2rad)
	desplazamientoX := 10.0 / (geo.RadioTierraWGS84 * cosLat) / deg2rad

	poly1 := makeRect(centerLon, centerLat, 20, 10)
	poly2 := makeRect(centerLon+desplazamientoX, centerLat, 20, 10)

	areaInter, pct := geo.CalcularAreaSolapadaGeodesica(poly1, poly2)
	t.Logf("Área solapada: %.2f m², Porcentaje: %.2f%%", areaInter, pct)

	if math.Abs(pct-50.0) > 1.5 {
		t.Fatalf("Esperado solapamiento ~50%%, obtenido %.2f%% (area=%.2f)", pct, areaInter)
	}
}
