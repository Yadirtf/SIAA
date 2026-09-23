// Package impl — repositorio MongoDB para Sedes universitarias (US-GEO-01).
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

type sedeDoc struct {
	ID            primitive.ObjectID `bson:"_id,omitempty"`
	Codigo        string             `bson:"codigo"`
	Nombre        string             `bson:"nombre"`
	Direccion     string             `bson:"direccion"`
	Activo        bool               `bson:"activo"`
	Eliminado     bool               `bson:"eliminado"`
	CreadoEn      time.Time          `bson:"creadoEn"`
	ActualizadoEn time.Time          `bson:"actualizadoEn"`
}

type sedeRepository struct {
	col *mongo.Collection
}

func NewSedeRepository(client *mongoConn.Client) repository.SedeRepository {
	return &sedeRepository{col: client.Collection("sedes")}
}

func (r *sedeRepository) Create(ctx context.Context, s *geo.Sede) error {
	doc := sedeDoc{
		Codigo:        s.Codigo,
		Nombre:        s.Nombre,
		Direccion:     s.Direccion,
		Activo:        s.Activo,
		Eliminado:     false,
		CreadoEn:      s.CreadoEn,
		ActualizadoEn: s.ActualizadoEn,
	}
	if s.ID != "" {
		if oid, err := primitive.ObjectIDFromHex(s.ID); err == nil {
			doc.ID = oid
		}
	}
	res, err := r.col.InsertOne(ctx, doc)
	if err != nil {
		return fmt.Errorf("create sede: %w", err)
	}
	if oid, ok := res.InsertedID.(primitive.ObjectID); ok {
		s.ID = oid.Hex()
	}
	return nil
}

func (r *sedeRepository) FindByID(ctx context.Context, id string) (*geo.Sede, error) {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, nil
	}
	var doc sedeDoc
	err = r.col.FindOne(ctx, bson.D{
		{Key: "_id", Value: oid},
		{Key: "eliminado", Value: false},
	}).Decode(&doc)
	if errors.Is(err, mongo.ErrNoDocuments) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("findSedeByID: %w", err)
	}
	return &geo.Sede{
		ID:            doc.ID.Hex(),
		Codigo:        doc.Codigo,
		Nombre:        doc.Nombre,
		Direccion:     doc.Direccion,
		Activo:        doc.Activo,
		Eliminado:     doc.Eliminado,
		CreadoEn:      doc.CreadoEn,
		ActualizadoEn: doc.ActualizadoEn,
	}, nil
}

func (r *sedeRepository) FindByCodigo(ctx context.Context, codigo string) (*geo.Sede, error) {
	var doc sedeDoc
	err := r.col.FindOne(ctx, bson.D{
		{Key: "codigo", Value: codigo},
		{Key: "eliminado", Value: false},
	}).Decode(&doc)
	if errors.Is(err, mongo.ErrNoDocuments) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("findSedeByCodigo: %w", err)
	}
	return &geo.Sede{
		ID:            doc.ID.Hex(),
		Codigo:        doc.Codigo,
		Nombre:        doc.Nombre,
		Direccion:     doc.Direccion,
		Activo:        doc.Activo,
		Eliminado:     doc.Eliminado,
		CreadoEn:      doc.CreadoEn,
		ActualizadoEn: doc.ActualizadoEn,
	}, nil
}

func (r *sedeRepository) List(ctx context.Context) ([]*geo.Sede, error) {
	cursor, err := r.col.Find(ctx, bson.D{{Key: "eliminado", Value: false}})
	if err != nil {
		return nil, fmt.Errorf("listSedes: %w", err)
	}
	defer cursor.Close(ctx)

	var sedes []*geo.Sede
	for cursor.Next(ctx) {
		var doc sedeDoc
		if err := cursor.Decode(&doc); err != nil {
			return nil, fmt.Errorf("decode sede: %w", err)
		}
		sedes = append(sedes, &geo.Sede{
			ID:            doc.ID.Hex(),
			Codigo:        doc.Codigo,
			Nombre:        doc.Nombre,
			Direccion:     doc.Direccion,
			Activo:        doc.Activo,
			Eliminado:     doc.Eliminado,
			CreadoEn:      doc.CreadoEn,
			ActualizadoEn: doc.ActualizadoEn,
		})
	}
	return sedes, nil
}

func (r *sedeRepository) Update(ctx context.Context, s *geo.Sede) error {
	oid, err := primitive.ObjectIDFromHex(s.ID)
	if err != nil {
		return fmt.Errorf("invalid sede ID: %w", err)
	}
	update := bson.D{{Key: "$set", Value: bson.D{
		{Key: "codigo", Value: s.Codigo},
		{Key: "nombre", Value: s.Nombre},
		{Key: "direccion", Value: s.Direccion},
		{Key: "activo", Value: s.Activo},
		{Key: "actualizadoEn", Value: time.Now().UTC()},
	}}}
	_, err = r.col.UpdateByID(ctx, oid, update)
	return err
}

func (r *sedeRepository) SoftDelete(ctx context.Context, id string) error {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return fmt.Errorf("invalid sede ID: %w", err)
	}
	update := bson.D{{Key: "$set", Value: bson.D{
		{Key: "eliminado", Value: true},
		{Key: "activo", Value: false},
		{Key: "actualizadoEn", Value: time.Now().UTC()},
	}}}
	_, err = r.col.UpdateByID(ctx, oid, update)
	return err
}
