package impl

import (
	"context"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// EliminarLogico marca sesiones como eliminadas; se usa al reemplazar las sesiones futuras de
// una asignación editada, para que no cuenten como faltas ni aparezcan en los listados.
func (r *sesionRepository) EliminarLogico(ctx context.Context, ids []string) (int64, error) {
	oids := make([]primitive.ObjectID, 0, len(ids))
	for _, id := range ids {
		if oid, err := primitive.ObjectIDFromHex(id); err == nil {
			oids = append(oids, oid)
		}
	}
	if len(oids) == 0 {
		return 0, nil
	}
	res, err := r.col.UpdateMany(ctx, bson.M{"_id": bson.M{"$in": oids}}, bson.M{"$set": bson.M{
		"eliminado": true, "actualizadoEn": time.Now().UTC(),
	}})
	if err != nil {
		return 0, fmt.Errorf("eliminar sesiones: %w", err)
	}
	return res.ModifiedCount, nil
}
