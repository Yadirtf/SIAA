// Package impl — verificador de sesiones futuras asociadas a un espacio (US-GEO-06).
package impl

import (
	"context"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"

	"github.com/siaa/backend/internal/repository"
	mongoConn "github.com/siaa/backend/internal/repository/mongo"
)

type sesionFutureChecker struct {
	col *mongo.Collection
}

func NewSesionFutureChecker(client *mongoConn.Client) repository.SesionFutureChecker {
	return &sesionFutureChecker{col: client.Collection("sesiones")}
}

func (s *sesionFutureChecker) CountSesionesFuturasPorEspacio(ctx context.Context, espacioID string, desde time.Time) (int64, error) {
	count, err := s.col.CountDocuments(ctx, bson.D{
		{Key: "espacioId", Value: espacioID},
		{Key: "inicioProgramado", Value: bson.D{{Key: "$gt", Value: desde}}},
		{Key: "estado", Value: bson.D{{Key: "$ne", Value: "CANCELADA"}}},
		{Key: "eliminado", Value: bson.D{{Key: "$ne", Value: true}}},
	})
	if err != nil {
		return 0, fmt.Errorf("countSesionesFuturas: %w", err)
	}
	return count, nil
}
