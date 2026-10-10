// Package geo — importación de cartografía GeoJSON y KML (US-GEO-11).
// Satisface US-GEO-11 (AC-01, AC-04) y RF-GEO-011: ambos formatos se reducen a candidatos
// comunes que pasan por la misma previsualización y validación (importacion_analisis.go).
package geo

import (
	"context"
	"encoding/json"
	"errors"
	"strconv"
	"strings"

	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/platform/kml"
)

// Formatos de intercambio de cartografía admitidos (US-GEO-11).
const (
	FormatoGeoJSON = "geojson"
	FormatoKML     = "kml"
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
	Formato        string                   `json:"formato"`
	TotalElementos int                      `json:"totalElementos"`
	Validos        int                      `json:"validos"`
	Invalidos      int                      `json:"invalidos"`
	Elementos      []ItemPreviewImportacion `json:"elementos"`
}

// candidatoImportacion es un elemento leído de cualquier formato, antes de validarse.
type candidatoImportacion struct {
	Codigo, Nombre, Tipo string
	Capacidad            int
	TipoGeometria        string
	Anillo               [][2]float64
	ErrorLectura         string
}

// geojsonEntrada decodifica coordenadas en crudo para no rechazar el archivo entero cuando
// una característica trae un Point o un MultiPolygon: ese elemento se reporta inválido.
type geojsonEntrada struct {
	Features []struct {
		Geometry struct {
			Type        string          `json:"type"`
			Coordinates json.RawMessage `json:"coordinates"`
		} `json:"geometry"`
		Properties map[string]interface{} `json:"properties"`
	} `json:"features"`
}

// PreviewImportar analiza el archivo en el formato indicado (o detectado por su contenido),
// valida cada espacio y marca los códigos que ya existen o se repiten (US-GEO-11 AC-01).
func (s *Service) PreviewImportar(ctx context.Context, data []byte, formato string) (*PreviewImportacionDTO, error) {
	formato = strings.ToLower(strings.TrimSpace(formato))
	if formato == "" {
		formato = FormatoGeoJSON
		if kml.PareceKML(data) {
			formato = FormatoKML
		}
	}
	var (
		cands []candidatoImportacion
		err   error
	)
	switch formato {
	case FormatoKML:
		cands, err = candidatosDesdeKML(data)
	case FormatoGeoJSON, "json":
		formato = FormatoGeoJSON
		cands, err = candidatosDesdeGeoJSON(data)
	default:
		return nil, shared.NewValidationError("Formato de importación no soportado; use geojson o kml",
			shared.FieldError{Campo: "formato", Error: "FORMATO_NO_SOPORTADO"})
	}
	if err != nil {
		return nil, err
	}
	res := analizarCandidatos(cands)
	res.Formato = formato
	s.marcarCodigosExistentes(ctx, res)
	return res, nil
}

// PreviewImportarGeoJSON analiza un payload GeoJSON sin consultar la base (compatibilidad).
func (s *Service) PreviewImportarGeoJSON(data []byte) (*PreviewImportacionDTO, error) {
	cands, err := candidatosDesdeGeoJSON(data)
	if err != nil {
		return nil, err
	}
	res := analizarCandidatos(cands)
	res.Formato = FormatoGeoJSON
	return res, nil
}

func candidatosDesdeGeoJSON(data []byte) ([]candidatoImportacion, error) {
	var fc geojsonEntrada
	if err := json.Unmarshal(data, &fc); err != nil {
		return nil, shared.NewValidationError("El archivo no es un GeoJSON válido", shared.FieldError{
			Campo: "archivo", Error: "FORMATO_GEOJSON_INVALIDO",
		})
	}
	res := make([]candidatoImportacion, 0, len(fc.Features))
	for _, f := range fc.Features {
		c := candidatoImportacion{TipoGeometria: f.Geometry.Type}
		if p := f.Properties; p != nil {
			c.Codigo, _ = p["codigo"].(string)
			c.Nombre, _ = p["nombre"].(string)
			c.Tipo, _ = p["tipo"].(string)
			if v, ok := p["capacidad"].(float64); ok {
				c.Capacidad = int(v)
			}
		}
		if c.TipoGeometria == "Polygon" {
			var anillos [][][2]float64
			if err := json.Unmarshal(f.Geometry.Coordinates, &anillos); err != nil {
				c.ErrorLectura = "Coordenadas del polígono ilegibles"
			} else if len(anillos) > 0 {
				c.Anillo = anillos[0]
			}
		}
		res = append(res, c)
	}
	return res, nil
}

// candidatosDesdeKML toma código y nombre de ExtendedData (codigo/nombre) y, en su defecto,
// de <name> (si parece un código, sin espacios) y <description>.
func candidatosDesdeKML(data []byte) ([]candidatoImportacion, error) {
	placemarks, err := kml.Parse(data)
	if err != nil {
		if errors.Is(err, kml.ErrNoEsKML) {
			return nil, shared.NewValidationError("El archivo no es un KML válido", shared.FieldError{
				Campo: "archivo", Error: "FORMATO_KML_INVALIDO",
			})
		}
		return nil, err
	}
	res := make([]candidatoImportacion, 0, len(placemarks))
	for _, p := range placemarks {
		c := candidatoImportacion{
			Codigo:        p.Datos["codigo"],
			Nombre:        p.Datos["nombre"],
			Tipo:          p.Datos["tipo"],
			TipoGeometria: p.TipoGeometria,
			Anillo:        p.Anillo,
			ErrorLectura:  p.ErrorCoordenadas,
		}
		if n, errN := strconv.Atoi(strings.TrimSpace(p.Datos["capacidad"])); errN == nil {
			c.Capacidad = n
		}
		nombreUsado := false
		if c.Codigo == "" && p.Nombre != "" && !strings.ContainsAny(p.Nombre, " \t") {
			c.Codigo, nombreUsado = p.Nombre, true
		}
		if c.Nombre == "" {
			switch {
			case !nombreUsado && p.Nombre != "":
				c.Nombre = p.Nombre
			case p.Descripcion != "" && len(p.Descripcion) <= 120:
				c.Nombre = p.Descripcion
			default:
				c.Nombre = p.Nombre
			}
		}
		res = append(res, c)
	}
	return res, nil
}
