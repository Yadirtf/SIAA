// Package impl — BSON document structures y mapeadores para Espacios (US-GEO-01).
package impl

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"

	"github.com/siaa/backend/internal/domain/geo"
)

type geoJSONPolygonDoc struct {
	Type        string         `bson:"type"`
	Coordinates [][][2]float64 `bson:"coordinates"`
}

type geoJSONPointDoc struct {
	Type        string     `bson:"type"`
	Coordinates [2]float64 `bson:"coordinates"`
}

type espacioDoc struct {
	ID                      primitive.ObjectID `bson:"_id,omitempty"`
	SedeID                  string             `bson:"sedeId"`
	Torre                   *string            `bson:"torre,omitempty"`
	BloqueID                *string            `bson:"bloqueId,omitempty"`
	Piso                    *int               `bson:"piso,omitempty"`
	Codigo                  string             `bson:"codigo"`
	Nombre                  string             `bson:"nombre"`
	Capacidad               int                `bson:"capacidad"`
	Tipo                    string             `bson:"tipo"`
	FacultadResponsable     string             `bson:"facultadResponsable"`
	Estado                  string             `bson:"estado"`
	NivelValidacion         string             `bson:"nivelValidacion"`
	BufferMetros            float64            `bson:"bufferMetros"`
	Geometria               *geoJSONPolygonDoc `bson:"geometria,omitempty"`
	GeometriaBuffer         *geoJSONPolygonDoc `bson:"geometriaBuffer,omitempty"`
	RadioMetros             *float64           `bson:"radioMetros,omitempty"`
	AreaMetrosCuadrados     float64            `bson:"areaMetrosCuadrados,omitempty"`
	Centroide               *geoJSONPointDoc   `bson:"centroide,omitempty"`
	PrecisionPromedioMetros *float64           `bson:"precisionPromedioMetros,omitempty"`
	MetodoCaptura           *string            `bson:"metodoCaptura,omitempty"`
	VersionGeometria        int                `bson:"versionGeometria"`
	Activo                  bool               `bson:"activo"`
	Eliminado               bool               `bson:"eliminado"`
	CreadoEn                time.Time          `bson:"creadoEn"`
	ActualizadoEn           time.Time          `bson:"actualizadoEn"`
}

func docToEspacio(doc *espacioDoc) *geo.Espacio {
	esp := &geo.Espacio{
		ID:                      doc.ID.Hex(),
		SedeID:                  doc.SedeID,
		Torre:                   doc.Torre,
		BloqueID:                doc.BloqueID,
		Piso:                    doc.Piso,
		Codigo:                  doc.Codigo,
		Nombre:                  doc.Nombre,
		Capacidad:               doc.Capacidad,
		Tipo:                    geo.TipoEspacio(doc.Tipo),
		FacultadResponsable:     doc.FacultadResponsable,
		Estado:                  geo.EstadoEspacio(doc.Estado),
		NivelValidacion:         geo.NivelValidacion(doc.NivelValidacion),
		BufferMetros:            doc.BufferMetros,
		AreaMetrosCuadrados:     doc.AreaMetrosCuadrados,
		PrecisionPromedioMetros: doc.PrecisionPromedioMetros,
		VersionGeometria:        doc.VersionGeometria,
		Activo:                  doc.Activo,
		Eliminado:               doc.Eliminado,
		CreadoEn:                doc.CreadoEn,
		ActualizadoEn:           doc.ActualizadoEn,
	}
	if doc.MetodoCaptura != nil {
		m := geo.MetodoCaptura(*doc.MetodoCaptura)
		esp.MetodoCaptura = &m
	}
	if doc.Centroide != nil {
		if pt, err := geo.NewGeoPoint(doc.Centroide.Coordinates[0], doc.Centroide.Coordinates[1]); err == nil {
			esp.Centroide = &pt
		}
	}
	if doc.Geometria != nil && len(doc.Geometria.Coordinates) > 0 {
		ring := doc.Geometria.Coordinates[0]
		vertices := make([]geo.GeoPoint, 0, len(ring))
		for _, c := range ring {
			if pt, err := geo.NewGeoPoint(c[0], c[1]); err == nil {
				vertices = append(vertices, pt)
			}
		}
		if poly, err := geo.NewGeoPolygon(vertices); err == nil {
			esp.Geometria = &poly
		}
	}
	if doc.GeometriaBuffer != nil && len(doc.GeometriaBuffer.Coordinates) > 0 {
		ringBuf := doc.GeometriaBuffer.Coordinates[0]
		verticesBuf := make([]geo.GeoPoint, 0, len(ringBuf))
		for _, c := range ringBuf {
			if pt, err := geo.NewGeoPoint(c[0], c[1]); err == nil {
				verticesBuf = append(verticesBuf, pt)
			}
		}
		if polyBuf, err := geo.NewGeoPolygon(verticesBuf); err == nil {
			esp.GeometriaBuffer = &polyBuf
		}
	}
	esp.RadioMetros = doc.RadioMetros
	return esp
}
