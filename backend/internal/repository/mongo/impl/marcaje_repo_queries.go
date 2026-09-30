// Package impl — consultas avanzadas, ausencias automáticas y reversión offline.
// Satisface US-MAR-07 (AC-01..AC-05), US-MAR-09, US-MAR-11.
package impl

import (
	"context"
	"fmt"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo/options"

	"github.com/siaa/backend/internal/domain/marcaje"
	"github.com/siaa/backend/internal/repository"
)

// ListarConFiltros consulta marcajes con filtros administrativos (US-MAR-09).
func (r *marcajeMongoRepo) ListarConFiltros(ctx context.Context, f repository.FiltrosMarcaje, skip, limit int64) ([]*marcaje.Marcaje, int64, error) {
	filtro := bson.M{}

	if f.SesionID != "" {
		filtro["sesionId"] = f.SesionID
	}
	if f.UsuarioID != "" {
		filtro["$or"] = []bson.M{
			{"usuarioId": f.UsuarioID},
			{"docenteId": f.UsuarioID},
		}
	}
	if f.EspacioID != "" {
		filtro["espacioId"] = f.EspacioID
	}
	if f.Resultado != "" {
		filtro["resultado"] = f.Resultado
	}
	if f.Tipo != "" {
		filtro["tipo"] = f.Tipo
	}
	if f.Origen != "" {
		filtro["origen"] = f.Origen
	}
	if f.Anulado != nil {
		filtro["anulado"] = *f.Anulado
	}
	if cond := condicionAlcance(f.Alcance, "usuarioId"); cond != nil {
		filtro["$and"] = []bson.M{cond}
	}

	if f.Desde != nil || f.Hasta != nil {
		rango := bson.M{}
		if f.Desde != nil {
			rango["$gte"] = *f.Desde
		}
		if f.Hasta != nil {
			rango["$lte"] = *f.Hasta
		}
		filtro["timestampServidor"] = rango
	}

	total, err := r.col.CountDocuments(ctx, filtro)
	if err != nil {
		return nil, 0, fmt.Errorf("contar marcajes con filtros: %w", err)
	}

	if limit <= 0 {
		limit = 50
	}
	opts := options.Find().
		SetSort(bson.D{{Key: "timestampServidor", Value: -1}}).
		SetSkip(skip).
		SetLimit(limit)

	cur, err := r.col.Find(ctx, filtro, opts)
	if err != nil {
		return nil, 0, fmt.Errorf("buscar marcajes con filtros: %w", err)
	}
	defer cur.Close(ctx)

	var lista []*marcaje.Marcaje
	for cur.Next(ctx) {
		var item marcaje.Marcaje
		if err := cur.Decode(&item); err != nil {
			return nil, 0, fmt.Errorf("decodificar marcaje filtro: %w", err)
		}
		lista = append(lista, &item)
	}

	return lista, total, nil
}
