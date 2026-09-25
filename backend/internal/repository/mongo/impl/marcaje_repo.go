// Package impl — repositorio MongoDB para marcajes de asistencia.
// Satisface US-MAR-04, US-MAR-05, US-MAR-08, US-MAR-09, ADR-07.
package impl

import (
	"context"
	"errors"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"

	"github.com/siaa/backend/internal/domain/marcaje"
	"github.com/siaa/backend/internal/repository"
)

const coleccionMarcajes = "marcajes"

type marcajeMongoRepo struct {
	col *mongo.Collection
	db  *mongo.Database
}

// NewMarcajeMongoRepository inicializa una nueva instancia del repositorio de marcajes.
func NewMarcajeMongoRepository(db *mongo.Database) repository.MarcajeRepository {
	return &marcajeMongoRepo{
		col: db.Collection(coleccionMarcajes),
		db:  db,
	}
}

// Crear inserta el marcaje y traduce el error de clave duplicada a retorno idempotente del registro existente (ADR-07).
func (r *marcajeMongoRepo) Crear(ctx context.Context, m *marcaje.Marcaje) error {
	if m.ID == "" {
		m.ID = primitive.NewObjectID().Hex()
	}
	if m.CreadoEn.IsZero() {
		m.CreadoEn = time.Now().UTC()
	}
	if m.Timestamp.IsZero() {
		m.Timestamp = m.TimestampServidor
	}

	_, err := r.col.InsertOne(ctx, m)
	if err != nil {
		if mongo.IsDuplicateKeyError(err) {
			// US-MAR-05 AC-03: recuperación transparente del registro existente ante carrera concurrente
			previo, errPrevio := r.ObtenerPrevio(ctx, m.SesionID, m.UsuarioID, m.Tipo)
			if errPrevio == nil && previo != nil {
				*m = *previo
				return nil
			}
		}
		return fmt.Errorf("error persistiendo marcaje: %w", err)
	}

	return nil
}

// ObtenerPorID busca un marcaje por su identificador primario.
func (r *marcajeMongoRepo) ObtenerPorID(ctx context.Context, id string) (*marcaje.Marcaje, error) {
	var m marcaje.Marcaje
	err := r.col.FindOne(ctx, bson.M{"_id": id}).Decode(&m)
	if err != nil {
		if errors.Is(err, mongo.ErrNoDocuments) {
			return nil, nil
		}
		return nil, fmt.Errorf("buscar marcaje por id: %w", err)
	}
	return &m, nil
}

// ObtenerPrevio consulta si ya existe un marcaje activo (no anulado) para sesión, usuario y tipo.
func (r *marcajeMongoRepo) ObtenerPrevio(ctx context.Context, sesionID, usuarioID string, tipo marcaje.TipoMarcaje) (*marcaje.Marcaje, error) {
	filtro := bson.M{
		"sesionId": sesionID,
		"$or": []bson.M{
			{"usuarioId": usuarioID},
			{"docenteId": usuarioID},
		},
		"tipo":    tipo,
		"anulado": false,
	}

	var m marcaje.Marcaje
	err := r.col.FindOne(ctx, filtro).Decode(&m)
	if err != nil {
		if errors.Is(err, mongo.ErrNoDocuments) {
			return nil, nil
		}
		return nil, fmt.Errorf("buscar marcaje previo: %w", err)
	}
	return &m, nil
}

// ListarPorUsuario obtiene el historial paginado de marcajes de un usuario con filtro mensual opcional (US-MAR-08).
func (r *marcajeMongoRepo) ListarPorUsuario(ctx context.Context, usuarioID string, mes string, skip, limit int64) ([]*marcaje.Marcaje, int64, error) {
	filtro := bson.M{
		"$or": []bson.M{
			{"usuarioId": usuarioID},
			{"docenteId": usuarioID},
		},
	}

	// Filtro mensual en formato "YYYY-MM" (ej. "2026-09")
	if len(mes) >= 7 {
		inicioMes, errMes := time.Parse("2006-01", mes[:7])
		if errMes == nil {
			finMes := inicioMes.AddDate(0, 1, 0)
			filtro["timestampServidor"] = bson.M{
				"$gte": inicioMes,
				"$lt":  finMes,
			}
		}
	}

	total, err := r.col.CountDocuments(ctx, filtro)
	if err != nil {
		return nil, 0, fmt.Errorf("contar historial usuario: %w", err)
	}

	if limit <= 0 {
		limit = 20
	}
	opts := options.Find().
		SetSort(bson.D{{Key: "timestampServidor", Value: -1}}).
		SetSkip(skip).
		SetLimit(limit)

	cur, err := r.col.Find(ctx, filtro, opts)
	if err != nil {
		return nil, 0, fmt.Errorf("consultar historial usuario: %w", err)
	}
	defer cur.Close(ctx)

	var lista []*marcaje.Marcaje
	for cur.Next(ctx) {
		var item marcaje.Marcaje
		if err := cur.Decode(&item); err != nil {
			return nil, 0, fmt.Errorf("decodificar marcaje historial: %w", err)
		}
		lista = append(lista, &item)
	}

	return lista, total, nil
}

// ActualizarAjuste aplica un ajuste o anulación administrativa conservando trazabilidad (US-MAR-09).
func (r *marcajeMongoRepo) ActualizarAjuste(ctx context.Context, id string, nuevoResultado marcaje.ResultadoMarcaje, anulado bool, motivo string, ajustadorID string, ajustadoEn time.Time) (*marcaje.Marcaje, error) {
	update := bson.M{
		"$set": bson.M{
			"anulado":      anulado,
			"motivoAjuste": motivo,
			"ajustadoPor":  ajustadorID,
			"ajustadoEn":   ajustadoEn,
		},
	}
	if nuevoResultado != "" {
		update["$set"].(bson.M)["resultado"] = nuevoResultado
	}

	opts := options.FindOneAndUpdate().SetReturnDocument(options.After)
	var actualizado marcaje.Marcaje
	err := r.col.FindOneAndUpdate(ctx, bson.M{"_id": id}, update, opts).Decode(&actualizado)
	if err != nil {
		return nil, fmt.Errorf("actualizar ajuste marcaje: %w", err)
	}

	return &actualizado, nil
}

// ObtenerUltimoMarcajeUsuario obtiene el marcaje más reciente para análisis de saltos imposibles (US-MAR-10 AC-04).
func (r *marcajeMongoRepo) ObtenerUltimoMarcajeUsuario(ctx context.Context, usuarioID string) (*marcaje.Marcaje, error) {
	filtro := bson.M{
		"$or": []bson.M{
			{"usuarioId": usuarioID},
			{"docenteId": usuarioID},
		},
		"anulado": false,
	}
	opts := options.FindOne().SetSort(bson.D{{Key: "timestampServidor", Value: -1}})

	var m marcaje.Marcaje
	err := r.col.FindOne(ctx, filtro, opts).Decode(&m)
	if err != nil {
		if errors.Is(err, mongo.ErrNoDocuments) {
			return nil, nil
		}
		return nil, fmt.Errorf("obtener ultimo marcaje usuario: %w", err)
	}

	return &m, nil
}
