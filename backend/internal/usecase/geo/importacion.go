// Package geo — importación y exportación de cartografía GeoJSON (US-GEO-11).
// Satisface US-GEO-11 (AC-01..AC-04) y RF-GEO-011.
package geo

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"

	"github.com/siaa/backend/internal/domain/geo"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/repository"
)

// GeoJSONFeatureCollection representa una colección estándar GeoJSON.
type GeoJSONFeatureCollection struct {
	Type     string           `json:"type"`
	Features []GeoJSONFeature `json:"features"`
}

// GeoJSONFeature representa una característica individual GeoJSON.
type GeoJSONFeature struct {
	Type       string                 `json:"type"`
	Geometry   GeoJSONGeometry        `json:"geometry"`
	Properties map[string]interface{} `json:"properties"`
}

// GeoJSONGeometry representa la geometría GeoJSON.
type GeoJSONGeometry struct {
	Type        string         `json:"type"`
	Coordinates [][][2]float64 `json:"coordinates"`
}

// ItemPreviewImportacion representa el resultado del análisis preliminar de un espacio importado.
type ItemPreviewImportacion struct {
	Indice            int          `json:"indice"`
	Codigo            string       `json:"codigo"`
	Nombre            string       `json:"nombre"`
	Tipo              string       `json:"tipo"`
	Capacidad         int          `json:"capacidad"`
	Valido            bool         `json:"valido"`
	CoordenadasInvert bool         `json:"coordenadasInvertidas"`
	Vertices          [][2]float64 `json:"vertices,omitempty"`
	Errores           []string     `json:"errores,omitempty"`
	Advertencias      []string     `json:"advertencias,omitempty"`
}

// PreviewImportacionDTO es la respuesta para la previsualización de importación.
type PreviewImportacionDTO struct {
	TotalElementos int                      `json:"totalElementos"`
	Validos        int                      `json:"validos"`
	Invalidos      int                      `json:"invalidos"`
	Elementos      []ItemPreviewImportacion `json:"elementos"`
}

// PreviewImportarGeoJSON analiza un payload GeoJSON, valida cada espacio y detecta si las coordenadas vienen invertidas (US-GEO-11 AC-01, AC-04).
func (s *Service) PreviewImportarGeoJSON(data []byte) (*PreviewImportacionDTO, error) {
	var fc GeoJSONFeatureCollection
	if err := json.Unmarshal(data, &fc); err != nil {
		return nil, shared.NewValidationError("El archivo no es un GeoJSON válido", shared.FieldError{
			Campo: "archivo", Error: "FORMATO_GEOJSON_INVALIDO",
		})
	}

	res := &PreviewImportacionDTO{
		TotalElementos: len(fc.Features),
		Elementos:      make([]ItemPreviewImportacion, 0, len(fc.Features)),
	}

	for i, f := range fc.Features {
		item := ItemPreviewImportacion{
			Indice:  i + 1,
			Valido:  true,
			Errores: []string{},
		}

		if f.Properties != nil {
			if cod, ok := f.Properties["codigo"].(string); ok {
				item.Codigo = strings.TrimSpace(cod)
			}
			if nom, ok := f.Properties["nombre"].(string); ok {
				item.Nombre = strings.TrimSpace(nom)
			}
			if capVal, ok := f.Properties["capacidad"].(float64); ok {
				item.Capacidad = int(capVal)
			}
			if tip, ok := f.Properties["tipo"].(string); ok {
				item.Tipo = strings.ToUpper(strings.TrimSpace(tip))
			}
		}

		if item.Codigo == "" {
			item.Codigo = fmt.Sprintf("IMP-%d", i+1)
			item.Advertencias = append(item.Advertencias, "Código no provisto, asignado código provisional")
		}
		if item.Nombre == "" {
			item.Nombre = fmt.Sprintf("Espacio Importado %d", i+1)
		}
		if item.Tipo == "" {
			item.Tipo = "AULA"
		}

		if f.Geometry.Type != "Polygon" || len(f.Geometry.Coordinates) == 0 {
			item.Valido = false
			item.Errores = append(item.Errores, "La geometría debe ser de tipo Polygon con anillo cerrado")
			res.Invalidos++
			res.Elementos = append(res.Elementos, item)
			continue
		}

		ring := f.Geometry.Coordinates[0]
		if len(ring) < 3 {
			item.Valido = false
			item.Errores = append(item.Errores, "El polígono debe tener al menos 3 vértices")
			res.Invalidos++
			res.Elementos = append(res.Elementos, item)
			continue
		}

		// AC-04: Detección de coordenadas invertidas [lat, lon]
		invertidas := false
		for _, coord := range ring {
			c0, c1 := coord[0], coord[1]
			// Longitud válida mundial: [-180, 180]; Latitud válida: [-90, 90]
			// En Colombia / Sudamérica: Latitud ~ [-5, 15], Longitud ~ [-85, -60]
			if (c0 >= -10 && c0 <= 20) && (c1 >= -90 && c1 <= -50) {
				invertidas = true
				break
			}
		}

		if invertidas {
			item.CoordenadasInvert = true
			item.Advertencias = append(item.Advertencias, "Se detectó orden [latitud, longitud] invertido; normalizado a [longitud, latitud]")
		}

		normalizedVerts := make([]geo.GeoPoint, 0, len(ring))
		coordsArray := make([][2]float64, 0, len(ring))

		for _, coord := range ring {
			lon, lat := coord[0], coord[1]
			if invertidas {
				lon, lat = coord[1], coord[0]
			}
			pt, errPt := geo.NewGeoPoint(lon, lat)
			if errPt != nil {
				item.Valido = false
				item.Errores = append(item.Errores, fmt.Sprintf("Vértice inválido [%.6f, %.6f]: %v", lon, lat, errPt))
			} else {
				normalizedVerts = append(normalizedVerts, pt)
				coordsArray = append(coordsArray, [2]float64{lon, lat})
			}
		}

		if item.Valido {
			if _, errPoly := geo.NewGeoPolygon(normalizedVerts); errPoly != nil {
				item.Valido = false
				item.Errores = append(item.Errores, fmt.Sprintf("Polígono geodésico no conformante: %v", errPoly))
			}
		}

		item.Vertices = coordsArray
		if item.Valido {
			res.Validos++
		} else {
			res.Invalidos++
		}
		res.Elementos = append(res.Elementos, item)
	}

	return res, nil
}

