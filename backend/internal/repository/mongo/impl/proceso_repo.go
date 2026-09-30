package impl

import (
	"context"
	"errors"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"

	"github.com/siaa/backend/internal/repository"
	mongoConn "github.com/siaa/backend/internal/repository/mongo"
)

type procesoRepo struct {
	col *mongo.Collection
}

// NewProcesoRepository crea el repositorio de marcas de agua de procesos periódicos.
func NewProcesoRepository(client *mongoConn.Client) repository.ProcesoRepository {
	return &procesoRepo{col: client.Collection("procesos")}
}

func (r *procesoRepo) ObtenerMarca(ctx context.Context, proceso string) (*time.Time, error) {
	var doc struct {
		Hasta time.Time `bson:"hasta"`
	}
	if err := r.col.FindOne(ctx, bson.M{"_id": proceso}).Decode(&doc); err != nil {
		if errors.Is(err, mongo.ErrNoDocuments) {
			return nil, nil
		}
		return nil, fmt.Errorf("leer marca de %s: %w", proceso, err)
	}
	return &doc.Hasta, nil
}

func (r *procesoRepo) GuardarMarca(ctx context.Context, proceso string, hasta time.Time) error {
	_, err := r.col.UpdateOne(ctx, bson.M{"_id": proceso},
		bson.M{"$set": bson.M{"hasta": hasta, "actualizadoEn": time.Now().UTC()}},
		options.Update().SetUpsert(true))
	if err != nil {
		return fmt.Errorf("guardar marca de %s: %w", proceso, err)
	}
	return nil
}
