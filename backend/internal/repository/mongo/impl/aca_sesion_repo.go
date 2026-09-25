// Package impl — repositorio MongoDB para sesiones académicas.
// Satisface US-ACA-05, US-ACA-06, US-ACA-08 y US-MAR-01.
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

	"github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/domain/geo"
	"github.com/siaa/backend/internal/repository"
	mongoConn "github.com/siaa/backend/internal/repository/mongo"
)

type sesionDoc struct {
	ID                      primitive.ObjectID `bson:"_id,omitempty"`
	PeriodoID               string             `bson:"periodoId"`
	AsignacionID            string             `bson:"asignacionId"`
	AsignaturaID            string             `bson:"asignaturaId"`
	GrupoID                 string             `bson:"grupoId"`
	DocenteIDs              []string           `bson:"docenteIds"`
	EspacioID               string             `bson:"espacioId"`
	Fecha                   string             `bson:"fecha"`
	HoraInicio              string             `bson:"horaInicio"`
	HoraFin                 string             `bson:"horaFin"`
	InicioProgramado        time.Time          `bson:"inicioProgramado"`
	FinProgramado           time.Time          `bson:"finProgramado"`
	VentanaEntradaAbre      time.Time          `bson:"ventanaEntradaAbre"`
	VentanaEntradaCierra    time.Time          `bson:"ventanaEntradaCierra"`
	VentanaSalidaAbre       *time.Time         `bson:"ventanaSalidaAbre,omitempty"`
	VentanaSalidaCierra     *time.Time         `bson:"ventanaSalidaCierra,omitempty"`
	Estado                  string             `bson:"estado"`
	EspacioVersionGeometria int                `bson:"espacioVersionGeometria"`
	GeometriaSnapshot       *geoJSONPolygonDoc `bson:"geometriaSnapshot,omitempty"`
	GeometriaBufferSnapshot *geoJSONPolygonDoc `bson:"geometriaBufferSnapshot,omitempty"`
	ParametrosCongelados    bson.M             `bson:"parametrosCongelados"`
	MotivoCancelacion       string             `bson:"motivoCancelacion,omitempty"`
	Eliminado               bool               `bson:"eliminado"`
	CreadoEn                time.Time          `bson:"creadoEn"`
	ActualizadoEn           time.Time          `bson:"actualizadoEn"`
}

type sesionRepository struct {
	col *mongo.Collection
}

// NewSesionRepository crea una nueva instancia del repositorio MongoDB de sesiones.
func NewSesionRepository(client *mongoConn.Client) repository.SesionRepository {
	return &sesionRepository{col: client.Collection("sesiones")}
}

func (r *sesionRepository) Create(ctx context.Context, s *academico.Sesion) error {
	doc := toSesionDoc(s)
	res, err := r.col.InsertOne(ctx, doc)
	if err != nil {
		return fmt.Errorf("create sesion: %w", err)
	}
	if oid, ok := res.InsertedID.(primitive.ObjectID); ok {
		_ = oid
	}
	return nil
}

func (r *sesionRepository) CreateBatch(ctx context.Context, sesiones []*academico.Sesion) (int, error) {
	if len(sesiones) == 0 {
		return 0, nil
	}
	docs := make([]interface{}, len(sesiones))
	for i, s := range sesiones {
		docs[i] = toSesionDoc(s)
	}
	opts := options.InsertMany().SetOrdered(false)
	res, err := r.col.InsertMany(ctx, docs, opts)
	if err != nil {
		if res != nil {
			return len(res.InsertedIDs), err
		}
		return 0, err
	}
	return len(res.InsertedIDs), nil
}

func (r *sesionRepository) FindByID(ctx context.Context, id string) (*academico.Sesion, error) {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, nil
	}
	var doc sesionDoc
	err = r.col.FindOne(ctx, bson.D{
		{Key: "_id", Value: oid},
		{Key: "eliminado", Value: false},
	}).Decode(&doc)
	if errors.Is(err, mongo.ErrNoDocuments) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("findSesionByID: %w", err)
	}
	return docToSesion(&doc), nil
}

