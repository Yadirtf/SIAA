// Package impl — consultas y supresión de datos del titular (US-LEG-02 AC-01, AC-03).
package impl

import (
	"context"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"

	"github.com/siaa/backend/internal/domain/privacidad"
	"github.com/siaa/backend/internal/repository"
	mongoConn "github.com/siaa/backend/internal/repository/mongo"
)

// NewConsentimientoHistorialRepository crea la consulta del historial de consentimientos.
func NewConsentimientoHistorialRepository(client *mongoConn.Client) repository.ConsentimientoHistorialRepository {
	return &consentimientoRepo{col: client.Collection("consentimientos")}
}

// Historial devuelve todas las decisiones del titular, la más reciente primero.
func (r *consentimientoRepo) Historial(ctx context.Context, usuarioID string) ([]*privacidad.Consentimiento, error) {
	opts := options.Find().SetSort(bson.D{{Key: "decididoEn", Value: -1}, {Key: "_id", Value: -1}})
	cur, err := r.col.Find(ctx, bson.M{"usuarioId": usuarioID}, opts)
	if err != nil {
		return nil, fmt.Errorf("historial de consentimientos: %w", err)
	}
	var docs []consentimientoDoc
	if err := cur.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decodificar consentimientos: %w", err)
	}
	res := make([]*privacidad.Consentimiento, 0, len(docs))
	for _, d := range docs {
		res = append(res, &privacidad.Consentimiento{
			ID: d.ID.Hex(), UsuarioID: d.UsuarioID, Version: d.Version, Decision: privacidad.Decision(d.Decision),
			DispositivoID: d.DispositivoID, IPOrigen: d.IPOrigen, DecididoEn: d.DecididoEn,
		})
	}
	return res, nil
}

type supresionTitularRepo struct {
	marcajes, auditoria, tokens, preferencias *mongo.Collection
}

// NewSupresionTitularRepository crea el repositorio que ejecuta la supresión del titular.
func NewSupresionTitularRepository(client *mongoConn.Client) repository.SupresionTitularRepository {
	return &supresionTitularRepo{
		marcajes: client.Collection("marcajes"), auditoria: client.Collection("auditoria"),
		tokens: client.Collection("tokens_push"), preferencias: client.Collection("preferencias_notificacion"),
	}
}

// AnonimizarUbicacionesDe borra las coordenadas de los marcajes del titular, como la retención;
// los protegidos por una investigación en curso no se tocan.
func (r *supresionTitularRepo) AnonimizarUbicacionesDe(ctx context.Context, usuarioID string, excluir privacidad.ExclusionRetencion) (int64, error) {
	delTitular := bson.M{"$or": bson.A{bson.M{"usuarioId": usuarioID}, bson.M{"docenteId": usuarioID}}}
	if cond := condicionesExclusion(excluir); len(cond) > 0 {
		delTitular = bson.M{"$and": bson.A{delTitular, bson.M{"$nor": cond}}}
	}
	ids, err := r.marcajes.Distinct(ctx, "_id", delTitular)
	if err != nil {
		return 0, fmt.Errorf("marcajes del titular: %w", err)
	}
	filtro := bson.M{"$and": bson.A{delTitular, bson.M{"geolocalizacion.coordenadas.0": bson.M{"$exists": true}}}}
	res, err := r.marcajes.UpdateMany(ctx, filtro,
		bson.M{"$set": bson.M{"geolocalizacion.coordenadas": nil, "anonimizadoEn": time.Now().UTC()}})
	if err != nil {
		return 0, fmt.Errorf("anonimizar marcajes del titular: %w", err)
	}
	if len(ids) == 0 {
		return res.ModifiedCount, nil
	}
	for _, campo := range []string{"valorAnterior", "valorNuevo"} {
		ruta := campo + ".geolocalizacion.coordenadas"
		filtroAud := bson.M{"entidad": "marcajes", "entidadId": bson.M{"$in": ids}, ruta + ".0": bson.M{"$exists": true}}
		if _, err := r.auditoria.UpdateMany(ctx, filtroAud, bson.M{"$set": bson.M{ruta: nil}}); err != nil {
			return res.ModifiedCount, fmt.Errorf("anonimizar bitácora del titular: %w", err)
		}
	}
	return res.ModifiedCount, nil
}

// EliminarAvisosDe borra los tokens push y las preferencias de avisos del titular.
func (r *supresionTitularRepo) EliminarAvisosDe(ctx context.Context, usuarioID string) error {
	if _, err := r.tokens.DeleteMany(ctx, bson.M{"usuarioId": usuarioID}); err != nil {
		return fmt.Errorf("eliminar tokens push: %w", err)
	}
	if _, err := r.preferencias.DeleteOne(ctx, bson.M{"_id": usuarioID}); err != nil {
		return fmt.Errorf("eliminar preferencias de avisos: %w", err)
	}
	return nil
}
