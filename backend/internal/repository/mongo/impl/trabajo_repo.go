package impl

import (
	"context"
	"errors"
	"fmt"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"

	"github.com/siaa/backend/internal/repository"
	mongoConn "github.com/siaa/backend/internal/repository/mongo"
)

type trabajoRepo struct {
	col *mongo.Collection
}

// NewTrabajoRepository crea el repositorio de la colección trabajos.
func NewTrabajoRepository(client *mongoConn.Client) repository.TrabajoRepository {
	return &trabajoRepo{col: client.Collection("trabajos")}
}

func (r *trabajoRepo) Crear(ctx context.Context, t *repository.Trabajo) error {
	if _, err := r.col.InsertOne(ctx, t); err != nil {
		return fmt.Errorf("crear trabajo: %w", err)
	}
	return nil
}

func (r *trabajoRepo) Actualizar(ctx context.Context, t *repository.Trabajo) error {
	if _, err := r.col.ReplaceOne(ctx, bson.M{"_id": t.ID}, t); err != nil {
		return fmt.Errorf("actualizar trabajo: %w", err)
	}
	return nil
}

func (r *trabajoRepo) Obtener(ctx context.Context, id string) (*repository.Trabajo, error) {
	// El resultado se lee como documento (bson.M) para que se serialice como objeto JSON.
	var crudo struct {
		repository.Trabajo `bson:",inline"`
		Resultado          bson.M `bson:"resultado,omitempty"`
	}
	err := r.col.FindOne(ctx, bson.M{"_id": id}).Decode(&crudo)
	if errors.Is(err, mongo.ErrNoDocuments) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("obtener trabajo: %w", err)
	}
	t := crudo.Trabajo
	if crudo.Resultado != nil {
		t.Resultado = crudo.Resultado
	}
	return &t, nil
}
