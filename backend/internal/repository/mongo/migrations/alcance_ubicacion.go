// Package migrations — sede y facultad en sesiones y marcajes para el alcance ABAC (RF-ROL-003).
package migrations

import (
	"context"
	"fmt"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

// MigrarUbicacionAlcance completa sedeId y facultadId en las sesiones y marcajes creados
// antes de que se guardaran, para que los filtros por ámbito los incluyan. Es idempotente:
// solo toca documentos a los que les falta el campo.
func MigrarUbicacionAlcance(ctx context.Context, db *mongo.Database) error {
	if err := completarSesiones(ctx, db); err != nil {
		return fmt.Errorf("sesiones: %w", err)
	}
	if err := completarMarcajes(ctx, db); err != nil {
		return fmt.Errorf("marcajes: %w", err)
	}
	return nil
}

func completarSesiones(ctx context.Context, db *mongo.Database) error {
	cur, err := db.Collection("sesiones").Find(ctx, bson.M{"facultadId": bson.M{"$exists": false}})
	if err != nil {
		return err
	}
	defer cur.Close(ctx)
	for cur.Next(ctx) {
		var s struct {
			ID           primitive.ObjectID `bson:"_id"`
			AsignacionID string             `bson:"asignacionId"`
			EspacioID    string             `bson:"espacioId"`
			PeriodoID    string             `bson:"periodoId"`
		}
		if err := cur.Decode(&s); err != nil {
			continue
		}
		facultad := campoPorID(ctx, db, "asignaciones", s.AsignacionID, "facultadId")
		sede := campoPorID(ctx, db, "espacios", s.EspacioID, "sedeId")
		if sede == "" {
			sede = campoPorID(ctx, db, "periodos", s.PeriodoID, "sedeId")
		}
		if _, err := db.Collection("sesiones").UpdateByID(ctx, s.ID, bson.M{"$set": bson.M{"facultadId": facultad, "sedeId": sede}}); err != nil {
			return err
		}
	}
	return cur.Err()
}

func completarMarcajes(ctx context.Context, db *mongo.Database) error {
	cur, err := db.Collection("marcajes").Find(ctx, bson.M{"facultadId": bson.M{"$exists": false}})
	if err != nil {
		return err
	}
	defer cur.Close(ctx)
	for cur.Next(ctx) {
		var m struct {
			ID       interface{} `bson:"_id"`
			SesionID string      `bson:"sesionId"`
		}
		if err := cur.Decode(&m); err != nil {
			continue
		}
		set := bson.M{
			"facultadId": campoPorID(ctx, db, "sesiones", m.SesionID, "facultadId"),
			"sedeId":     campoPorID(ctx, db, "sesiones", m.SesionID, "sedeId"),
		}
		if _, err := db.Collection("marcajes").UpdateOne(ctx, bson.M{"_id": m.ID}, bson.M{"$set": set}); err != nil {
			return err
		}
	}
	return cur.Err()
}

// campoPorID lee un campo de texto de un documento identificado por un ObjectID en hexadecimal.
func campoPorID(ctx context.Context, db *mongo.Database, coleccion, id, campo string) string {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return ""
	}
	var doc bson.M
	if err := db.Collection(coleccion).FindOne(ctx, bson.M{"_id": oid}).Decode(&doc); err != nil {
		return ""
	}
	v, _ := doc[campo].(string)
	return v
}
