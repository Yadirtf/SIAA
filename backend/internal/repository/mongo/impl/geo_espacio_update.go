package impl

import (
	"context"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"

	"github.com/siaa/backend/internal/domain/geo"
)

func (r *espacioRepository) Update(ctx context.Context, e *geo.Espacio) error {
	oid, err := primitive.ObjectIDFromHex(e.ID)
	if err != nil {
		return fmt.Errorf("invalid espacio ID: %w", err)
	}
	_, err = r.col.UpdateByID(ctx, oid, camposActualizables(e))
	return err
}

// UpdateSiVersion aplica la actualización solo si versionGeometria sigue siendo versionLeida
// (compare-and-set atómico en un único updateOne). Devuelve false si otro guardado ganó.
func (r *espacioRepository) UpdateSiVersion(ctx context.Context, e *geo.Espacio, versionLeida int) (bool, error) {
	oid, err := primitive.ObjectIDFromHex(e.ID)
	if err != nil {
		return false, fmt.Errorf("invalid espacio ID: %w", err)
	}
	filtro := bson.D{{Key: "_id", Value: oid}, {Key: "versionGeometria", Value: versionLeida}}
	if versionLeida == 0 {
		// Documentos antiguos pueden no tener el campo: equivale a la versión 0.
		filtro = bson.D{{Key: "_id", Value: oid}, {Key: "$or", Value: bson.A{
			bson.D{{Key: "versionGeometria", Value: 0}},
			bson.D{{Key: "versionGeometria", Value: bson.D{{Key: "$exists", Value: false}}}},
		}}}
	}
	res, err := r.col.UpdateOne(ctx, filtro, camposActualizables(e))
	if err != nil {
		return false, err
	}
	return res.MatchedCount == 1, nil
}

// camposActualizables construye el $set completo de un espacio.
func camposActualizables(e *geo.Espacio) bson.D {

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

	return bson.D{{Key: "$set", Value: bson.D{
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
		{Key: "verificacionComplementaria", Value: verificacionADoc(e.VerificacionComplementaria)},
		{Key: "activo", Value: e.Activo},
		{Key: "actualizadoEn", Value: time.Now().UTC()},
	}}}
}
