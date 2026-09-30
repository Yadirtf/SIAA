// Package unit — Pruebas unitarias para invariantes geoespaciales y cálculos geodésicos.
// ADR-04: coordenadas obligatorias en orden [longitud, latitud].
// RF-GEO-002, T-GEO-02.1, T-GEO-02.2, T-GEO-02.8, AC-06.
package unit_test

import (
	"encoding/json"
	"math"
	"testing"

	"github.com/siaa/backend/internal/domain/geo"
)

// TestGeo_Invariante_ADR04_OrdenCoordenadas valida que todo GeoPoint y GeoJSON
// respete estrictamente el orden [longitud, latitud] según ADR-04 y T-GEO-02.8.
func TestGeo_Invariante_ADR04_OrdenCoordenadas(t *testing.T) {
	lonValida := -74.081750
	latValida := 4.609710

	pt, err := geo.NewGeoPoint(lonValida, latValida)
	if err != nil {
		t.Fatalf("error inesperado creando GeoPoint: %v", err)
	}

	if pt.Longitud() != lonValida {
		t.Errorf("esperado Longitud %f, obtenido %f", lonValida, pt.Longitud())
	}
	if pt.Latitud() != latValida {
		t.Errorf("esperado Latitud %f, obtenido %f", latValida, pt.Latitud())
	}

	coords := pt.Coordinates()
	if coords[0] != lonValida || coords[1] != latValida {
		t.Errorf("Coordinates() violó ADR-04: esperado [%f, %f], obtenido [%f, %f]",
			lonValida, latValida, coords[0], coords[1])
	}

	// Serialización JSON: debe ser array [lon, lat]
	data, err := json.Marshal(pt)
	if err != nil {
		t.Fatalf("error serializando GeoPoint a JSON: %v", err)
	}
	var arr []float64
	if err := json.Unmarshal(data, &arr); err != nil {
		t.Fatalf("error deserializando GeoPoint JSON: %v", err)
	}
	if len(arr) != 2 || arr[0] != lonValida || arr[1] != latValida {
		t.Fatalf("GeoPoint JSON no cumple formato [lon, lat]: %s", string(data))
	}

	// Validación de rangos
	_, errLonInvalida := geo.NewGeoPoint(185.0, 4.0)
	if errLonInvalida == nil {
		t.Error("se esperaba error con longitud fuera de rango [-180, 180]")
	}

	_, errLatInvalida := geo.NewGeoPoint(-74.0, 95.0)
	if errLatInvalida == nil {
		t.Error("se esperaba error con latitud fuera de rango [-90, 90]")
	}
}

// TestGeo_Invariante_PoligonoCierreAutomatico_Y_MinimoVertices valida AC-06:
// Un polígono se cierra automáticamente repitiendo el primer vértice si no coincide con el último,
// y rechaza polígonos con menos de 3 vértices distintos.
func TestGeo_Invariante_PoligonoCierreAutomatico_Y_MinimoVertices(t *testing.T) {
	p1, _ := geo.NewGeoPoint(-74.0818, 4.6097)
	p2, _ := geo.NewGeoPoint(-74.0816, 4.6097)
	p3, _ := geo.NewGeoPoint(-74.0816, 4.6099)

	// Polígono abierto de 3 vértices
	poly, err := geo.NewGeoPolygon([]geo.GeoPoint{p1, p2, p3})
	if err != nil {
		t.Fatalf("error creando GeoPolygon con 3 puntos: %v", err)
	}

	vertices := poly.Vertices()
	if len(vertices) != 4 {
		t.Fatalf("se esperaba que el polígono se auto-cerrara con 4 vértices (3 + cierre), obtenidos: %d", len(vertices))
	}

	ultimo := vertices[len(vertices)-1]
	if ultimo.Longitud() != p1.Longitud() || ultimo.Latitud() != p1.Latitud() {
		t.Errorf("el último vértice [%f, %f] no coincide con el primero [%f, %f]",
			ultimo.Longitud(), ultimo.Latitud(), p1.Longitud(), p1.Latitud())
	}

	// Polígono con menos de 3 vértices debe fallar
	_, errInsuficiente := geo.NewGeoPolygon([]geo.GeoPoint{p1, p2})
	if errInsuficiente == nil {
		t.Error("se esperaba error con menos de 3 vértices")
	}
}

