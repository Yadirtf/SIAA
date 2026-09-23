package impl

import (
	"context"
	"errors"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"

	domainAca "github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/repository"
	mongoConn "github.com/siaa/backend/internal/repository/mongo"
)

type calendarioExcepcionDoc struct {
	ID            primitive.ObjectID        `bson:"_id,omitempty"`
	Nombre        string                    `bson:"nombre"`
	Tipo          domainAca.TipoExcepcion   `bson:"tipo"`
	Ambito        domainAca.AmbitoExcepcion `bson:"ambito"`
	AmbitoID      string                    `bson:"ambitoId,omitempty"`
	FechaInicio   time.Time                 `bson:"fechaInicio"`
	FechaFin      time.Time                 `bson:"fechaFin"`
	Borrado       bool                      `bson:"borrado"`
	CreadoEn      time.Time                 `bson:"creadoEn"`
	ActualizadoEn time.Time                 `bson:"actualizadoEn"`
}

type calendarioExcepcionRepository struct {
	col *mongo.Collection
}

func NewCalendarioExcepcionRepository(client *mongoConn.Client) repository.CalendarioExcepcionRepository {
	return &calendarioExcepcionRepository{col: client.Collection("calendario_excepciones")}
}

func (r *calendarioExcepcionRepository) Create(ctx context.Context, e *domainAca.CalendarioExcepcion) error {
	doc := calendarioExcepcionDoc{
		Nombre:        e.Nombre(),
		Tipo:          e.Tipo(),
		Ambito:        e.Ambito(),
		AmbitoID:      e.AmbitoID(),
		FechaInicio:   e.FechaInicio(),
		FechaFin:      e.FechaFin(),
		Borrado:       false,
		CreadoEn:      e.CreadoEn(),
		ActualizadoEn: e.ActualizadoEn(),
	}
	if e.ID() != "" {
		if oid, err := primitive.ObjectIDFromHex(e.ID()); err == nil {
			doc.ID = oid
		}
	}
	_, err := r.col.InsertOne(ctx, doc)
	return err
}

func (r *calendarioExcepcionRepository) Update(ctx context.Context, e *domainAca.CalendarioExcepcion) error {
	oid, err := primitive.ObjectIDFromHex(e.ID())
	if err != nil {
		return err
	}
	update := bson.M{
		"$set": bson.M{
			"nombre":        e.Nombre(),
			"tipo":          e.Tipo(),
			"ambito":        e.Ambito(),
			"ambitoId":      e.AmbitoID(),
			"fechaInicio":   e.FechaInicio(),
			"fechaFin":      e.FechaFin(),
			"actualizadoEn": e.ActualizadoEn(),
		},
	}
	_, err = r.col.UpdateOne(ctx, bson.M{"_id": oid}, update)
	return err
}

func (r *calendarioExcepcionRepository) GetByID(ctx context.Context, id string) (*domainAca.CalendarioExcepcion, error) {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, err
	}
	var doc calendarioExcepcionDoc
	err = r.col.FindOne(ctx, bson.M{"_id": oid, "borrado": false}).Decode(&doc)
	if err != nil {
		if errors.Is(err, mongo.ErrNoDocuments) {
			return nil, nil
		}
		return nil, err
	}
	return domainAca.ReconstituirCalendarioExcepcion(
		doc.ID.Hex(),
		doc.Nombre,
		doc.Tipo,
		doc.Ambito,
		doc.AmbitoID,
		doc.FechaInicio,
		doc.FechaFin,
		doc.Borrado,
		doc.CreadoEn,
		doc.ActualizadoEn,
	), nil
}

func (r *calendarioExcepcionRepository) ListAll(ctx context.Context) ([]*domainAca.CalendarioExcepcion, error) {
	cur, err := r.col.Find(ctx, bson.M{"borrado": false}, options.Find().SetSort(bson.D{{Key: "fechaInicio", Value: 1}}))
	if err != nil {
		return nil, err
	}
	defer cur.Close(ctx)

	var list []*domainAca.CalendarioExcepcion
	for cur.Next(ctx) {
		var doc calendarioExcepcionDoc
		if err := cur.Decode(&doc); err != nil {
			return nil, err
		}
		list = append(list, domainAca.ReconstituirCalendarioExcepcion(
			doc.ID.Hex(),
			doc.Nombre,
			doc.Tipo,
			doc.Ambito,
			doc.AmbitoID,
			doc.FechaInicio,
			doc.FechaFin,
			doc.Borrado,
			doc.CreadoEn,
			doc.ActualizadoEn,
		))
	}
	return list, nil
}

func (r *calendarioExcepcionRepository) ListByRango(ctx context.Context, inicio, fin time.Time) ([]*domainAca.CalendarioExcepcion, error) {
	filter := bson.M{
		"borrado":     false,
		"fechaInicio": bson.M{"$lte": fin},
		"fechaFin":    bson.M{"$gte": inicio},
	}
	cur, err := r.col.Find(ctx, filter, options.Find().SetSort(bson.D{{Key: "fechaInicio", Value: 1}}))
	if err != nil {
		return nil, err
	}
	defer cur.Close(ctx)

	var list []*domainAca.CalendarioExcepcion
	for cur.Next(ctx) {
		var doc calendarioExcepcionDoc
		if err := cur.Decode(&doc); err != nil {
			return nil, err
		}
		list = append(list, domainAca.ReconstituirCalendarioExcepcion(
			doc.ID.Hex(),
			doc.Nombre,
			doc.Tipo,
			doc.Ambito,
			doc.AmbitoID,
			doc.FechaInicio,
			doc.FechaFin,
			doc.Borrado,
			doc.CreadoEn,
			doc.ActualizadoEn,
		))
	}
	return list, nil
}

func (r *calendarioExcepcionRepository) DeleteLogico(ctx context.Context, id string) error {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return err
	}
	_, err = r.col.UpdateOne(ctx, bson.M{"_id": oid}, bson.M{"$set": bson.M{"borrado": true, "actualizadoEn": time.Now()}})
	return err
}
