// Package impl — repositorio MongoDB para historial de versiones de geometría (US-GEO-06).
package impl

import (
	"context"
	"errors"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"

	"github.com/siaa/backend/internal/domain/geo"
	"github.com/siaa/backend/internal/repository"
	mongoConn "github.com/siaa/backend/internal/repository/mongo"
)

type espacioGeometriaHistDoc struct {
	ID                      primitive.ObjectID `bson:"_id,omitempty"`
	EspacioID               string             `bson:"espacioId"`
	Version                 int                `bson:"version"`
	Geometria               *geoJSONPolygonDoc `bson:"geometria"`
	AreaMetrosCuadrados     float64            `bson:"areaMetrosCuadrados"`
	Centroide               *geoJSONPointDoc   `bson:"centroide,omitempty"`
	MetodoCaptura           *string            `bson:"metodoCaptura,omitempty"`
	PrecisionPromedioMetros *float64           `bson:"precisionPromedioMetros,omitempty"`
	CreadoPor               string             `bson:"creadoPor"`
	CreadoEn                time.Time          `bson:"creadoEn"`
	MotivoCambio            string             `bson:"motivoCambio,omitempty"`
}

type espacioGeometriaHistRepository struct {
	col *mongo.Collection
}

// NewEspacioGeometriaHistRepository crea una nueva instancia del repositorio histórico de geometrías.
func NewEspacioGeometriaHistRepository(client *mongoConn.Client) repository.EspacioGeometriaHistRepository {
	return &espacioGeometriaHistRepository{col: client.Collection("espacios_geometria_hist")}
}

// Create inserta un registro histórico inmutable (T-GEO-06.1).
func (r *espacioGeometriaHistRepository) Create(ctx context.Context, h *geo.EspacioGeometriaHist) error {
	var geomDoc *geoJSONPolygonDoc
	coords := h.Geometria.Coordinates()
	if len(coords) > 0 {
		geomDoc = &geoJSONPolygonDoc{
			Type:        "Polygon",
			Coordinates: [][][2]float64{coords},
		}
	}

	var centroideDoc *geoJSONPointDoc
	if h.Centroide != nil {
		centroideDoc = &geoJSONPointDoc{
			Type:        "Point",
			Coordinates: h.Centroide.Coordinates(),
		}
	}

	var metodo *string
	if h.MetodoCaptura != nil {
		m := string(*h.MetodoCaptura)
		metodo = &m
	}

	doc := espacioGeometriaHistDoc{
		EspacioID:               h.EspacioID,
		Version:                 h.Version,
		Geometria:               geomDoc,
		AreaMetrosCuadrados:     h.AreaMetrosCuadrados,
		Centroide:               centroideDoc,
		MetodoCaptura:           metodo,
		PrecisionPromedioMetros: h.PrecisionPromedioMetros,
		CreadoPor:               h.CreadoPor,
		CreadoEn:                h.CreadoEn,
		MotivoCambio:            h.MotivoCambio,
	}

	res, err := r.col.InsertOne(ctx, doc)
	if err != nil {
		return fmt.Errorf("create espacioGeometriaHist: %w", err)
	}
	if oid, ok := res.InsertedID.(primitive.ObjectID); ok {
		h.ID = oid.Hex()
	}
	return nil
}

// ListByEspacioID lista todas las versiones de geometría de un espacio ordenadas descendentemente por versión (AC-04).
func (r *espacioGeometriaHistRepository) ListByEspacioID(ctx context.Context, espacioID string) ([]*geo.EspacioGeometriaHist, error) {
	opts := options.Find().SetSort(bson.D{{Key: "version", Value: -1}})
	cursor, err := r.col.Find(ctx, bson.D{{Key: "espacioId", Value: espacioID}}, opts)
	if err != nil {
		return nil, fmt.Errorf("listEspaciosGeometriaHist: %w", err)
	}
	defer cursor.Close(ctx)

	var list []*geo.EspacioGeometriaHist
	for cursor.Next(ctx) {
		var doc espacioGeometriaHistDoc
		if err := cursor.Decode(&doc); err != nil {
			return nil, fmt.Errorf("decode espacioGeometriaHist: %w", err)
		}
		list = append(list, mapDocToEspacioGeometriaHist(&doc))
	}
	return list, nil
}

// FindByEspacioIDAndVersion busca una versión específica de la geometría de un espacio (T-GEO-06.3, AC-03).
func (r *espacioGeometriaHistRepository) FindByEspacioIDAndVersion(ctx context.Context, espacioID string, version int) (*geo.EspacioGeometriaHist, error) {
	var doc espacioGeometriaHistDoc
	err := r.col.FindOne(ctx, bson.D{
		{Key: "espacioId", Value: espacioID},
		{Key: "version", Value: version},
	}).Decode(&doc)
	if errors.Is(err, mongo.ErrNoDocuments) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("findEspacioGeometriaHistByVersion: %w", err)
	}
	return mapDocToEspacioGeometriaHist(&doc), nil
}

func mapDocToEspacioGeometriaHist(doc *espacioGeometriaHistDoc) *geo.EspacioGeometriaHist {
	h := &geo.EspacioGeometriaHist{
		ID:                      doc.ID.Hex(),
		EspacioID:               doc.EspacioID,
		Version:                 doc.Version,
		AreaMetrosCuadrados:     doc.AreaMetrosCuadrados,
		PrecisionPromedioMetros: doc.PrecisionPromedioMetros,
		CreadoPor:               doc.CreadoPor,
		CreadoEn:                doc.CreadoEn,
		MotivoCambio:            doc.MotivoCambio,
	}
	if doc.MetodoCaptura != nil {
		m := geo.MetodoCaptura(*doc.MetodoCaptura)
		h.MetodoCaptura = &m
	}
	if doc.Centroide != nil {
		if pt, err := geo.NewGeoPoint(doc.Centroide.Coordinates[0], doc.Centroide.Coordinates[1]); err == nil {
			h.Centroide = &pt
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
			h.Geometria = poly
		}
	}
	return h
}
