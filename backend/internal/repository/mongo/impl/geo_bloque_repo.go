// Package impl — repositorio MongoDB para Bloques de edificios (US-GEO-01).
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

type bloqueDoc struct {
	ID            primitive.ObjectID `bson:"_id,omitempty"`
	SedeID        string             `bson:"sedeId"`
	Codigo        string             `bson:"codigo"`
	Nombre        string             `bson:"nombre"`
	Pisos         []int              `bson:"pisos"`
	Activo        bool               `bson:"activo"`
	Eliminado     bool               `bson:"eliminado"`
	CreadoEn      time.Time          `bson:"creadoEn"`
	ActualizadoEn time.Time          `bson:"actualizadoEn"`
}

type bloqueRepository struct {
	col *mongo.Collection
}

func NewBloqueRepository(client *mongoConn.Client) repository.BloqueRepository {
	return &bloqueRepository{col: client.Collection("bloques")}
}

func (r *bloqueRepository) Create(ctx context.Context, b *geo.Bloque) error {
	doc := bloqueDoc{
		SedeID:        b.SedeID,
		Codigo:        b.Codigo,
		Nombre:        b.Nombre,
		Pisos:         b.Pisos,
		Activo:        b.Activo,
		Eliminado:     false,
		CreadoEn:      b.CreadoEn,
		ActualizadoEn: b.ActualizadoEn,
	}
	if b.ID != "" {
		if oid, err := primitive.ObjectIDFromHex(b.ID); err == nil {
			doc.ID = oid
		}
	}
	res, err := r.col.InsertOne(ctx, doc)
	if err != nil {
		return fmt.Errorf("create bloque: %w", err)
	}
	if oid, ok := res.InsertedID.(primitive.ObjectID); ok {
		b.ID = oid.Hex()
	}
	return nil
}

func (r *bloqueRepository) FindByID(ctx context.Context, id string) (*geo.Bloque, error) {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, nil
	}
	var doc bloqueDoc
	err = r.col.FindOne(ctx, bson.D{
		{Key: "_id", Value: oid},
		{Key: "eliminado", Value: false},
	}).Decode(&doc)
	if errors.Is(err, mongo.ErrNoDocuments) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("findBloqueByID: %w", err)
	}
	return &geo.Bloque{
		ID:            doc.ID.Hex(),
		SedeID:        doc.SedeID,
		Codigo:        doc.Codigo,
		Nombre:        doc.Nombre,
		Pisos:         doc.Pisos,
		Activo:        doc.Activo,
		Eliminado:     doc.Eliminado,
		CreadoEn:      doc.CreadoEn,
		ActualizadoEn: doc.ActualizadoEn,
	}, nil
}

func (r *bloqueRepository) FindByCodigo(ctx context.Context, sedeID, codigo string) (*geo.Bloque, error) {
	var doc bloqueDoc
	err := r.col.FindOne(ctx, bson.D{
		{Key: "sedeId", Value: sedeID},
		{Key: "codigo", Value: codigo},
		{Key: "eliminado", Value: false},
	}).Decode(&doc)
	if errors.Is(err, mongo.ErrNoDocuments) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("findBloqueByCodigo: %w", err)
	}
	return &geo.Bloque{
		ID:            doc.ID.Hex(),
		SedeID:        doc.SedeID,
		Codigo:        doc.Codigo,
		Nombre:        doc.Nombre,
		Pisos:         doc.Pisos,
		Activo:        doc.Activo,
		Eliminado:     doc.Eliminado,
		CreadoEn:      doc.CreadoEn,
		ActualizadoEn: doc.ActualizadoEn,
	}, nil
}

func (r *bloqueRepository) FindBySede(ctx context.Context, sedeID string) ([]*geo.Bloque, error) {
	cursor, err := r.col.Find(ctx, bson.D{
		{Key: "sedeId", Value: sedeID},
		{Key: "eliminado", Value: false},
	})
	if err != nil {
		return nil, fmt.Errorf("findBloquesBySede: %w", err)
	}
	defer cursor.Close(ctx)

	var bloques []*geo.Bloque
	for cursor.Next(ctx) {
		var doc bloqueDoc
		if err := cursor.Decode(&doc); err != nil {
			return nil, fmt.Errorf("decode bloque: %w", err)
		}
		bloques = append(bloques, &geo.Bloque{
			ID:            doc.ID.Hex(),
			SedeID:        doc.SedeID,
			Codigo:        doc.Codigo,
			Nombre:        doc.Nombre,
			Pisos:         doc.Pisos,
			Activo:        doc.Activo,
			Eliminado:     doc.Eliminado,
			CreadoEn:      doc.CreadoEn,
			ActualizadoEn: doc.ActualizadoEn,
		})
	}
	return bloques, nil
}

func (r *bloqueRepository) List(ctx context.Context) ([]*geo.Bloque, error) {
	cursor, err := r.col.Find(ctx, bson.D{{Key: "eliminado", Value: false}})
	if err != nil {
		return nil, fmt.Errorf("listBloques: %w", err)
	}
	defer cursor.Close(ctx)

	var bloques []*geo.Bloque
	for cursor.Next(ctx) {
		var doc bloqueDoc
		if err := cursor.Decode(&doc); err != nil {
			return nil, fmt.Errorf("decode bloque: %w", err)
		}
		bloques = append(bloques, &geo.Bloque{
			ID:            doc.ID.Hex(),
			SedeID:        doc.SedeID,
			Codigo:        doc.Codigo,
			Nombre:        doc.Nombre,
			Pisos:         doc.Pisos,
			Activo:        doc.Activo,
			Eliminado:     doc.Eliminado,
			CreadoEn:      doc.CreadoEn,
			ActualizadoEn: doc.ActualizadoEn,
		})
	}
	return bloques, nil
}

func (r *bloqueRepository) Update(ctx context.Context, b *geo.Bloque) error {
	oid, err := primitive.ObjectIDFromHex(b.ID)
	if err != nil {
		return fmt.Errorf("invalid bloque ID: %w", err)
	}
	update := bson.D{{Key: "$set", Value: bson.D{
		{Key: "codigo", Value: b.Codigo},
		{Key: "nombre", Value: b.Nombre},
		{Key: "pisos", Value: b.Pisos},
		{Key: "activo", Value: b.Activo},
		{Key: "actualizadoEn", Value: time.Now().UTC()},
	}}}
	_, err = r.col.UpdateByID(ctx, oid, update)
	return err
}

func (r *bloqueRepository) SoftDelete(ctx context.Context, id string) error {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return fmt.Errorf("invalid bloque ID: %w", err)
	}
	update := bson.D{{Key: "$set", Value: bson.D{
		{Key: "eliminado", Value: true},
		{Key: "activo", Value: false},
		{Key: "actualizadoEn", Value: time.Now().UTC()},
	}}}
	_, err = r.col.UpdateByID(ctx, oid, update)
	return err
}
