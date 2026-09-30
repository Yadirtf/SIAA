// Package migrations — migración del índice de idempotencia de marcajes (ADR-07).
package migrations

import (
	"context"
	"fmt"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
)

const (
	indiceIdempotenciaMarcajes       = "marcajes_sesion_usuario_tipo_consolidado_unique"
	indiceIdempotenciaMarcajesLegado = "marcajes_sesion_usuario_tipo_unique"
)

// resultadosConsolidados son los resultados que ocupan la ranura única (sesión, usuario, tipo).
var resultadosConsolidados = []string{"PRESENTE", "TARDANZA", "VALIDO", "RETARDO", "AUSENTE"}

// MigrarIdempotenciaMarcajes marca como consolidados los marcajes existentes y elimina
// el índice único anterior, que incluía los rechazos: con él, un primer intento
// rechazado (p. ej. desde el pasillo) impedía registrar el marcaje válido posterior.
// Es idempotente: puede ejecutarse en cada arranque.
func MigrarIdempotenciaMarcajes(ctx context.Context, db *mongo.Database) error {
	col := db.Collection("marcajes")

	sinCampo := bson.M{"consolidado": bson.M{"$exists": false}}
	if _, err := col.UpdateMany(ctx,
		bson.M{"$and": []bson.M{sinCampo, {"anulado": false}, {"resultado": bson.M{"$in": resultadosConsolidados}}}},
		bson.M{"$set": bson.M{"consolidado": true}},
	); err != nil {
		return fmt.Errorf("marcar consolidados: %w", err)
	}
	if _, err := col.UpdateMany(ctx, sinCampo, bson.M{"$set": bson.M{"consolidado": false}}); err != nil {
		return fmt.Errorf("marcar no consolidados: %w", err)
	}

	cur, err := col.Indexes().List(ctx)
	if err != nil {
		return fmt.Errorf("listar índices: %w", err)
	}
	defer cur.Close(ctx)
	for cur.Next(ctx) {
		var idx struct {
			Name string `bson:"name"`
		}
		if err := cur.Decode(&idx); err == nil && idx.Name == indiceIdempotenciaMarcajesLegado {
			if _, err := col.Indexes().DropOne(ctx, indiceIdempotenciaMarcajesLegado); err != nil {
				return fmt.Errorf("eliminar índice legado: %w", err)
			}
		}
	}
	return nil
}