// TestGeo_CalculoAreaGeodesica_PrecisionSubMetrica valida T-GEO-02.2:
// Cálculo esférico con error relativo < 0.5% respecto a un cuadrilátero de dimensiones conocidas.
func TestGeo_CalculoAreaGeodesica_PrecisionSubMetrica(t *testing.T) {
	// Rectángulo de 10m x 20m = 200 m² en Bogotá (lat ~ 4.60971)
	lat0 := 4.609710
	lon0 := -74.081750

	metrosPorGradoLat := geo.RadioTierraWGS84 * math.Pi / 180.0
	metrosPorGradoLon := geo.RadioTierraWGS84 * math.Cos(lat0*math.Pi/180.0) * math.Pi / 180.0

	deltaLat := 20.0 / metrosPorGradoLat // 20 metros exactos en latitud
	deltaLon := 10.0 / metrosPorGradoLon // 10 metros exactos en longitud

	p1, _ := geo.NewGeoPoint(lon0, lat0)
	p2, _ := geo.NewGeoPoint(lon0+deltaLon, lat0)
	p3, _ := geo.NewGeoPoint(lon0+deltaLon, lat0+deltaLat)
	p4, _ := geo.NewGeoPoint(lon0, lat0+deltaLat)

	poly, err := geo.NewGeoPolygon([]geo.GeoPoint{p1, p2, p3, p4})
	if err != nil {
		t.Fatalf("error creando polígono: %v", err)
	}

	areaCalculada := geo.CalcularAreaGeodesica(poly)
	areaEsperada := 200.0 // 10m * 20m

	errorRelativo := math.Abs(areaCalculada-areaEsperada) / areaEsperada
	t.Logf("Área calculada: %.2f m², esperada: %.2f m², error relativo: %.4f%%",
		areaCalculada, areaEsperada, errorRelativo*100)

	// Error relativo debe ser inferior a 0.5% (T-GEO-02.2)
	if errorRelativo > 0.005 {
		t.Errorf("error relativo del área esférica (%.4f%%) supera el 0.5%% permitido", errorRelativo*100)
	}

	// Validar perímetro: ~ 2 * (10 + 20) = 60 m
	perimetro := geo.CalcularPerimetro(poly)
	if perimetro < 59.0 || perimetro > 61.0 {
		t.Errorf("perímetro calculado %.2f m está fuera del rango esperado [59, 61]", perimetro)
	}
}

// TestGeo_CalculoCentroide_PoligonoSimetrico valida que el centroide
// caiga en el centro geométrico de un polígono regular.
func TestGeo_CalculoCentroide_PoligonoSimetrico(t *testing.T) {
	lon0 := -74.080000
	lat0 := 4.600000
	delta := 0.001000

	p1, _ := geo.NewGeoPoint(lon0, lat0)
	p2, _ := geo.NewGeoPoint(lon0+delta, lat0)
	p3, _ := geo.NewGeoPoint(lon0+delta, lat0+delta)
	p4, _ := geo.NewGeoPoint(lon0, lat0+delta)

	poly, _ := geo.NewGeoPolygon([]geo.GeoPoint{p1, p2, p3, p4})
	centroide := geo.CalcularCentroide(poly)

	esperadoLon := lon0 + delta/2.0
	esperadoLat := lat0 + delta/2.0

	tol := 1e-6
	if math.Abs(centroide.Longitud()-esperadoLon) > tol {
		t.Errorf("centroide longitud: esperado %f, obtenido %f", esperadoLon, centroide.Longitud())
	}
	if math.Abs(centroide.Latitud()-esperadoLat) > tol {
		t.Errorf("centroide latitud: esperado %f, obtenido %f", esperadoLat, centroide.Latitud())
	}
}