// ConfirmarImportarGeoJSONCmd contiene los datos para persistir la importación confirmada.
type ConfirmarImportarGeoJSONCmd struct {
	SedeID    string                   `json:"sedeId"`
	BloqueID  *string                  `json:"bloqueId,omitempty"`
	Piso      *int                     `json:"piso,omitempty"`
	Elementos []ItemPreviewImportacion `json:"elementos"`
	Actor     ContextoActor            `json:"-"`
}

// ConfirmarImportarGeoJSON persiste los espacios validados (US-GEO-11 AC-02).
func (s *Service) ConfirmarImportarGeoJSON(ctx context.Context, cmd ConfirmarImportarGeoJSONCmd) (int, error) {
	if cmd.SedeID == "" {
		return 0, shared.NewValidationError("La sede es obligatoria para la importación", shared.FieldError{
			Campo: "sedeId", Error: "SEDE_REQUERIDA",
		})
	}

	now := s.clk.Now()
	creados := 0

	for _, item := range cmd.Elementos {
		if !item.Valido || len(item.Vertices) < 3 {
			continue
		}

		existente, _ := s.espacioRepo.FindByCodigo(ctx, item.Codigo)
		if existente != nil {
			continue // Omitir colisiones existentes
		}

		tipo := geo.TipoEspacio(item.Tipo)
		if !geo.EsTipoEspacioValido(tipo) {
			tipo = geo.TipoAula
		}

		verts := make([]geo.GeoPoint, 0, len(item.Vertices))
		for _, c := range item.Vertices {
			if pt, err := geo.NewGeoPoint(c[0], c[1]); err == nil {
				verts = append(verts, pt)
			}
		}
		poly, err := geo.NewGeoPolygon(verts)
		if err != nil {
			continue
		}

		esp := &geo.Espacio{
			SedeID:           cmd.SedeID,
			BloqueID:         cmd.BloqueID,
			Piso:             cmd.Piso,
			Codigo:           item.Codigo,
			Nombre:           item.Nombre,
			Capacidad:        item.Capacidad,
			Tipo:             tipo,
			Estado:           geo.EstadoActivo,
			NivelValidacion:  geo.NivelAula,
			BufferMetros:     10.0,
			VersionGeometria: 0,
			Activo:           true,
			Eliminado:        false,
			CreadoEn:         now,
			ActualizadoEn:    now,
		}

		_ = esp.AsignarGeometria(poly, geo.MetodoImportacion, nil)

		if err := s.espacioRepo.Create(ctx, esp); err == nil {
			creados++
		}
	}

	s.auditar(ctx, "sede", cmd.SedeID, "ESPACIOS_IMPORTADOS_GEOJSON", cmd.Actor, nil, map[string]interface{}{
		"totalImportados": creados,
	})

	return creados, nil
}

// ExportarEspaciosGeoJSON genera un documento GeoJSON FeatureCollection con la cartografía de la sede/bloque (US-GEO-11 AC-03).
func (s *Service) ExportarEspaciosGeoJSON(ctx context.Context, sedeID, bloqueID string) (*GeoJSONFeatureCollection, error) {
	espacios, err := s.espacioRepo.List(ctx, repository.EspacioFilter{
		SedeID:   sedeID,
		BloqueID: bloqueID,
	})
	if err != nil {
		return nil, fmt.Errorf("consultar espacios para exportación: %w", err)
	}

	fc := &GeoJSONFeatureCollection{
		Type:     "FeatureCollection",
		Features: make([]GeoJSONFeature, 0, len(espacios)),
	}

	for _, esp := range espacios {
		if esp.Geometria == nil || !esp.Activo || esp.Eliminado {
			continue
		}

		props := map[string]interface{}{
			"id":                  esp.ID,
			"codigo":              esp.Codigo,
			"nombre":              esp.Nombre,
			"capacidad":           esp.Capacidad,
			"tipo":                string(esp.Tipo),
			"areaMetrosCuadrados": esp.AreaMetrosCuadrados,
			"bufferMetros":        esp.BufferMetros,
			"versionGeometria":    esp.VersionGeometria,
		}
		if esp.Piso != nil {
			props["piso"] = *esp.Piso
		}
		if esp.BloqueID != nil {
			props["bloqueId"] = *esp.BloqueID
		}

		feature := GeoJSONFeature{
			Type: "Feature",
			Geometry: GeoJSONGeometry{
				Type:        "Polygon",
				Coordinates: [][][2]float64{esp.Geometria.Coordinates()},
			},
			Properties: props,
		}
		fc.Features = append(fc.Features, feature)
	}

	return fc, nil
}
