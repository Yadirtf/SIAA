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

type facultadDoc struct {
	ID            primitive.ObjectID `bson:"_id,omitempty"`
	Codigo        string             `bson:"codigo"`
	Nombre        string             `bson:"nombre"`
	SedeID        string             `bson:"sedeId,omitempty"`
	CodigoExterno *string            `bson:"codigoExterno,omitempty"`
	Borrado       bool               `bson:"borrado"`
	CreadoEn      time.Time          `bson:"creadoEn"`
	ActualizadoEn time.Time          `bson:"actualizadoEn"`
}

type estructuraRepository struct {
	colFacultades  *mongo.Collection
	colProgramas   *mongo.Collection
	colAsignaturas *mongo.Collection
	colGrupos      *mongo.Collection
}

func NewEstructuraRepository(client *mongoConn.Client) repository.EstructuraRepository {
	return &estructuraRepository{
		colFacultades:  client.Collection("facultades"),
		colProgramas:   client.Collection("programas"),
		colAsignaturas: client.Collection("asignaturas"),
		colGrupos:      client.Collection("grupos"),
	}
}

// ─────────────────────────────────────────────────────────────
// Facultades (US-ACA-01 AC-04)
// ─────────────────────────────────────────────────────────────

func (r *estructuraRepository) CreateFacultad(ctx context.Context, f *domainAca.Facultad) error {
	doc := facultadDoc{
		Codigo:        f.Codigo(),
		Nombre:        f.Nombre(),
		SedeID:        f.SedeID(),
		CodigoExterno: f.CodigoExterno(),
		Borrado:       false,
		CreadoEn:      f.CreadoEn(),
		ActualizadoEn: f.ActualizadoEn(),
	}
	if f.ID() != "" {
		if oid, err := primitive.ObjectIDFromHex(f.ID()); err == nil {
			doc.ID = oid
		}
	}
	_, err := r.colFacultades.InsertOne(ctx, doc)
	return err
}

func (r *estructuraRepository) UpdateFacultad(ctx context.Context, f *domainAca.Facultad) error {
	oid, err := primitive.ObjectIDFromHex(f.ID())
	if err != nil {
		return err
	}
	_, err = r.colFacultades.UpdateOne(ctx, bson.M{"_id": oid}, bson.M{"$set": bson.M{
		"codigo":        f.Codigo(),
		"nombre":        f.Nombre(),
		"sedeId":        f.SedeID(),
		"codigoExterno": f.CodigoExterno(),
		"actualizadoEn": f.ActualizadoEn(),
	}})
	return err
}

func (r *estructuraRepository) GetFacultadByID(ctx context.Context, id string) (*domainAca.Facultad, error) {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, err
	}
	var doc facultadDoc
	err = r.colFacultades.FindOne(ctx, bson.M{"_id": oid, "borrado": false}).Decode(&doc)
	if err != nil {
		if errors.Is(err, mongo.ErrNoDocuments) {
			return nil, nil
		}
		return nil, err
	}
	return domainAca.ReconstituirFacultad(doc.ID.Hex(), doc.Codigo, doc.Nombre, doc.SedeID, doc.CodigoExterno, doc.Borrado, doc.CreadoEn, doc.ActualizadoEn), nil
}

func (r *estructuraRepository) ListFacultades(ctx context.Context, sedeID string) ([]*domainAca.Facultad, error) {
	filter := bson.M{"borrado": false}
	if sedeID != "" {
		filter["sedeId"] = sedeID
	}
	cur, err := r.colFacultades.Find(ctx, filter, options.Find().SetSort(bson.D{{Key: "nombre", Value: 1}}))
	if err != nil {
		return nil, err
	}
	defer cur.Close(ctx)

	var list []*domainAca.Facultad
	for cur.Next(ctx) {
		var doc facultadDoc
		if err := cur.Decode(&doc); err != nil {
			return nil, err
		}
		list = append(list, domainAca.ReconstituirFacultad(doc.ID.Hex(), doc.Codigo, doc.Nombre, doc.SedeID, doc.CodigoExterno, doc.Borrado, doc.CreadoEn, doc.ActualizadoEn))
	}
	return list, nil
}

func (r *estructuraRepository) DeleteFacultadLogico(ctx context.Context, id string) error {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return err
	}
	_, err = r.colFacultades.UpdateOne(ctx, bson.M{"_id": oid}, bson.M{"$set": bson.M{"borrado": true, "actualizadoEn": time.Now()}})
	return err
}
