// Package migrations provee la creación idempotente de índices MongoDB.
// T-PLT-01.7, §10.3 del backlog.
// MongoDB ignora la creación si el índice ya existe con el mismo nombre y spec.
package migrations

import (
	"context"
	"fmt"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// CreateIndexes crea todos los índices obligatorios del sistema de forma idempotente.
func CreateIndexes(ctx context.Context, db *mongo.Database) error {
	type indexSpec struct {
		collection string
		model      mongo.IndexModel
	}

	specs := []indexSpec{
		// ── usuarios ────────────────────────────────────────
		{
			collection: "usuarios",
			model: mongo.IndexModel{
				Keys:    bson.D{{Key: "correo", Value: 1}},
				Options: options.Index().SetUnique(true).SetName("usuarios_correo_unique"),
			},
		},
		// ── dispositivos ────────────────────────────────────
		{
			collection: "dispositivos",
			model: mongo.IndexModel{
				Keys:    bson.D{{Key: "usuarioId", Value: 1}, {Key: "instalacionId", Value: 1}},
				Options: options.Index().SetUnique(true).SetName("dispositivos_usuario_instalacion"),
			},
		},
		// ── refresh_tokens ──────────────────────────────────
		{
			collection: "refresh_tokens",
			model: mongo.IndexModel{
				Keys:    bson.D{{Key: "tokenHash", Value: 1}},
				Options: options.Index().SetUnique(true).SetName("refresh_tokens_hash_unique"),
			},
		},
		{
			collection: "refresh_tokens",
			model: mongo.IndexModel{
				Keys:    bson.D{{Key: "expiraEn", Value: 1}},
				Options: options.Index().SetExpireAfterSeconds(0).SetName("refresh_tokens_ttl"),
			},
		},
		// ── recovery_tokens ─────────────────────────────────
		{
			collection: "recovery_tokens",
			model: mongo.IndexModel{
				Keys:    bson.D{{Key: "tokenHash", Value: 1}},
				Options: options.Index().SetUnique(true).SetName("recovery_tokens_hash_unique"),
			},
		},
		{
			collection: "recovery_tokens",
			model: mongo.IndexModel{
				Keys:    bson.D{{Key: "expiraEn", Value: 1}},
				Options: options.Index().SetExpireAfterSeconds(0).SetName("recovery_tokens_ttl"),
			},
		},
		// ── espacios — geoespaciales §10.3 ──────────────────
		{
			collection: "espacios",
			model: mongo.IndexModel{
				Keys:    bson.D{{Key: "geometria", Value: "2dsphere"}},
				Options: options.Index().SetName("espacios_geometria_2dsphere"),
			},
		},
		{
			collection: "espacios",
			model: mongo.IndexModel{
				Keys:    bson.D{{Key: "geometriaBuffer", Value: "2dsphere"}},
				Options: options.Index().SetName("espacios_geometria_buffer_2dsphere"),
			},
		},
		{
			collection: "espacios",
			model: mongo.IndexModel{
				Keys:    bson.D{{Key: "codigo", Value: 1}},
				Options: options.Index().SetUnique(true).SetName("espacios_codigo_unique"),
			},
		},
		{
			collection: "espacios",
			model: mongo.IndexModel{
				Keys:    bson.D{{Key: "sedeId", Value: 1}, {Key: "bloqueId", Value: 1}, {Key: "piso", Value: 1}},
				Options: options.Index().SetName("espacios_sede_bloque_piso"),
			},
		},
		// ── sesiones ────────────────────────────────────────
		{
			collection: "sesiones",
			model: mongo.IndexModel{
				Keys: bson.D{
					{Key: "docenteIds", Value: 1},
					{Key: "ventanaEntradaAbre", Value: 1},
					{Key: "ventanaEntradaCierra", Value: 1},
				},
				Options: options.Index().SetName("sesiones_docente_ventana"),
			},
		},
		{
			collection: "sesiones",
			model: mongo.IndexModel{
				Keys:    bson.D{{Key: "espacioId", Value: 1}, {Key: "inicioProgramado", Value: 1}},
				Options: options.Index().SetName("sesiones_espacio_inicio"),
			},
		},
		{
			collection: "sesiones",
			model: mongo.IndexModel{
				Keys:    bson.D{{Key: "fecha", Value: 1}, {Key: "estado", Value: 1}},
				Options: options.Index().SetName("sesiones_fecha_estado"),
			},
		},
		// ── marcajes — índice único PARCIAL (excluye anulados) — ADR-07, §10.4 ──
		{
			collection: "marcajes",
			model: mongo.IndexModel{
				Keys: bson.D{
					{Key: "sesionId", Value: 1},
					{Key: "usuarioId", Value: 1},
					{Key: "tipo", Value: 1},
				},
				Options: options.Index().
					SetUnique(true).
					SetName("marcajes_sesion_usuario_tipo_unique").
					SetPartialFilterExpression(bson.D{{Key: "anulado", Value: false}}),
			},
		},
		{
			collection: "marcajes",
			model: mongo.IndexModel{
				Keys:    bson.D{{Key: "usuarioId", Value: 1}, {Key: "creadoEn", Value: -1}},
				Options: options.Index().SetName("marcajes_usuario_fecha"),
			},
		},
		{
			collection: "marcajes",
			model: mongo.IndexModel{
				Keys:    bson.D{{Key: "resultado", Value: 1}, {Key: "espacioId", Value: 1}, {Key: "creadoEn", Value: -1}},
				Options: options.Index().SetName("marcajes_resultado_espacio"),
			},
		},
		{
			collection: "marcajes",
			model: mongo.IndexModel{
				Keys:    bson.D{{Key: "ubicacion", Value: "2dsphere"}},
				Options: options.Index().SetSparse(true).SetName("marcajes_ubicacion_2dsphere"),
			},
		},
		// ── auditoria ───────────────────────────────────────
		{
			collection: "auditoria",
			model: mongo.IndexModel{
				Keys:    bson.D{{Key: "entidad", Value: 1}, {Key: "entidadId", Value: 1}, {Key: "creadoEn", Value: -1}},
				Options: options.Index().SetName("auditoria_entidad"),
			},
		},
		{
			collection: "auditoria",
			model: mongo.IndexModel{
				Keys:    bson.D{{Key: "actorId", Value: 1}, {Key: "creadoEn", Value: -1}},
				Options: options.Index().SetName("auditoria_actor"),
			},
		},
		// ── parametros ──────────────────────────────────────
		{
			collection: "parametros",
			model: mongo.IndexModel{
				Keys:    bson.D{{Key: "ambito", Value: 1}, {Key: "ambitoId", Value: 1}, {Key: "vigenteDesde", Value: -1}},
				Options: options.Index().SetName("parametros_ambito"),
			},
		},
		// ── asignaciones ────────────────────────────────────
		{
			collection: "asignaciones",
			model: mongo.IndexModel{
				Keys:    bson.D{{Key: "periodoId", Value: 1}, {Key: "docenteIds", Value: 1}},
				Options: options.Index().SetName("asignaciones_periodo_docente"),
			},
		},
		{
			collection: "asignaciones",
			model: mongo.IndexModel{
				Keys: bson.D{
					{Key: "periodoId", Value: 1},
					{Key: "espacioId", Value: 1},
					{Key: "franja.diaSemana", Value: 1},
				},
				Options: options.Index().SetName("asignaciones_colision_aula"),
			},
		},
		// ── consentimientos ─────────────────────────────────
		{
			collection: "consentimientos",
			model: mongo.IndexModel{
				Keys:    bson.D{{Key: "usuarioId", Value: 1}, {Key: "versionPolitica", Value: 1}},
				Options: options.Index().SetName("consentimientos_usuario_version"),
			},
		},
	}

	for _, spec := range specs {
		col := db.Collection(spec.collection)
		if _, err := col.Indexes().CreateOne(ctx, spec.model); err != nil {
			if !isIndexConflict(err) {
				return fmt.Errorf("crear índice en %s: %w", spec.collection, err)
			}
		}
	}
	return nil
}

// isIndexConflict determina si el error es por un índice ya existente (idempotente).
func isIndexConflict(err error) bool {
	if err == nil {
		return false
	}
	msg := err.Error()
	for _, sub := range []string{"IndexKeySpecsConflict", "IndexOptionsConflict", "already exists"} {
		if containsStr(msg, sub) {
			return true
		}
	}
	return false
}

func containsStr(s, sub string) bool {
	if len(s) < len(sub) {
		return false
	}
	for i := 0; i <= len(s)-len(sub); i++ {
		if s[i:i+len(sub)] == sub {
			return true
		}
	}
	return false
}
