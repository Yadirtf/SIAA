// Package impl — registro de ajustes de marcaje como eventos nuevos (US-MAR-09, RF-JUS-004).
package impl

import (
	"context"
	"errors"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"

	"github.com/siaa/backend/internal/domain/marcaje"
	"github.com/siaa/backend/internal/repository"
)

// RegistrarAjuste libera la ranura del original, apuntándolo al ajuste, e inserta el
// evento nuevo. Si la inserción falla, el original recupera su estado previo.
func (r *marcajeMongoRepo) RegistrarAjuste(ctx context.Context, originalID string, ajuste *marcaje.Marcaje) error {
	if ajuste.ID == "" {
		ajuste.ID = primitive.NewObjectID().Hex()
	}
	if ajuste.CreadoEn.IsZero() {
		ajuste.CreadoEn = time.Now().UTC()
	}
	ajuste.AjusteDe = originalID
	ajuste.Consolidado = !ajuste.Anulado && ajuste.ConsolidaSesion()

	var original marcaje.Marcaje
	filtro := bson.M{"_id": originalID, "reemplazadoPor": bson.M{"$exists": false}}
	if err := r.col.FindOne(ctx, filtro).Decode(&original); err != nil {
		if errors.Is(err, mongo.ErrNoDocuments) {
			return repository.ErrMarcajeYaAjustado
		}
		return fmt.Errorf("buscar marcaje a ajustar: %w", err)
	}

	res, err := r.col.UpdateOne(ctx, filtro, bson.M{"$set": bson.M{
		"reemplazadoPor": ajuste.ID,
		"consolidado":    false,
	}})
	if err != nil {
		return fmt.Errorf("marcar marcaje reemplazado: %w", err)
	}
	if res.MatchedCount == 0 {
		return repository.ErrMarcajeYaAjustado
	}

	if _, err := r.col.InsertOne(ctx, ajuste); err != nil {
		// Restituir el original para no dejar la sesión sin su registro vigente.
		_, _ = r.col.UpdateOne(ctx, bson.M{"_id": originalID}, bson.M{
			"$set":   bson.M{"consolidado": original.Consolidado},
			"$unset": bson.M{"reemplazadoPor": ""},
		})
		if mongo.IsDuplicateKeyError(err) {
			return repository.ErrRanuraOcupada
		}
		return fmt.Errorf("insertar ajuste de marcaje: %w", err)
	}
	return nil
}