func (r *sesionRepository) FindByAsignacionFechaHora(ctx context.Context, asignacionID string, fecha string, horaInicio string) (*academico.Sesion, error) {
	var doc sesionDoc
	err := r.col.FindOne(ctx, bson.D{
		{Key: "asignacionId", Value: asignacionID},
		{Key: "fecha", Value: fecha},
		{Key: "horaInicio", Value: horaInicio},
		{Key: "eliminado", Value: false},
	}).Decode(&doc)
	if errors.Is(err, mongo.ErrNoDocuments) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("findSesionByAsignacionFechaHora: %w", err)
	}
	return docToSesion(&doc), nil
}

func (r *sesionRepository) ListByPeriodo(ctx context.Context, periodoID string) ([]*academico.Sesion, error) {
	return r.List(ctx, repository.SesionFilter{PeriodoID: periodoID})
}

func (r *sesionRepository) ListByDocenteYFecha(ctx context.Context, docenteID string, fecha string) ([]*academico.Sesion, error) {
	return r.List(ctx, repository.SesionFilter{DocenteID: docenteID, Fecha: fecha})
}

func (r *sesionRepository) List(ctx context.Context, filter repository.SesionFilter) ([]*academico.Sesion, error) {
	criteria := bson.D{{Key: "eliminado", Value: false}}

	if filter.PeriodoID != "" {
		criteria = append(criteria, bson.E{Key: "periodoId", Value: filter.PeriodoID})
	}
	if filter.AsignacionID != "" {
		criteria = append(criteria, bson.E{Key: "asignacionId", Value: filter.AsignacionID})
	}
	if filter.DocenteID != "" {
		criteria = append(criteria, bson.E{Key: "docenteIds", Value: filter.DocenteID})
	}
	if filter.EspacioID != "" {
		criteria = append(criteria, bson.E{Key: "espacioId", Value: filter.EspacioID})
	}
	if filter.Fecha != "" {
		criteria = append(criteria, bson.E{Key: "fecha", Value: filter.Fecha})
	}
	if filter.Estado != nil {
		criteria = append(criteria, bson.E{Key: "estado", Value: string(*filter.Estado)})
	}

	opts := options.Find().SetSort(bson.D{{Key: "inicioProgramado", Value: 1}})
	cursor, err := r.col.Find(ctx, criteria, opts)
	if err != nil {
		return nil, fmt.Errorf("listSesiones: %w", err)
	}
	defer cursor.Close(ctx)

	var docs []sesionDoc
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decodeSesiones: %w", err)
	}

	res := make([]*academico.Sesion, len(docs))
	for i := range docs {
		res[i] = docToSesion(&docs[i])
	}
	return res, nil
}

func (r *sesionRepository) Update(ctx context.Context, s *academico.Sesion) error {
	oid, err := primitive.ObjectIDFromHex(s.ID())
	if err != nil {
		return fmt.Errorf("invalid sesion ID: %w", err)
	}
	update := bson.D{{Key: "$set", Value: bson.D{
		{Key: "espacioId", Value: s.EspacioID()},
		{Key: "estado", Value: string(s.Estado())},
		{Key: "espacioVersionGeometria", Value: s.EspacioVersionGeometria()},
		{Key: "motivoCancelacion", Value: s.MotivoCancelacion()},
		{Key: "actualizadoEn", Value: time.Now().UTC()},
	}}}
	_, err = r.col.UpdateByID(ctx, oid, update)
	return err
}

func (r *sesionRepository) CountSesionesFuturasPorEspacio(ctx context.Context, espacioID string, desde time.Time) (int64, error) {
	return r.col.CountDocuments(ctx, bson.D{
		{Key: "espacioId", Value: espacioID},
		{Key: "inicioProgramado", Value: bson.D{{Key: "$gt", Value: desde}}},
		{Key: "estado", Value: bson.D{{Key: "$ne", Value: string(academico.EstadoSesionCancelada)}}},
		{Key: "eliminado", Value: false},
	})
}

