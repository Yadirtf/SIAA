package geo_test

import (
	"math"
	"testing"

	"github.com/siaa/backend/internal/domain/geo"
)

func TestContienePunto_CasosBasicos(t *testing.T) {
	// Cuadrado de 100m aprox en Bogotá
	// Lon: -74.082 a -74.081, Lat: 4.609 a 4.610
	p1, _ := geo.NewGeoPoint(-74.082, 4.609)
	p2, _ := geo.NewGeoPoint(-74.081, 4.609)
	p3, _ := geo.NewGeoPoint(-74.081, 4.610)
	p4, _ := geo.NewGeoPoint(-74.082, 4.610)

	poly, err := geo.NewGeoPolygon([]geo.GeoPoint{p1, p2, p3, p4})
	if err != nil {
		t.Fatalf("error creando poligono: %v", err)
	}

	t.Run("Punto estrictamente dentro", func(t *testing.T) {
		pt, _ := geo.NewGeoPoint(-74.0815, 4.6095)
		if !geo.ContienePunto(poly, pt) {
			t.Errorf("se esperaba que el punto estuviera dentro")
		}
	})

	t.Run("Punto estrictamente fuera", func(t *testing.T) {
		pt, _ := geo.NewGeoPoint(-74.083, 4.6095)
		if geo.ContienePunto(poly, pt) {
			t.Errorf("se esperaba que el punto estuviera fuera")
		}
	})

	t.Run("Borde exacto - sobre un vertice", func(t *testing.T) {
		// Vértice 1 exacto (§11.4: definido explícitamente como DENTRO)
		if !geo.ContienePunto(poly, p1) {
			t.Errorf("se esperaba que el vértice exacto estuviera dentro")
		}
	})

	t.Run("Borde exacto - sobre una arista", func(t *testing.T) {
		// Punto medio de la arista sur: Lat 4.609, Lon -74.0815
		ptBorde, _ := geo.NewGeoPoint(-74.0815, 4.609)
		if !geo.ContienePunto(poly, ptBorde) {
			t.Errorf("se esperaba que el punto sobre la arista estuviera dentro")
		}
	})
}

func TestDistanciaAlPoligono(t *testing.T) {
	p1, _ := geo.NewGeoPoint(-74.082, 4.609)
	p2, _ := geo.NewGeoPoint(-74.081, 4.609)
	p3, _ := geo.NewGeoPoint(-74.081, 4.610)
	p4, _ := geo.NewGeoPoint(-74.082, 4.610)

	poly, err := geo.NewGeoPolygon([]geo.GeoPoint{p1, p2, p3, p4})
	if err != nil {
		t.Fatalf("error creando poligono: %v", err)
	}

	t.Run("Distancia de punto interior es 0", func(t *testing.T) {
		pt, _ := geo.NewGeoPoint(-74.0815, 4.6095)
		d := geo.DistanciaAlPoligono(poly, pt)
		if d != 0.0 {
			t.Errorf("distancia esperada 0.0, obtenida: %f", d)
		}
	})

	t.Run("Distancia de punto exterior es positiva y precisa", func(t *testing.T) {
		// Punto al este a ~111 metros (0.001 grados de longitud aprox en latitud 4.6 es ~111m * cos(4.6°) ≈ 110.8m)
		pt, _ := geo.NewGeoPoint(-74.080, 4.6095)
		d := geo.DistanciaAlPoligono(poly, pt)
		if d <= 50.0 || d >= 150.0 {
			t.Errorf("distancia esperada entre 50 y 150m, obtenida: %f", d)
		}
	})

	t.Run("Poligono vacio o degenerado", func(t *testing.T) {
		emptyPoly := geo.GeoPolygon{}
		pt, _ := geo.NewGeoPoint(-74.080, 4.6095)
		if geo.ContienePunto(emptyPoly, pt) {
			t.Errorf("poligono vacio no debe contener puntos")
		}
		if geo.DistanciaAlPoligono(emptyPoly, pt) != math.MaxFloat64 {
			t.Errorf("distancia a poligono vacio debe ser MaxFloat64")
		}
	})
}
