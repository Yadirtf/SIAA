// Package impl — consultas MongoDB de los avisos programados (US-JUS-04 AC-02, US-ROL-05 AC-02).
package impl

import (
	"context"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo/options"

	"github.com/siaa/backend/internal/domain/justificacion"
	"github.com/siaa/backend/internal/domain/user"
	"github.com/siaa/backend/internal/repository"
	mongoConn "github.com/siaa/backend/internal/repository/mongo"
)

// NewJustificacionesSinResolverRepository crea la consulta de justificaciones pendientes.
func NewJustificacionesSinResolverRepository(client *mongoConn.Client) repository.JustificacionesSinResolverRepository {
	return &justificacionRepo{col: client.Collection("justificaciones")}
}

// SinResolver lista las justificaciones radicadas o en revisión anteriores al límite.
func (r *justificacionRepo) SinResolver(ctx context.Context, radicadasAntesDe time.Time, limite int) ([]*justificacion.Justificacion, error) {
	filtro := bson.M{
		"estado":   bson.M{"$in": bson.A{justificacion.EstadoRadicada, justificacion.EstadoEnRevision}},
		"creadoEn": bson.M{"$lte": radicadasAntesDe},
	}
	opts := options.Find().SetSort(bson.D{{Key: "creadoEn", Value: 1}}).SetLimit(int64(limite))
	cur, err := r.col.Find(ctx, filtro, opts)
	if err != nil {
		return nil, fmt.Errorf("justificaciones sin resolver: %w", err)
	}
	var lista []*justificacion.Justificacion
	if err := cur.All(ctx, &lista); err != nil {
		return nil, fmt.Errorf("decodificar justificaciones sin resolver: %w", err)
	}
	return lista, nil
}

// NewRolesPorVencerRepository crea la consulta de roles próximos a vencer.
func NewRolesPorVencerRepository(client *mongoConn.Client) repository.RolesPorVencerRepository {
	return &usuarioRepository{col: client.Collection("usuarios")}
}

// ConRolesPorVencer lista los usuarios activos con un rol que vence en (desde, hasta].
func (r *usuarioRepository) ConRolesPorVencer(ctx context.Context, desde, hasta time.Time) ([]*user.Usuario, error) {
	filtro := bson.M{
		"activo": true, "eliminado": false,
		"roles": bson.M{"$elemMatch": bson.M{"vigenciaFin": bson.M{"$gt": desde, "$lte": hasta}}},
	}
	cur, err := r.col.Find(ctx, filtro, options.Find().SetLimit(500))
	if err != nil {
		return nil, fmt.Errorf("roles por vencer: %w", err)
	}
	var docs []usuarioDoc
	if err := cur.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decodificar roles por vencer: %w", err)
	}
	res := make([]*user.Usuario, 0, len(docs))
	for i := range docs {
		res = append(res, docToUsuario(&docs[i]))
	}
	return res, nil
}
