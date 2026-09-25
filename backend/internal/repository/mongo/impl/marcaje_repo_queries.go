// Package impl — consultas avanzadas, ausencias automáticas y reversión offline.
// Satisface US-MAR-07 (AC-01..AC-05), US-MAR-09, US-MAR-11.
package impl

import (
	"context"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo/options"

	"github.com/siaa/backend/internal/domain/academico"
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

// ObtenerSesionesExpiradasSinMarcaje consulta sesiones cuya ventana de entrada cerró y no tienen marcaje de entrada (US-MAR-07).
func (r *marcajeMongoRepo) ObtenerSesionesExpiradasSinMarcaje(ctx context.Context, ahora time.Time) ([]*academico.Sesion, error) {
	colSesiones := r.db.Collection("sesiones")

	// 1. Sesiones del día de hoy o anteriores que ya expiraron su ventana de entrada
	filtroSesiones := bson.M{
		"ventanaEntradaCierra": bson.M{"$lt": ahora},
		"estado": bson.M{
			"$nin": []string{
				string(academico.EstadoSesionCancelada),
				string(academico.EstadoSesionExcluida),
				string(academico.EstadoSesionRealizada),
				string(academico.EstadoSesionSinDocente),
			},
		},
	}

	cur, err := colSesiones.Find(ctx, filtroSesiones)
	if err != nil {
		return nil, fmt.Errorf("buscar sesiones expiradas: %w", err)
	}
	defer cur.Close(ctx)

	var resultado []*academico.Sesion
	for cur.Next(ctx) {
		var sDoc sesionDoc
		if err := cur.Decode(&sDoc); err != nil {
			continue
		}
		// Verificar si ya tiene un marcaje de entrada no anulado
		count, errMarc := r.col.CountDocuments(ctx, bson.M{
			"sesionId": sDoc.ID,
			"tipo":     marcaje.TipoEntrada,
			"anulado":  false,
		})
		if errMarc == nil && count == 0 {
			resultado = append(resultado, docToSesion(&sDoc))
		}
	}

	return resultado, nil
}

// RevertirAusenciaPorOffline revierte la ausencia generada automáticamente al sincronizar un marcaje offline válido posterior (US-MAR-07 AC-05, US-MAR-11).
func (r *marcajeMongoRepo) RevertirAusenciaPorOffline(ctx context.Context, sesionID, usuarioID string, nuevoMarcaje *marcaje.Marcaje) error {
	// 1. Anular el registro previo de AUSENTE
	filtroAusencia := bson.M{
		"sesionId": sesionID,
		"$or": []bson.M{
			{"usuarioId": usuarioID},
			{"docenteId": usuarioID},
		},
		"resultado": marcaje.ResultadoAusente,
		"anulado":   false,
	}

	ahora := time.Now().UTC()
	updateAusencia := bson.M{
		"$set": bson.M{
			"anulado":      true,
			"motivoAjuste": "Reversión automática por sincronización posterior de marcaje offline válido (US-MAR-07 AC-05)",
			"ajustadoPor":  "SISTEMA_OFFLINE_SYNC",
			"ajustadoEn":   ahora,
		},
	}

	_, _ = r.col.UpdateMany(ctx, filtroAusencia, updateAusencia)

	// 2. Persistir el nuevo marcaje
	if err := r.Crear(ctx, nuevoMarcaje); err != nil {
		return fmt.Errorf("persistir nuevo marcaje offline en reversion: %w", err)
	}

	// 3. Actualizar estado de la sesión a REALIZADA
	colSesiones := r.db.Collection("sesiones")
	_, _ = colSesiones.UpdateOne(ctx, bson.M{"_id": sesionID}, bson.M{
		"$set": bson.M{
			"estado":        academico.EstadoSesionRealizada,
			"actualizadoEn": ahora,
		},
	})

	return nil
}
