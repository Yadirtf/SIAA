package impl

import (
	"context"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"

	"github.com/siaa/backend/internal/domain/privacidad"
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

// filtroVencidos selecciona los marcajes anteriores al límite que aún tienen coordenadas.
func filtroVencidos(antesDe time.Time) bson.M {
	return bson.M{
		"timestampServidor":             bson.M{"$lt": antesDe},
		"geolocalizacion.coordenadas.0": bson.M{"$exists": true},
	}
}

// condicionesExclusion arma una condición por cada tipo de registro protegido.
func condicionesExclusion(ex privacidad.ExclusionRetencion) bson.A {
	var o bson.A
	if len(ex.UsuarioIDs) > 0 {
		o = append(o, bson.M{"usuarioId": bson.M{"$in": ex.UsuarioIDs}})
	}
	if len(ex.SesionIDs) > 0 {
		o = append(o, bson.M{"sesionId": bson.M{"$in": ex.SesionIDs}})
	}
	if len(ex.MarcajeIDs) > 0 {
		o = append(o, bson.M{"_id": bson.M{"$in": ex.MarcajeIDs}})
	}
	return o
}

// AnonimizarUbicaciones borra las coordenadas y conserva resultado, distancia y precisión, que
// no identifican un lugar. Las copias del marcaje en la bitácora (ajustes) también se limpian.
// Los marcajes bajo investigación en curso, y sus copias en la bitácora, no se tocan.
func (r *retencionRepo) AnonimizarUbicaciones(ctx context.Context, antesDe time.Time, excluir privacidad.ExclusionRetencion) (int64, error) {
	ahora := time.Now().UTC()
	filtro := filtroVencidos(antesDe)
	protegidos, err := r.marcajesProtegidos(ctx, excluir)
	if err != nil {
		return 0, err
	}
	if cond := condicionesExclusion(excluir); len(cond) > 0 {
		filtro["$nor"] = cond
	}
	res, err := r.marcajes.UpdateMany(ctx, filtro,
		bson.M{"$set": bson.M{"geolocalizacion.coordenadas": nil, "anonimizadoEn": ahora}})
	if err != nil {
		return 0, fmt.Errorf("anonimizar marcajes: %w", err)
	}
	for _, campo := range []string{"valorAnterior", "valorNuevo"} {
		ruta := campo + ".geolocalizacion.coordenadas"
		filtroAud := bson.M{
			"entidad":   "marcajes",
			"creadoEn":  bson.M{"$lt": antesDe},
			ruta + ".0": bson.M{"$exists": true},
		}
		if len(protegidos) > 0 {
			filtroAud["entidadId"] = bson.M{"$nin": protegidos}
		}
		if _, err := r.auditoria.UpdateMany(ctx, filtroAud, bson.M{"$set": bson.M{ruta: nil}}); err != nil {
			return res.ModifiedCount, fmt.Errorf("anonimizar bitácora: %w", err)
		}
	}
	return res.ModifiedCount, nil
}

// ContarRetenidos cuenta los marcajes vencidos que la investigación mantiene intactos.
func (r *retencionRepo) ContarRetenidos(ctx context.Context, antesDe time.Time, retener privacidad.ExclusionRetencion) (int64, error) {
	cond := condicionesExclusion(retener)
	if len(cond) == 0 {
		return 0, nil
	}
	filtro := filtroVencidos(antesDe)
	filtro["$or"] = cond
	n, err := r.marcajes.CountDocuments(ctx, filtro)
	if err != nil {
		return 0, fmt.Errorf("contar marcajes retenidos: %w", err)
	}
	return n, nil
}

// marcajesProtegidos devuelve los ids de todos los marcajes bajo investigación, para que sus
// copias en la bitácora tampoco se anonimicen.
func (r *retencionRepo) marcajesProtegidos(ctx context.Context, ex privacidad.ExclusionRetencion) ([]string, error) {
	cond := condicionesExclusion(ex)
	if len(cond) == 0 {
		return nil, nil
	}
	ids, err := r.marcajes.Distinct(ctx, "_id", bson.M{"$or": cond})
	if err != nil {
		return nil, fmt.Errorf("leer marcajes protegidos: %w", err)
	}
	out := make([]string, 0, len(ids))
	for _, id := range ids {
		if s, ok := id.(string); ok {
			out = append(out, s)
		}
	}
	return out, nil
}
