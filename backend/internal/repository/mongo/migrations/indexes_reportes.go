package migrations

import (
	"context"
	"fmt"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// CrearIndicesJustificacionesYAuditoria crea los índices de EP-07, EP-08 y RF-AUD-003.
func CrearIndicesJustificacionesYAuditoria(ctx context.Context, db *mongo.Database) error {
	vigentes := bson.M{"estado": bson.M{"$in": []string{"RADICADA", "EN_REVISION", "APROBADA"}}}
	specs := []struct {
		collection string
		model      mongo.IndexModel
	}{
		// Una sola justificación en curso o aprobada por sesión y docente.
		{"justificaciones", mongo.IndexModel{
			Keys:    bson.D{{Key: "sesionId", Value: 1}, {Key: "docenteId", Value: 1}},
			Options: options.Index().SetUnique(true).SetPartialFilterExpression(vigentes).SetName("justificaciones_vigente_unica"),
		}},
		{"justificaciones", mongo.IndexModel{
			Keys:    bson.D{{Key: "estado", Value: 1}, {Key: "creadoEn", Value: -1}},
			Options: options.Index().SetName("justificaciones_bandeja"),
		}},
		{"justificaciones", mongo.IndexModel{
			Keys:    bson.D{{Key: "docenteId", Value: 1}, {Key: "creadoEn", Value: -1}},
			Options: options.Index().SetName("justificaciones_docente"),
		}},
		// Consulta de la bitácora por fecha y por acción (RF-AUD-003).
		{"auditoria", mongo.IndexModel{
			Keys:    bson.D{{Key: "creadoEn", Value: -1}},
			Options: options.Index().SetName("auditoria_fecha"),
		}},
		{"auditoria", mongo.IndexModel{
			Keys:    bson.D{{Key: "accion", Value: 1}, {Key: "creadoEn", Value: -1}},
			Options: options.Index().SetName("auditoria_accion"),
		}},
		// Reportes: sesiones de un periodo por fecha.
		{"sesiones", mongo.IndexModel{
			Keys:    bson.D{{Key: "periodoId", Value: 1}, {Key: "fecha", Value: 1}},
			Options: options.Index().SetName("sesiones_periodo_fecha"),
		}},
	}
	for _, spec := range specs {
		if _, err := db.Collection(spec.collection).Indexes().CreateOne(ctx, spec.model); err != nil && !isIndexConflict(err) {
			return fmt.Errorf("crear índice en %s: %w", spec.collection, err)
		}
	}
	return nil
}
