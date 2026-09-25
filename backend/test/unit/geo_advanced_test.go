// Package unit_test — pruebas unitarias para funcionalidades avanzadas de cartografía (EP-03).
// Satisface US-GEO-08 (Buffer perimetral), US-GEO-09 (Centroide + Radio),
// US-GEO-11 (Importación/Exportación GeoJSON) y US-GEO-12 (Clonación de pisos).
package unit_test

import (
	"context"
	"testing"
	"time"

	"github.com/siaa/backend/internal/domain/geo"
	"github.com/siaa/backend/internal/domain/shared"
	applog "github.com/siaa/backend/internal/platform/log"
	usecaseGeo "github.com/siaa/backend/internal/usecase/geo"
)

func TestUS_GEO_08_BufferGeodesico(t *testing.T) {
	// Cuadrado de ~10m x 10m en Bogotá
	// Coordenadas [lon, lat]
	vertices := []geo.GeoPoint{
		makePoint(t, -74.0650, 4.6500),
		makePoint(t, -74.0649, 4.6500),
		makePoint(t, -74.0649, 4.6501),
		makePoint(t, -74.0650, 4.6501),
		makePoint(t, -74.0650, 4.6500),
	}
	poly, err := geo.NewGeoPolygon(vertices)
	if err != nil {
		t.Fatalf("error creando polígono base: %v", err)
	}

	baseArea := geo.CalcularAreaGeodesica(poly)

	t.Run("AC-01: Buffer de 10 metros expande el polígono geodésicamente", func(t *testing.T) {
		buffered, err := geo.CalcularBufferGeodesico(poly, 10.0)
		if err != nil {
			t.Fatalf("error calculando buffer: %v", err)
		}

		bufArea := geo.CalcularAreaGeodesica(buffered)
		if bufArea <= baseArea {
			t.Errorf("área con buffer (%.2f m²) debe ser mayor al área base (%.2f m²)", bufArea, baseArea)
		}
	})

	t.Run("AC-02: Actualizar buffer en entidad Espacio sin recapturar vértices", func(t *testing.T) {
		esp := &geo.Espacio{
			ID:           "esp-1",
			Codigo:       "A-101",
			BufferMetros: 5.0,
		}
		err := esp.AsignarGeometria(poly, geo.MetodoRecorridoPerimetral, nil)
		if err != nil {
			t.Fatalf("error asignando geometría: %v", err)
		}
		if esp.GeometriaBuffer == nil {
			t.Fatal("GeometriaBuffer debe precalcularse al asignar geometría")
		}

		area1 := geo.CalcularAreaGeodesica(*esp.GeometriaBuffer)

		// Incrementar buffer a 20m
		err = esp.ActualizarBuffer(20.0)
		if err != nil {
			t.Fatalf("error actualizando buffer: %v", err)
		}
		if esp.BufferMetros != 20.0 {
			t.Errorf("esperaba BufferMetros 20.0, obtuvo %.1f", esp.BufferMetros)
		}

		area2 := geo.CalcularAreaGeodesica(*esp.GeometriaBuffer)
		if area2 <= area1 {
			t.Errorf("área tras actualizar buffer (%.2f m²) debe superar área previa (%.2f m²)", area2, area1)
		}
	})

	t.Run("AC-03: Rechazar buffer superior a 50 metros", func(t *testing.T) {
		_, err := geo.CalcularBufferGeodesico(poly, 55.0)
		if err == nil {
			t.Fatal("esperaba error por buffer > 50m, obtuvo nil")
		}
	})
}

func TestUS_GEO_09_CentroideRadio(t *testing.T) {
	centroide := makePoint(t, -74.0650, 4.6500)

	t.Run("AC-01: Generar polígono circular con al menos 16 vértices", func(t *testing.T) {
		poly, err := geo.GenerarPoligonoCentroideRadio(centroide, 15.0, 16)
		if err != nil {
			t.Fatalf("error generando polígono circular: %v", err)
		}

		verts := poly.Vertices()
		// 16 vértices únicos + 1 de cierre = 17
		if len(verts) < 17 {
			t.Errorf("esperaba al menos 17 vértices (16 + cierre), obtuvo %d", len(verts))
		}

		// Área esperada π * r² = π * 15² ≈ 706.85 m²
		area := geo.CalcularAreaGeodesica(poly)
		if area < 650.0 || area > 750.0 {
			t.Errorf("área esperada cercana a ~706 m², obtenida: %.2f m²", area)
		}
	})

	t.Run("AC-02: Rechazar radio inválido <= 0", func(t *testing.T) {
		_, err := geo.GenerarPoligonoCentroideRadio(centroide, -5.0, 16)
		if err == nil {
			t.Fatal("esperaba error por radio negativo, obtuvo nil")
		}
	})
}

