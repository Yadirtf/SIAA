// Package impl — repositorio MongoDB para Espacios / Aulas (US-GEO-01, US-GEO-02, US-GEO-05).
package impl

import (
	"context"
	"errors"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"

	"github.com/siaa/backend/internal/domain/geo"
	"github.com/siaa/backend/internal/repository"
	mongoConn "github.com/siaa/backend/internal/repository/mongo"
)

type espacioRepository struct {
	col *mongo.Collection
}

func NewEspacioRepository(client *mongoConn.Client) repository.EspacioRepository {
	return &espacioRepository{col: client.Collection("espacios")}
}

func (r *espacioRepository) Create(ctx context.Context, e *geo.Espacio) error {
	doc := espacioDoc{
		SedeID:                  e.SedeID,
		Torre:                   e.Torre,
		BloqueID:                e.BloqueID,
		Piso:                    e.Piso,
		Codigo:                  e.Codigo,
		Nombre:                  e.Nombre,
		Capacidad:               e.Capacidad,
		Tipo:                    string(e.Tipo),
		FacultadResponsable:     e.FacultadResponsable,
		Estado:                  string(e.Estado),
		NivelValidacion:         string(e.NivelValidacion),
		BufferMetros:            e.BufferMetros,
		AreaMetrosCuadrados:     e.AreaMetrosCuadrados,
		PrecisionPromedioMetros: e.PrecisionPromedioMetros,
		VersionGeometria:        e.VersionGeometria,
		Activo:                  e.Activo,
		Eliminado:               false,
		CreadoEn:                e.CreadoEn,
		ActualizadoEn:           e.ActualizadoEn,
	}
	if e.Geometria != nil {
		doc.Geometria = &geoJSONPolygonDoc{
			Type:        "Polygon",
			Coordinates: [][][2]float64{e.Geometria.Coordinates()},
		}
	}
	if e.GeometriaBuffer != nil {
		doc.GeometriaBuffer = &geoJSONPolygonDoc{
			Type:        "Polygon",
			Coordinates: [][][2]float64{e.GeometriaBuffer.Coordinates()},
		}
	}
	doc.RadioMetros = e.RadioMetros
	if e.Centroide != nil {
		doc.Centroide = &geoJSONPointDoc{
			Type:        "Point",
			Coordinates: e.Centroide.Coordinates(),
		}
	}
	if e.MetodoCaptura != nil {
		m := string(*e.MetodoCaptura)
		doc.MetodoCaptura = &m
	}
	if e.ID != "" {
		if oid, err := primitive.ObjectIDFromHex(e.ID); err == nil {
			doc.ID = oid
		}
	}
	res, err := r.col.InsertOne(ctx, doc)
	if err != nil {
		return fmt.Errorf("create espacio: %w", err)
	}
	if oid, ok := res.InsertedID.(primitive.ObjectID); ok {
		e.ID = oid.Hex()
	}
	return nil
}

func (r *espacioRepository) FindByID(ctx context.Context, id string) (*geo.Espacio, error) {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, nil
	}
	var doc espacioDoc
	err = r.col.FindOne(ctx, bson.D{
		{Key: "_id", Value: oid},
		{Key: "eliminado", Value: false},
	}).Decode(&doc)
	if errors.Is(err, mongo.ErrNoDocuments) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("findEspacioByID: %w", err)
	}
	return docToEspacio(&doc), nil
}

func (r *espacioRepository) FindByCodigo(ctx context.Context, codigo string) (*geo.Espacio, error) {
	var doc espacioDoc
	err := r.col.FindOne(ctx, bson.D{
		{Key: "codigo", Value: codigo},
		{Key: "eliminado", Value: false},
	}).Decode(&doc)
	if errors.Is(err, mongo.ErrNoDocuments) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("findEspacioByCodigo: %w", err)
	}
	return docToEspacio(&doc), nil
}

func (r *espacioRepository) List(ctx context.Context, filter repository.EspacioFilter) ([]*geo.Espacio, error) {
	criteria := bson.D{{Key: "eliminado", Value: false}}

	if filter.SedeID != "" {
		criteria = append(criteria, bson.E{Key: "sedeId", Value: filter.SedeID})
	}
	if filter.BloqueID != "" {
		criteria = append(criteria, bson.E{Key: "bloqueId", Value: filter.BloqueID})
	}
	if filter.Piso != nil {
		criteria = append(criteria, bson.E{Key: "piso", Value: *filter.Piso})
	}
	if filter.Tipo != nil {
		criteria = append(criteria, bson.E{Key: "tipo", Value: string(*filter.Tipo)})
	}
	if filter.Estado != nil {
		criteria = append(criteria, bson.E{Key: "estado", Value: string(*filter.Estado)})
	}

	cursor, err := r.col.Find(ctx, criteria)
	if err != nil {
		return nil, fmt.Errorf("listEspacios: %w", err)
	}
	defer cursor.Close(ctx)

	var espacios []*geo.Espacio
	for cursor.Next(ctx) {
		var doc espacioDoc
		if err := cursor.Decode(&doc); err != nil {
			return nil, fmt.Errorf("decode espacio: %w", err)
		}
		espacios = append(espacios, docToEspacio(&doc))
	}
	return espacios, nil
}