func toSesionDoc(s *academico.Sesion) sesionDoc {
	doc := sesionDoc{
		PeriodoID:               s.PeriodoID(),
		AsignacionID:            s.AsignacionID(),
		AsignaturaID:            s.AsignaturaID(),
		GrupoID:                 s.GrupoID(),
		DocenteIDs:              s.DocenteIDs(),
		EspacioID:               s.EspacioID(),
		Fecha:                   s.Fecha(),
		HoraInicio:              s.HoraInicio(),
		HoraFin:                 s.HoraFin(),
		InicioProgramado:        s.InicioProgramado(),
		FinProgramado:           s.FinProgramado(),
		VentanaEntradaAbre:      s.VentanaEntradaAbre(),
		VentanaEntradaCierra:    s.VentanaEntradaCierra(),
		VentanaSalidaAbre:       s.VentanaSalidaAbre(),
		VentanaSalidaCierra:     s.VentanaSalidaCierra(),
		Estado:                  string(s.Estado()),
		EspacioVersionGeometria: s.EspacioVersionGeometria(),
		ParametrosCongelados:    s.ParametrosCongelados(),
		MotivoCancelacion:       s.MotivoCancelacion(),
		Eliminado:               false,
		CreadoEn:                s.CreadoEn(),
		ActualizadoEn:           s.ActualizadoEn(),
	}
	if s.ID() != "" {
		if oid, err := primitive.ObjectIDFromHex(s.ID()); err == nil {
			doc.ID = oid
		}
	}
	if s.GeometriaSnapshot() != nil {
		doc.GeometriaSnapshot = &geoJSONPolygonDoc{
			Type:        "Polygon",
			Coordinates: [][][2]float64{s.GeometriaSnapshot().Coordinates()},
		}
	}
	if s.GeometriaBufferSnapshot() != nil {
		doc.GeometriaBufferSnapshot = &geoJSONPolygonDoc{
			Type:        "Polygon",
			Coordinates: [][][2]float64{s.GeometriaBufferSnapshot().Coordinates()},
		}
	}
	return doc
}

func docToSesion(doc *sesionDoc) *academico.Sesion {
	var geomSnap *geo.GeoPolygon
	if doc.GeometriaSnapshot != nil && len(doc.GeometriaSnapshot.Coordinates) > 0 {
		verts := make([]geo.GeoPoint, 0, len(doc.GeometriaSnapshot.Coordinates[0]))
		for _, c := range doc.GeometriaSnapshot.Coordinates[0] {
			if pt, err := geo.NewGeoPoint(c[0], c[1]); err == nil {
				verts = append(verts, pt)
			}
		}
		if poly, err := geo.NewGeoPolygon(verts); err == nil {
			geomSnap = &poly
		}
	}

	var geomBufSnap *geo.GeoPolygon
	if doc.GeometriaBufferSnapshot != nil && len(doc.GeometriaBufferSnapshot.Coordinates) > 0 {
		vertsBuf := make([]geo.GeoPoint, 0, len(doc.GeometriaBufferSnapshot.Coordinates[0]))
		for _, c := range doc.GeometriaBufferSnapshot.Coordinates[0] {
			if pt, err := geo.NewGeoPoint(c[0], c[1]); err == nil {
				vertsBuf = append(vertsBuf, pt)
			}
		}
		if polyBuf, err := geo.NewGeoPolygon(vertsBuf); err == nil {
			geomBufSnap = &polyBuf
		}
	}

	params := make(map[string]interface{}, len(doc.ParametrosCongelados))
	for k, v := range doc.ParametrosCongelados {
		params[k] = v
	}

	return academico.ReconstituirSesion(
		doc.ID.Hex(),
		doc.PeriodoID,
		doc.AsignacionID,
		doc.AsignaturaID,
		doc.GrupoID,
		doc.DocenteIDs,
		doc.EspacioID,
		doc.Fecha,
		doc.HoraInicio,
		doc.HoraFin,
		doc.InicioProgramado,
		doc.FinProgramado,
		doc.VentanaEntradaAbre,
		doc.VentanaEntradaCierra,
		doc.VentanaSalidaAbre,
		doc.VentanaSalidaCierra,
		academico.EstadoSesion(doc.Estado),
		doc.EspacioVersionGeometria,
		geomSnap,
		geomBufSnap,
		params,
		doc.MotivoCancelacion,
		doc.CreadoEn,
		doc.ActualizadoEn,
	)
}