func TestUS_GEO_11_GeoJSONImportExport(t *testing.T) {
	clk := shared.NewFakeClock(time.Date(2026, 9, 25, 12, 0, 0, 0, time.UTC))
	log := applog.New(applog.LevelDebug, nil)
	svc := usecaseGeo.NewService(nil, nil, nil, nil, nil, nil, clk, log)

	t.Run("AC-01 & AC-04: Previsualizar y detectar coordenadas invertidas [lat, lon]", func(t *testing.T) {
		// GeoJSON con orden invertido en Colombia: [lat (~4.65), lon (~-74.06)]
		rawGeoJSON := `{
			"type": "FeatureCollection",
			"features": [
				{
					"type": "Feature",
					"properties": {
						"codigo": "A-101",
						"nombre": "Aula 101 Invertida"
					},
					"geometry": {
						"type": "Polygon",
						"coordinates": [
							[
								[4.6500, -74.0650],
								[4.6500, -74.0649],
								[4.6501, -74.0649],
								[4.6501, -74.0650],
								[4.6500, -74.0650]
							]
						]
					}
				}
			]
		}`

		preview, err := svc.PreviewImportarGeoJSON([]byte(rawGeoJSON))
		if err != nil {
			t.Fatalf("error en preview: %v", err)
		}

		if preview.TotalElementos != 1 {
			t.Fatalf("esperaba 1 elemento, obtuvo %d", preview.TotalElementos)
		}
		item := preview.Elementos[0]
		if !item.CoordenadasInvert {
			t.Error("debió detectar coordenadas invertidas [lat, lon]")
		}
		if !item.Valido {
			t.Errorf("elemento debió ser normalizado y válido, errores: %v", item.Errores)
		}
		// Verificar que el vértice normalizado tenga longitud negativa en [0] y latitud positiva en [1]
		if item.Vertices[0][0] > 0 || item.Vertices[0][1] < 0 {
			t.Errorf("orden normalizado incorrecto: %v", item.Vertices[0])
		}
	})
}

func TestUS_GEO_12_ClonarPiso(t *testing.T) {
	clk := shared.NewFakeClock(time.Date(2026, 9, 25, 12, 0, 0, 0, time.UTC))
	log := applog.New(applog.LevelDebug, nil)

	bRepo := newMockBloqueRepo()
	_ = bRepo.Create(context.Background(), &geo.Bloque{
		ID:     "bloque-A",
		SedeID: "sede-1",
		Codigo: "B-A",
		Nombre: "Bloque A",
		Pisos:  []int{1, 2},
	})

	eRepo := newMockEspacioRepo()
	piso1 := 1
	_ = eRepo.Create(context.Background(), &geo.Espacio{
		ID:                  "esp-101",
		SedeID:              "sede-1",
		BloqueID:            strPtr("bloque-A"),
		Piso:                &piso1,
		Codigo:              "A-101",
		Nombre:              "Aula 101 Piso 1",
		BufferMetros:        10.0,
		VersionGeometria:    1,
		Activo:              true,
		FacultadResponsable: "Ingeniería",
		Tipo:                geo.TipoAula,
		Capacidad:           30,
	})
	_ = eRepo.Create(context.Background(), &geo.Espacio{
		ID:                  "esp-102",
		SedeID:              "sede-1",
		BloqueID:            strPtr("bloque-A"),
		Piso:                &piso1,
		Codigo:              "A-102",
		Nombre:              "Aula 102 Piso 1",
		BufferMetros:        10.0,
		VersionGeometria:    1,
		Activo:              true,
		FacultadResponsable: "Ingeniería",
		Tipo:                geo.TipoAula,
		Capacidad:           40,
	})

	svc := usecaseGeo.NewService(nil, bRepo, eRepo, nil, nil, nil, clk, log)

	t.Run("AC-01 & AC-02: Clonar piso 1 a piso 2 exitosamente", func(t *testing.T) {
		res, err := svc.ClonarPiso(context.Background(), usecaseGeo.ClonarPisoCmd{
			BloqueID:    "bloque-A",
			PisoOrigen:  1,
			PisoDestino: 2,
		})
		if err != nil {
			t.Fatalf("error clonando piso: %v", err)
		}

		if res.EspaciosClonados != 2 {
			t.Errorf("esperaba 2 espacios clonados, obtuvo %d", res.EspaciosClonados)
		}
		codigosMap := map[string]bool{}
		for _, c := range res.CodigosCreados {
			codigosMap[c] = true
		}
		if !codigosMap["A-201"] || !codigosMap["A-202"] {
			t.Errorf("códigos esperados [A-201, A-202], obtenidos: %v", res.CodigosCreados)
		}

		// Verificar que el espacio clonado esté en el piso 2
		clonado, err := eRepo.FindByCodigo(context.Background(), "A-201")
		if err != nil || clonado == nil {
			t.Fatal("espacio clonado A-201 no encontrado")
		}
		if *clonado.Piso != 2 {
			t.Errorf("esperaba piso 2, obtuvo %d", *clonado.Piso)
		}
	})

	t.Run("AC-03: Rechazar clonación al mismo piso", func(t *testing.T) {
		_, err := svc.ClonarPiso(context.Background(), usecaseGeo.ClonarPisoCmd{
			BloqueID:    "bloque-A",
			PisoOrigen:  1,
			PisoDestino: 1,
		})
		if err == nil {
			t.Fatal("esperaba error por piso destino igual a origen, obtuvo nil")
		}
	})
}

func makePoint(t *testing.T, lon, lat float64) geo.GeoPoint {
	t.Helper()
	p, err := geo.NewGeoPoint(lon, lat)
	if err != nil {
		t.Fatalf("punto inválido [%.4f, %.4f]: %v", lon, lat, err)
	}
	return p
}

func strPtr(s string) *string {
	return &s
}
