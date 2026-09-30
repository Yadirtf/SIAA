// Package impl — consultas del worker de ausencias y reversión por marcaje offline tardío
// (US-MAR-07, US-MAR-11, ADR-09).
package impl

import (
	"context"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"

	"github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/domain/marcaje"
)

// ObtenerSesionesExpiradasSinMarcaje trae solo las sesiones cuya ventana de entrada cerró en
// [desde, hasta) y resuelve en una sola consulta qué docentes ya tienen entrada consolidada.
func (r *marcajeMongoRepo) ObtenerSesionesExpiradasSinMarcaje(ctx context.Context, desde, hasta time.Time) ([]*academico.Sesion, error) {
	filtro := bson.M{
		"eliminado":            bson.M{"$ne": true},
		"ventanaEntradaCierra": bson.M{"$gte": desde, "$lt": hasta},
		"estado": bson.M{"$nin": []string{
			string(academico.EstadoSesionCancelada),
			string(academico.EstadoSesionExcluida),
			string(academico.EstadoSesionRealizada),
			string(academico.EstadoSesionSinDocente),
		}},
	}
	cur, err := r.db.Collection("sesiones").Find(ctx, filtro)
	if err != nil {
		return nil, fmt.Errorf("buscar sesiones expiradas: %w", err)
	}
	var docs []sesionDoc
	if err := cur.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decodificar sesiones expiradas: %w", err)
	}
	if len(docs) == 0 {
		return nil, nil
	}

	ids := make([]string, len(docs))
	for i := range docs {
		ids[i] = docs[i].ID.Hex()
	}
	consolidados, err := r.ListarConsolidados(ctx, ids, marcaje.TipoEntrada)
	if err != nil {
		return nil, err
	}
	conEntrada := map[string]bool{}
	for _, m := range consolidados {
		conEntrada[m.SesionID+"|"+m.UsuarioID] = true
	}

	var resultado []*academico.Sesion
	for i := range docs {
		for _, docente := range docs[i].DocenteIDs {
			if !conEntrada[docs[i].ID.Hex()+"|"+docente] {
				resultado = append(resultado, docToSesion(&docs[i]))
				break
			}
		}
	}
	return resultado, nil
}

// RevertirAusenciaPorOffline registra el marcaje offline como evento que reemplaza a la ausencia
// automática; la ausencia conserva sus datos y queda con reemplazadoPor.
func (r *marcajeMongoRepo) RevertirAusenciaPorOffline(ctx context.Context, ausenciaID string, nuevo *marcaje.Marcaje) error {
	if err := r.RegistrarAjuste(ctx, ausenciaID, nuevo); err != nil {
		return err
	}
	if oid, err := primitive.ObjectIDFromHex(nuevo.SesionID); err == nil {
		_, _ = r.db.Collection("sesiones").UpdateOne(ctx, bson.M{"_id": oid}, bson.M{"$set": bson.M{
			"estado":        academico.EstadoSesionRealizada,
			"actualizadoEn": time.Now().UTC(),
		}})
	}
	return nil
}
