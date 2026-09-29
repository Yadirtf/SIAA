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
// usuariosDemo controla la creación de las cuentas de prueba con contraseñas conocidas:
// nunca deben existir en producción.
func Run(ctx context.Context, db *mongo.Database, usuariosDemo bool, admin seed.AdminInicial) error {
	if err := MigrarIdempotenciaMarcajes(ctx, db); err != nil {
		return fmt.Errorf("migrar idempotencia de marcajes: %w", err)
	}
	if err := MigrarUbicacionAlcance(ctx, db); err != nil {
		return fmt.Errorf("migrar ubicación de alcance: %w", err)
	}
	if err := CreateIndexes(ctx, db); err != nil {
		return fmt.Errorf("create indexes: %w", err)
	}
	if err := seed.Run(ctx, db, usuariosDemo, admin); err != nil {
		return fmt.Errorf("seed data: %w", err)
	}
	return nil
}
