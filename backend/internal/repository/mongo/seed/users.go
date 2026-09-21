// Package seed — usuarios iniciales para desarrollo y CI.
// Usa el paquete crypto compartido para evitar duplicación de hashArgon2id.
package seed

import (
	"context"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"

	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/usecase/auth/crypto"
)

// seedUsers inserta usuarios iniciales para pruebas y desarrollo.
// Los usuarios solo se crean si no existen ($setOnInsert).
func seedUsers(ctx context.Context, db *mongo.Database) error {
	col := db.Collection("usuarios")
	now := time.Now().UTC()

	users := []struct {
		correo   string
		password string
		nombre   string
		apellido string
		rol      rbac.RoleName
	}{
		{
			correo:   "admin@siaa.edu.co",
			password: "Admin12345678*",
			nombre:   "Super",
			apellido: "Administrador",
			rol:      rbac.RolSuperadmin,
		},
		{
			correo:   "docente@siaa.edu.co",
			password: "Docente123456*",
			nombre:   "Carlos",
			apellido: "Pérez",
			rol:      rbac.RolDocente,
		},
		{
			correo:   "coordinador@siaa.edu.co",
			password: "Coord12345678*",
			nombre:   "Ana",
			apellido: "Gómez",
			rol:      rbac.RolCoordinador,
		},
	}

	upsertOpts := options.Update().SetUpsert(true)
	for _, u := range users {
		// Reutiliza crypto compartido — elimina duplicación de hashPasswordArgon2id
		hash, err := crypto.HashArgon2id(u.password)
		if err != nil {
			return fmt.Errorf("hash password: %w", err)
		}

		filter := bson.D{{Key: "correo", Value: u.correo}}
		update := bson.D{{Key: "$setOnInsert", Value: bson.M{
			"correo":       u.correo,
			"passwordHash": hash,
			"nombre":       u.nombre,
			"apellido":     u.apellido,
			"activo":       true,
			"eliminado":    false,
			"roles": []bson.M{{
				"rolId":  string(u.rol),
				"nombre": string(u.rol),
			}},
			"ambitos":          []bson.M{},
			"intentosFallidos": 0,
			"creadoEn":         now,
			"actualizadoEn":    now,
		}}}

		if _, err := col.UpdateOne(ctx, filter, update, upsertOpts); err != nil {
			return fmt.Errorf("upsert user %s: %w", u.correo, err)
		}
	}

	return nil
}
