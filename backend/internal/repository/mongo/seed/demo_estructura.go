// Package seed — estructura mínima de demostración para el coordinador semilla (US-ROL-02).
// Un coordinador sin ámbitos no ve nada (mínimo privilegio); para que la cuenta de demostración
// sea útil se le asigna la facultad de demostración, dentro de su sede.
package seed

import (
	"context"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"

	"github.com/siaa/backend/internal/domain/rbac"
)

const (
	codigoSedeDemo     = "DEMO"
	codigoFacultadDemo = "DEMO-ING"
	correoCoordDemo    = "coordinador@siaa.edu.co"
)

// seedEstructuraDemo crea (si no existen) la sede y la facultad de demostración y asigna la
// facultad al coordinador semilla cuando aún no tiene ámbitos.
func seedEstructuraDemo(ctx context.Context, db *mongo.Database) error {
	ahora := time.Now().UTC()
	sedeID, err := upsertPorCodigo(ctx, db.Collection("sedes"), bson.M{"codigo": codigoSedeDemo}, bson.M{
		"codigo": codigoSedeDemo, "nombre": "Sede de demostración", "direccion": "",
		"activo": true, "eliminado": false, "creadoEn": ahora, "actualizadoEn": ahora,
	})
	if err != nil {
		return fmt.Errorf("sede de demostración: %w", err)
	}
	facultadID, err := upsertPorCodigo(ctx, db.Collection("facultades"), bson.M{"codigo": codigoFacultadDemo, "sedeId": sedeID}, bson.M{
		"codigo": codigoFacultadDemo, "nombre": "Facultad de demostración", "sedeId": sedeID,
		"borrado": false, "creadoEn": ahora, "actualizadoEn": ahora,
	})
	if err != nil {
		return fmt.Errorf("facultad de demostración: %w", err)
	}
	_, err = db.Collection("usuarios").UpdateOne(ctx,
		bson.M{"correo": correoCoordDemo, "$or": bson.A{
			bson.M{"ambitos": bson.M{"$exists": false}}, bson.M{"ambitos": bson.M{"$size": 0}}, bson.M{"ambitos": nil},
		}},
		bson.M{"$set": bson.M{"ambitos": []bson.M{{"tipo": string(rbac.ScopeFacultad), "id": facultadID}}}})
	if err != nil {
		return fmt.Errorf("ámbito del coordinador semilla: %w", err)
	}
	return nil
}

// upsertPorCodigo inserta el documento si no existe y devuelve su identificador hexadecimal.
func upsertPorCodigo(ctx context.Context, col *mongo.Collection, filtro, doc bson.M) (string, error) {
	if _, err := col.UpdateOne(ctx, filtro, bson.M{"$setOnInsert": doc}, options.Update().SetUpsert(true)); err != nil {
		return "", err
	}
	var res struct {
		ID primitive.ObjectID `bson:"_id"`
	}
	if err := col.FindOne(ctx, filtro).Decode(&res); err != nil {
		return "", err
	}
	return res.ID.Hex(), nil
}
