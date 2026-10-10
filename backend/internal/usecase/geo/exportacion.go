// Package geo — exportación de cartografía en GeoJSON y KML (US-GEO-11 AC-03).
package geo

import (
	"context"
	"fmt"
	"io"
	"strconv"

	"github.com/siaa/backend/internal/domain/geo"
	"github.com/siaa/backend/internal/platform/kml"
	"github.com/siaa/backend/internal/repository"
)

// espaciosExportables lista los espacios vigentes con geometría de la sede/bloque.
func (s *Service) espaciosExportables(ctx context.Context, sedeID, bloqueID string) ([]*geo.Espacio, error) {
	espacios, err := s.espacioRepo.List(ctx, repository.EspacioFilter{SedeID: sedeID, BloqueID: bloqueID})
	if err != nil {
		return nil, fmt.Errorf("consultar espacios para exportación: %w", err)
	}
	res := make([]*geo.Espacio, 0, len(espacios))
	for _, esp := range espacios {
		if esp.Geometria != nil && esp.Activo && !esp.Eliminado {
			res = append(res, esp)
		}
	}
	return res, nil
}

// metadatosExportacion son los atributos de un espacio que viajan en ambos formatos.
func metadatosExportacion(esp *geo.Espacio) map[string]interface{} {
	props := map[string]interface{}{
		"id":                  esp.ID,
		"codigo":              esp.Codigo,
		"nombre":              esp.Nombre,
		"capacidad":           esp.Capacidad,
		"tipo":                string(esp.Tipo),
		"areaMetrosCuadrados": esp.AreaMetrosCuadrados,
		"bufferMetros":        esp.BufferMetros,
		"versionGeometria":    esp.VersionGeometria,
		"sedeId":              esp.SedeID,
	}
	if esp.Piso != nil {
		props["piso"] = *esp.Piso
	}
	if esp.BloqueID != nil {
		props["bloqueId"] = *esp.BloqueID
	}
	return props
}

// clavesKML fija el orden de ExtendedData en el KML exportado.
var clavesKML = []string{"codigo", "nombre", "tipo", "capacidad", "piso", "bloqueId", "sedeId",
	"areaMetrosCuadrados", "bufferMetros", "versionGeometria", "id"}

// ExportarEspaciosGeoJSON genera un FeatureCollection con la cartografía de la sede/bloque (US-GEO-11 AC-03).
func (s *Service) ExportarEspaciosGeoJSON(ctx context.Context, sedeID, bloqueID string) (*GeoJSONFeatureCollection, error) {
	espacios, err := s.espaciosExportables(ctx, sedeID, bloqueID)
	if err != nil {
		return nil, err
	}
	fc := &GeoJSONFeatureCollection{Type: "FeatureCollection", Features: make([]GeoJSONFeature, 0, len(espacios))}
	for _, esp := range espacios {
		fc.Features = append(fc.Features, GeoJSONFeature{
			Type: "Feature",
			Geometry: GeoJSONGeometry{
				Type:        "Polygon",
				Coordinates: [][][2]float64{esp.Geometria.Coordinates()},
			},
			Properties: metadatosExportacion(esp),
		})
	}
	return fc, nil
}

// ExportarEspaciosKML escribe un documento KML 2.2 con un Placemark por espacio: nombre,
// descripción legible, ExtendedData con código y metadatos, y el polígono (US-GEO-11 AC-03).
func (s *Service) ExportarEspaciosKML(ctx context.Context, w io.Writer, sedeID, bloqueID string) error {
	espacios, err := s.espaciosExportables(ctx, sedeID, bloqueID)
	if err != nil {
		return err
	}
	salida := make([]kml.Espacio, 0, len(espacios))
	for _, esp := range espacios {
		datos := map[string]string{}
		claves := make([]string, 0, len(clavesKML))
		props := metadatosExportacion(esp)
		for _, k := range clavesKML {
			v, ok := props[k]
			if !ok {
				continue
			}
			datos[k] = textoMetadato(v)
			claves = append(claves, k)
		}
		salida = append(salida, kml.Espacio{
			Nombre:      esp.Nombre,
			Descripcion: fmt.Sprintf("%s · %s · capacidad %d · %.1f m²", esp.Codigo, esp.Tipo, esp.Capacidad, esp.AreaMetrosCuadrados),
			Datos:       datos,
			Claves:      claves,
			Anillo:      esp.Geometria.Coordinates(),
		})
	}
	return kml.Encode(w, "Cartografía SIAA", salida)
}

func textoMetadato(v interface{}) string {
	switch t := v.(type) {
	case float64:
		return strconv.FormatFloat(t, 'f', -1, 64)
	case int:
		return strconv.Itoa(t)
	default:
		return fmt.Sprint(t)
	}
}
