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

type retencionRepo struct {
	marcajes  *mongo.Collection
	auditoria *mongo.Collection
}

// NewRetencionRepository crea el repositorio que anonimiza ubicaciones vencidas (RNF-LEG-006).
func NewRetencionRepository(client *mongoConn.Client) repository.RetencionRepository {
	return &retencionRepo{marcajes: client.Collection("marcajes"), auditoria: client.Collection("auditoria")}
}

// AnonimizarUbicaciones borra las coordenadas y conserva resultado, distancia y precisión, que
// no identifican un lugar. Las copias del marcaje en la bitácora (ajustes) también se limpian.
func (r *retencionRepo) AnonimizarUbicaciones(ctx context.Context, antesDe time.Time) (int64, error) {
	ahora := time.Now().UTC()
	res, err := r.marcajes.UpdateMany(ctx, bson.M{
		"timestampServidor":             bson.M{"$lt": antesDe},
		"geolocalizacion.coordenadas.0": bson.M{"$exists": true},
	}, bson.M{"$set": bson.M{"geolocalizacion.coordenadas": nil, "anonimizadoEn": ahora}})
	if err != nil {
		return 0, fmt.Errorf("anonimizar marcajes: %w", err)
	}
	for _, campo := range []string{"valorAnterior", "valorNuevo"} {
		ruta := campo + ".geolocalizacion.coordenadas"
		if _, err := r.auditoria.UpdateMany(ctx, bson.M{
			"entidad":   "marcajes",
			"creadoEn":  bson.M{"$lt": antesDe},
			ruta + ".0": bson.M{"$exists": true},
		}, bson.M{"$set": bson.M{ruta: nil}}); err != nil {
			return res.ModifiedCount, fmt.Errorf("anonimizar bitácora: %w", err)
		}
	}
	return res.ModifiedCount, nil
}
