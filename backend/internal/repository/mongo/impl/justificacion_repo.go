// Package impl — repositorio MongoDB de justificaciones (EP-07).
package impl

import (
	"context"
	"errors"
	"fmt"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"

	"github.com/siaa/backend/internal/domain/justificacion"
	"github.com/siaa/backend/internal/repository"
	mongoConn "github.com/siaa/backend/internal/repository/mongo"
)

type justificacionRepo struct {
	col *mongo.Collection
}

// NewJustificacionRepository crea el repositorio de justificaciones.
func NewJustificacionRepository(client *mongoConn.Client) repository.JustificacionRepository {
	return &justificacionRepo{col: client.Collection("justificaciones")}
}

func (r *justificacionRepo) Crear(ctx context.Context, j *justificacion.Justificacion) error {
	if j.ID == "" {
		j.ID = primitive.NewObjectID().Hex()
	}
	if _, err := r.col.InsertOne(ctx, j); err != nil {
		if mongo.IsDuplicateKeyError(err) {
			return repository.ErrJustificacionModificada
		}
		return fmt.Errorf("crear justificación: %w", err)
	}
	return nil
}

func (r *justificacionRepo) uno(ctx context.Context, filtro bson.M) (*justificacion.Justificacion, error) {
	var j justificacion.Justificacion
	if err := r.col.FindOne(ctx, filtro).Decode(&j); err != nil {
		if errors.Is(err, mongo.ErrNoDocuments) {
			return nil, nil
		}
		return nil, fmt.Errorf("buscar justificación: %w", err)
	}
	return &j, nil
}

func (r *justificacionRepo) ObtenerPorID(ctx context.Context, id string) (*justificacion.Justificacion, error) {
	return r.uno(ctx, bson.M{"_id": id})
}

func (r *justificacionRepo) ObtenerVigente(ctx context.Context, sesionID, docenteID string) (*justificacion.Justificacion, error) {
	return r.uno(ctx, bson.M{
		"sesionId":  sesionID,
		"docenteId": docenteID,
		"estado":    bson.M{"$ne": justificacion.EstadoRechazada},
	})
}

func (r *justificacionRepo) Listar(ctx context.Context, f repository.FiltroJustificaciones, skip, limit int64) ([]*justificacion.Justificacion, int64, error) {
	filtro := bson.M{}
	if f.DocenteID != "" {
		filtro["docenteId"] = f.DocenteID
	}
	if f.SesionIDs != nil {
		filtro["sesionId"] = bson.M{"$in": f.SesionIDs}
	}
	if f.Estado != "" {
		filtro["estado"] = f.Estado
	}
	if f.Tipo != "" {
		filtro["tipo"] = f.Tipo
	}
	rango := bson.M{}
	if f.FechaDesde != "" {
		rango["$gte"] = f.FechaDesde
	}
	if f.FechaHasta != "" {
		rango["$lte"] = f.FechaHasta
	}
	if len(rango) > 0 {
		filtro["fechaSesion"] = rango
	}
	if cond := condicionAlcance(f.Alcance, "docenteId"); cond != nil {
		filtro["$and"] = []bson.M{cond}
	}

	total, err := r.col.CountDocuments(ctx, filtro)
	if err != nil {
		return nil, 0, fmt.Errorf("contar justificaciones: %w", err)
	}
	opts := options.Find().SetSort(bson.D{{Key: "creadoEn", Value: -1}}).SetSkip(skip)
	if limit > 0 {
		opts.SetLimit(limit)
	}
	cur, err := r.col.Find(ctx, filtro, opts)
	if err != nil {
		return nil, 0, fmt.Errorf("listar justificaciones: %w", err)
	}
	lista := []*justificacion.Justificacion{}
	if err := cur.All(ctx, &lista); err != nil {
		return nil, 0, fmt.Errorf("decodificar justificaciones: %w", err)
	}
	return lista, total, nil
}

func (r *justificacionRepo) ActualizarEstado(ctx context.Context, j *justificacion.Justificacion, estadoPrevio justificacion.Estado) error {
	res, err := r.col.UpdateOne(ctx, bson.M{"_id": j.ID, "estado": estadoPrevio}, bson.M{"$set": bson.M{
		"estado":        j.Estado,
		"revisorId":     j.RevisorID,
		"observaciones": j.Observaciones,
		"historial":     j.Historial,
		"actualizadoEn": j.ActualizadoEn,
	}})
	if err != nil {
		return fmt.Errorf("actualizar justificación: %w", err)
	}
	if res.MatchedCount == 0 {
		return repository.ErrJustificacionModificada
	}
	return nil
}
