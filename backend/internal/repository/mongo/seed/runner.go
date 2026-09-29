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
// Las cuentas de demostración (contraseñas conocidas) solo se crean si usuariosDemo es true;
// en producción únicamente se crea el administrador inicial configurado por entorno.
func Run(ctx context.Context, db *mongo.Database, usuariosDemo bool, admin AdminInicial) error {
	if err := seedRoles(ctx, db); err != nil {
		return fmt.Errorf("seed roles: %w", err)
	}
	if err := seedGlobalParams(ctx, db); err != nil {
		return fmt.Errorf("seed params: %w", err)
	}
	if usuariosDemo {
		if err := seedUsers(ctx, db); err != nil {
			return fmt.Errorf("seed users: %w", err)
		}
	}
	if err := seedAdminInicial(ctx, db, admin); err != nil {
		return fmt.Errorf("seed admin inicial: %w", err)
	}
	return nil
}
