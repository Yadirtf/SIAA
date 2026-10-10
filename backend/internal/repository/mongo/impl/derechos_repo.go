// Package impl — repositorio MongoDB de las solicitudes de derechos del titular (US-LEG-02).
package impl

import (
	"context"
	"errors"
	"fmt"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"

	"github.com/siaa/backend/internal/domain/privacidad"
	"github.com/siaa/backend/internal/repository"
	mongoConn "github.com/siaa/backend/internal/repository/mongo"
)

type solicitudDerechoRepo struct {
	col *mongo.Collection
}

// NewSolicitudDerechoRepository crea el repositorio de la colección solicitudes_derechos.
func NewSolicitudDerechoRepository(client *mongoConn.Client) repository.SolicitudDerechoRepository {
	return &solicitudDerechoRepo{col: client.Collection("solicitudes_derechos")}
}

func (r *solicitudDerechoRepo) Crear(ctx context.Context, s *privacidad.SolicitudDerecho) error {
	if s.ID == "" {
		s.ID = primitive.NewObjectID().Hex()
	}
	if _, err := r.col.InsertOne(ctx, s); err != nil {
		return fmt.Errorf("crear solicitud de derechos: %w", err)
	}
	return nil
}

func (r *solicitudDerechoRepo) Obtener(ctx context.Context, id string) (*privacidad.SolicitudDerecho, error) {
	var s privacidad.SolicitudDerecho
	if err := r.col.FindOne(ctx, bson.M{"_id": id}).Decode(&s); err != nil {
		if errors.Is(err, mongo.ErrNoDocuments) {
			return nil, nil
		}
		return nil, fmt.Errorf("leer solicitud de derechos: %w", err)
	}
	return &s, nil
}

func (r *solicitudDerechoRepo) Listar(ctx context.Context, f repository.FiltroSolicitudesDerechos, limite int) ([]*privacidad.SolicitudDerecho, error) {
	filtro := bson.M{}
	if f.TitularID != "" {
		filtro["titularId"] = f.TitularID
	}
	if f.Tipo != "" {
		filtro["tipo"] = f.Tipo
	}
	if f.SoloAbiertas {
		filtro["estado"] = bson.M{"$in": bson.A{privacidad.SolicitudRadicada, privacidad.SolicitudEnTramite}}
	} else if f.Estado != "" {
		filtro["estado"] = f.Estado
	}
	if limite <= 0 || limite > 500 {
		limite = 500
	}
	opts := options.Find().SetSort(bson.D{{Key: "venceEn", Value: 1}, {Key: "_id", Value: 1}}).SetLimit(int64(limite))
	cur, err := r.col.Find(ctx, filtro, opts)
	if err != nil {
		return nil, fmt.Errorf("listar solicitudes de derechos: %w", err)
	}
	lista := []*privacidad.SolicitudDerecho{}
	if err := cur.All(ctx, &lista); err != nil {
		return nil, fmt.Errorf("decodificar solicitudes de derechos: %w", err)
	}
	return lista, nil
}

func (r *solicitudDerechoRepo) Actualizar(ctx context.Context, s *privacidad.SolicitudDerecho, estadoPrevio privacidad.EstadoSolicitud) error {
	res, err := r.col.ReplaceOne(ctx, bson.M{"_id": s.ID, "estado": estadoPrevio}, s)
	if err != nil {
		return fmt.Errorf("actualizar solicitud de derechos: %w", err)
	}
	if res.MatchedCount == 0 {
		return repository.ErrSolicitudModificada
	}
	return nil
}