func (r *espacioRepository) Update(ctx context.Context, e *geo.Espacio) error {
	oid, err := primitive.ObjectIDFromHex(e.ID)
	if err != nil {
		return fmt.Errorf("invalid espacio ID: %w", err)
	}

	var geomDoc *geoJSONPolygonDoc
	if e.Geometria != nil {
		geomDoc = &geoJSONPolygonDoc{
			Type:        "Polygon",
			Coordinates: [][][2]float64{e.Geometria.Coordinates()},
		}
	}
	var geomBufferDoc *geoJSONPolygonDoc
	if e.GeometriaBuffer != nil {
		geomBufferDoc = &geoJSONPolygonDoc{
			Type:        "Polygon",
			Coordinates: [][][2]float64{e.GeometriaBuffer.Coordinates()},
		}
	}
	var centroideDoc *geoJSONPointDoc
	if e.Centroide != nil {
		centroideDoc = &geoJSONPointDoc{
			Type:        "Point",
			Coordinates: e.Centroide.Coordinates(),
		}
	}
	var metodoStr *string
	if e.MetodoCaptura != nil {
		s := string(*e.MetodoCaptura)
		metodoStr = &s
	}

	update := bson.D{{Key: "$set", Value: bson.D{
		{Key: "sedeId", Value: e.SedeID},
		{Key: "torre", Value: e.Torre},
		{Key: "bloqueId", Value: e.BloqueID},
		{Key: "piso", Value: e.Piso},
		{Key: "codigo", Value: e.Codigo},
		{Key: "nombre", Value: e.Nombre},
		{Key: "capacidad", Value: e.Capacidad},
		{Key: "tipo", Value: string(e.Tipo)},
		{Key: "facultadResponsable", Value: e.FacultadResponsable},
		{Key: "estado", Value: string(e.Estado)},
		{Key: "nivelValidacion", Value: string(e.NivelValidacion)},
		{Key: "bufferMetros", Value: e.BufferMetros},
		{Key: "geometria", Value: geomDoc},
		{Key: "geometriaBuffer", Value: geomBufferDoc},
		{Key: "radioMetros", Value: e.RadioMetros},
		{Key: "areaMetrosCuadrados", Value: e.AreaMetrosCuadrados},
		{Key: "centroide", Value: centroideDoc},
		{Key: "precisionPromedioMetros", Value: e.PrecisionPromedioMetros},
		{Key: "metodoCaptura", Value: metodoStr},
		{Key: "versionGeometria", Value: e.VersionGeometria},
		{Key: "activo", Value: e.Activo},
		{Key: "actualizadoEn", Value: time.Now().UTC()},
	}}}
	_, err = r.col.UpdateByID(ctx, oid, update)
	return err
}

func (r *espacioRepository) SoftDelete(ctx context.Context, id string) error {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return fmt.Errorf("invalid espacio ID: %w", err)
	}
	update := bson.D{{Key: "$set", Value: bson.D{
		{Key: "eliminado", Value: true},
		{Key: "activo", Value: false},
		{Key: "actualizadoEn", Value: time.Now().UTC()},
	}}}
	_, err = r.col.UpdateByID(ctx, oid, update)
	return err
}

func (r *espacioRepository) BuscarIntersecciones(
	ctx context.Context,
	espacioID string,
	bloqueID *string,
	piso *int,
	geom geo.GeoPolygon,
) ([]*geo.Espacio, error) {
	filter := bson.D{
		{Key: "activo", Value: true},
		{Key: "eliminado", Value: false},
		{Key: "geometria", Value: bson.D{
			{Key: "$geoIntersects", Value: bson.D{
				{Key: "$geometry", Value: bson.D{
					{Key: "type", Value: "Polygon"},
					{Key: "coordinates", Value: [][][2]float64{geom.Coordinates()}},
				}},
			}},
		}},
	}

	if espacioID != "" {
		if oid, err := primitive.ObjectIDFromHex(espacioID); err == nil {
			filter = append(filter, bson.E{Key: "_id", Value: bson.D{{Key: "$ne", Value: oid}}})
		}
	}
	if bloqueID != nil && *bloqueID != "" {
		filter = append(filter, bson.E{Key: "bloqueId", Value: *bloqueID})
	}
	if piso != nil {
		filter = append(filter, bson.E{Key: "piso", Value: *piso})
	}

	cursor, err := r.col.Find(ctx, filter)
	if err != nil {
		return nil, fmt.Errorf("buscarIntersecciones: %w", err)
	}
	defer cursor.Close(ctx)

	var docs []espacioDoc
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decodeIntersecciones: %w", err)
	}

	res := make([]*geo.Espacio, 0, len(docs))
	for i := range docs {
		res = append(res, docToEspacio(&docs[i]))
	}
	return res, nil
}
