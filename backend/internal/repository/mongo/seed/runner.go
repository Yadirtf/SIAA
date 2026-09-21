// Package seed orquesta la inserción de datos iniciales del sistema.
// T-PLT-01.7: roles predefinidos, parámetros globales y usuarios de prueba.
// Todas las operaciones son idempotentes (upsert con $setOnInsert).
package seed

import (
	"context"
	"fmt"

	"go.mongodb.org/mongo-driver/mongo"
)

// Run ejecuta todas las semillas en orden.
// Es idempotente: puede llamarse en cada arranque del servidor sin efectos secundarios.
func Run(ctx context.Context, db *mongo.Database) error {
	if err := seedRoles(ctx, db); err != nil {
		return fmt.Errorf("seed roles: %w", err)
	}
	if err := seedGlobalParams(ctx, db); err != nil {
		return fmt.Errorf("seed params: %w", err)
	}
	if err := seedUsers(ctx, db); err != nil {
		return fmt.Errorf("seed users: %w", err)
	}
	return nil
}
