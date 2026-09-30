package impl

import (
	"context"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"

	"github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/repository"
	mongoConn "github.com/siaa/backend/internal/repository/mongo"
)

type agendaRepo struct {
	col *mongo.Collection
}

// NewAgendaRepository crea las consultas por ventana de tiempo para los recordatorios (EP-10).
func NewAgendaRepository(client *mongoConn.Client) repository.AgendaRepository {
	return &agendaRepo{col: client.Collection("sesiones")}
}

func (r *agendaRepo) SesionesQueInician(ctx context.Context, desde, hasta time.Time) ([]*academico.Sesion, error) {
	return r.porCampo(ctx, "inicioProgramado", desde, hasta)
}

func (r *agendaRepo) SesionesQueCierran(ctx context.Context, desde, hasta time.Time) ([]*academico.Sesion, error) {
	return r.porCampo(ctx, "ventanaEntradaCierra", desde, hasta)
}

// porCampo trae las sesiones vigentes (programadas o en curso) con el campo en [desde, hasta).
func (r *agendaRepo) porCampo(ctx context.Context, campo string, desde, hasta time.Time) ([]*academico.Sesion, error) {
	cur, err := r.col.Find(ctx, bson.M{
		"eliminado": bson.M{"$ne": true},
		campo:       bson.M{"$gte": desde, "$lt": hasta},
		"estado":    bson.M{"$in": []academico.EstadoSesion{academico.EstadoSesionProgramada, academico.EstadoSesionEnCurso}},
	})
	if err != nil {
		return nil, fmt.Errorf("consultar agenda por %s: %w", campo, err)
	}
	var docs []sesionDoc
	if err := cur.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decodificar agenda: %w", err)
	}
	res := make([]*academico.Sesion, len(docs))
	for i := range docs {
		res[i] = docToSesion(&docs[i])
	}
	return res, nil
}
