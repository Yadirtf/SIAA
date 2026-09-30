// Package impl — implementación del ParametroRepository sobre MongoDB.
// US-PAR-01 AC-03: guarda valor anterior en cada upsert (trazabilidad de cambios).
// ADR-07: idempotencia garantizada por índice único {ambito, ambito_id, clave}.
package impl

import (
	"context"
	"errors"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"

	"github.com/siaa/backend/internal/domain/parametro"
	"github.com/siaa/backend/internal/repository"
)

const coleccionParametros = "parametros"

// ParametroRepo implementa repository.ParametroRepository usando MongoDB.
type ParametroRepo struct {
	col *mongo.Collection
}

// NewParametroRepo crea la instancia y crea los índices necesarios.
func NewParametroRepo(db *mongo.Database) *ParametroRepo {
	col := db.Collection(coleccionParametros)
	crearIndicesParametros(col)
	return &ParametroRepo{col: col}
}

func crearIndicesParametros(col *mongo.Collection) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Índice único por (ambito, ambito_id, clave) — un solo valor por nivel+clave.
	col.Indexes().CreateOne(ctx, mongo.IndexModel{
		Keys: bson.D{
			{Key: "ambito", Value: 1},
			{Key: "ambito_id", Value: 1},
			{Key: "clave", Value: 1},
		},
		Options: options.Index().SetUnique(true),
	})
}

// Upsert inserta o actualiza un parámetro. Preserva el valor anterior (US-PAR-01 AC-03).
func (r *ParametroRepo) Upsert(ctx context.Context, p *parametro.Parametro) error {
	filter := bson.M{
		"ambito":    p.Ambito,
		"ambito_id": p.AmbitoID,
		"clave":     p.Clave,
	}

	// Recuperar el valor anterior si existe
	var existente parametro.Parametro
	err := r.col.FindOne(ctx, filter).Decode(&existente)
	if err != nil && !errors.Is(err, mongo.ErrNoDocuments) {
		return err
	}
	if err == nil {
		p.ValorAnterior = existente.Valor
	}

	now := time.Now().UTC()
	p.CreadoEn = now
	if p.VigenteDesde.IsZero() {
		p.VigenteDesde = now
	}

	update := bson.M{
		"$set": bson.M{
			"valor":          p.Valor,
			"valor_anterior": p.ValorAnterior,
			"autor_id":       p.AutorID,
			"vigente_desde":  p.VigenteDesde,
			"creado_en":      p.CreadoEn,
		},
		"$setOnInsert": bson.M{
			"ambito":    p.Ambito,
			"ambito_id": p.AmbitoID,
			"clave":     p.Clave,
		},
	}

	opts := options.Update().SetUpsert(true)
	_, err = r.col.UpdateOne(ctx, filter, update, opts)
	return err
}

// ListByAmbito lista todos los parámetros de un nivel+id específico.
func (r *ParametroRepo) ListByAmbito(ctx context.Context, ambito parametro.Ambito, ambitoID string) ([]*parametro.Parametro, error) {
	filter := bson.M{"ambito": ambito, "ambito_id": ambitoID}
	return r.findMany(ctx, filter)
}

// FindByAmbitoAndClave busca un parámetro específico.
func (r *ParametroRepo) FindByAmbitoAndClave(ctx context.Context, ambito parametro.Ambito, ambitoID string, clave parametro.Clave) (*parametro.Parametro, error) {
	var p parametro.Parametro
	filter := bson.M{"ambito": ambito, "ambito_id": ambitoID, "clave": clave}
	err := r.col.FindOne(ctx, filter).Decode(&p)
	if errors.Is(err, mongo.ErrNoDocuments) {
		return nil, nil
	}
	return &p, err
}

// ListParaCascada recupera todos los parámetros relevantes para la cascada.
func (r *ParametroRepo) ListParaCascada(ctx context.Context, filtros []repository.ParametroFilter) ([]*parametro.Parametro, error) {
	if len(filtros) == 0 {
		return nil, nil
	}

	orClauses := make(bson.A, 0, len(filtros))
	for _, f := range filtros {
		clause := bson.M{}
		if f.Ambito != nil {
			clause["ambito"] = *f.Ambito
		}
		if f.AmbitoID != nil {
			clause["ambito_id"] = *f.AmbitoID
		}
		if f.Clave != nil {
			clause["clave"] = *f.Clave
		}
		orClauses = append(orClauses, clause)
	}

	filter := bson.M{"$or": orClauses}
	return r.findMany(ctx, filter)
}

func (r *ParametroRepo) findMany(ctx context.Context, filter bson.M) ([]*parametro.Parametro, error) {
	cursor, err := r.col.Find(ctx, filter)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var results []*parametro.Parametro
	if err := cursor.All(ctx, &results); err != nil {
		return nil, err
	}
	return results, nil
}
