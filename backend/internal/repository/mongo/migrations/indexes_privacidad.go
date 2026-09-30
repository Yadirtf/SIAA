package migrations

import (
	"context"
	"fmt"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// CrearIndicesNotificacionesYPrivacidad crea los índices de EP-10 y EP-11.
func CrearIndicesNotificacionesYPrivacidad(ctx context.Context, db *mongo.Database) error {
	specs := []struct {
		collection string
		model      mongo.IndexModel
	}{
		// Un mismo aviso (p. ej. el cierre de una ventana para un docente) se encola una sola vez.
		{"notificaciones", mongo.IndexModel{
			Keys:    bson.D{{Key: "claveDedupe", Value: 1}},
			Options: options.Index().SetUnique(true).SetName("notificaciones_dedupe"),
		}},
		{"notificaciones", mongo.IndexModel{
			Keys:    bson.D{{Key: "estado", Value: 1}, {Key: "programadaPara", Value: 1}},
			Options: options.Index().SetName("notificaciones_cola"),
		}},
		{"notificaciones", mongo.IndexModel{
			Keys:    bson.D{{Key: "usuarioId", Value: 1}, {Key: "creadaEn", Value: -1}},
			Options: options.Index().SetName("notificaciones_bandeja"),
		}},
		{"tokens_push", mongo.IndexModel{
			Keys:    bson.D{{Key: "usuarioId", Value: 1}},
			Options: options.Index().SetName("tokens_push_usuario"),
		}},
		{"consentimientos", mongo.IndexModel{
			Keys:    bson.D{{Key: "usuarioId", Value: 1}, {Key: "decididoEn", Value: -1}},
			Options: options.Index().SetName("consentimientos_usuario"),
		}},
		// Anonimización por retención (RNF-LEG-006).
		{"marcajes", mongo.IndexModel{
			Keys:    bson.D{{Key: "timestampServidor", Value: 1}},
			Options: options.Index().SetName("marcajes_timestamp_servidor"),
		}},
		{"sesiones", mongo.IndexModel{
			Keys:    bson.D{{Key: "inicioProgramado", Value: 1}},
			Options: options.Index().SetName("sesiones_inicio"),
		}},
	}
	for _, spec := range specs {
		if _, err := db.Collection(spec.collection).Indexes().CreateOne(ctx, spec.model); err != nil && !isIndexConflict(err) {
			return fmt.Errorf("crear índice en %s: %w", spec.collection, err)
		}
	}
	return nil
}
