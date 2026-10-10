package impl

import (
	"context"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo/options"

	"github.com/siaa/backend/internal/domain/notificacion"
	"github.com/siaa/backend/internal/repository"
	mongoConn "github.com/siaa/backend/internal/repository/mongo"
)

// NewAlertasRepository lee las alertas recientes de la colección de notificaciones para el
// tablero en vivo (US-REP-03). Usa el índice notificaciones_tipo_fecha.
func NewAlertasRepository(client *mongoConn.Client) repository.AlertasRepository {
	return &notificacionRepo{col: client.Collection("notificaciones")}
}

// Recientes devuelve los avisos del tipo creados desde `desde`, los más recientes primero.
func (r *notificacionRepo) Recientes(ctx context.Context, tipo notificacion.Tipo, desde time.Time, limite int) ([]*notificacion.Notificacion, error) {
	opts := options.Find().SetSort(bson.D{{Key: "creadaEn", Value: -1}})
	if limite > 0 {
		opts.SetLimit(int64(limite))
	}
	return r.buscar(ctx, bson.M{"tipo": string(tipo), "creadaEn": bson.M{"$gte": desde}}, opts)
}
