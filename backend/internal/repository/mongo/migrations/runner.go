// Package migrations orquesta la ejecución de migraciones de base de datos.
// T-PLT-01.7: índices + semillas de datos iniciales.
package migrations

import (
	"context"
	"fmt"

	"go.mongodb.org/mongo-driver/mongo"

	"github.com/siaa/backend/internal/repository/mongo/seed"
)

// Run ejecuta todas las migraciones en orden: índices primero, luego semillas.
// Es idempotente: puede ejecutarse en cada arranque del servidor.
func Run(ctx context.Context, db *mongo.Database) error {
	if err := CreateIndexes(ctx, db); err != nil {
		return fmt.Errorf("create indexes: %w", err)
	}
	if err := seed.Run(ctx, db); err != nil {
		return fmt.Errorf("seed data: %w", err)
	}
	return nil
}
