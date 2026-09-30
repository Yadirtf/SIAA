package impl

import (
	"context"
	"fmt"
	"regexp"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"

	"github.com/siaa/backend/internal/repository"
	mongoConn "github.com/siaa/backend/internal/repository/mongo"
)

// auditoriaLectura conserva los valores crudos para convertirlos según su tipo.
type auditoriaLectura struct {
	ID            primitive.ObjectID `bson:"_id"`
	Entidad       string             `bson:"entidad"`
	EntidadID     string             `bson:"entidadId"`
	Accion        string             `bson:"accion"`
	ActorID       string             `bson:"actorId"`
	RolActivo     string             `bson:"rolActivo"`
	CorrelationID string             `bson:"correlationId"`
	IPOrigen      string             `bson:"ipOrigen"`
	AgenteUsuario string             `bson:"agenteUsuario"`
	ValorAnterior bson.RawValue      `bson:"valorAnterior"`
	ValorNuevo    bson.RawValue      `bson:"valorNuevo"`
	CreadoEn      time.Time          `bson:"creadoEn"`
}

// auditoriaConsulta es el acceso de solo lectura a la bitácora (RF-AUD-003).
type auditoriaConsulta struct {
	col *mongo.Collection
}

// NewAuditoriaConsultaRepository crea el lector de la bitácora.
func NewAuditoriaConsultaRepository(client *mongoConn.Client) repository.AuditoriaConsultaRepository {
	return &auditoriaConsulta{col: client.Collection("auditoria")}
}

func (r *auditoriaConsulta) Buscar(ctx context.Context, f repository.FiltroAuditoria, skip, limit int64) ([]*repository.AuditEntry, int64, error) {
	filtro := bson.M{}
	if f.Entidad != "" {
		filtro["entidad"] = f.Entidad
	}
	if f.EntidadID != "" {
		filtro["entidadId"] = f.EntidadID
	}
	if f.ActorID != "" {
		filtro["actorId"] = f.ActorID
	}
	if f.Accion != "" {
		// Prefijo de acción: "JUSTIFICACION_" trae todas las transiciones.
		filtro["accion"] = bson.M{"$regex": "^" + regexp.QuoteMeta(f.Accion)}
	}
	rango := bson.M{}
	if f.Desde != nil {
		rango["$gte"] = *f.Desde
	}
	if f.Hasta != nil {
		rango["$lte"] = *f.Hasta
	}
	if len(rango) > 0 {
		filtro["creadoEn"] = rango
	}

	total, err := r.col.CountDocuments(ctx, filtro)
	if err != nil {
		return nil, 0, fmt.Errorf("contar auditoría: %w", err)
	}
	opts := options.Find().SetSort(bson.D{{Key: "creadoEn", Value: -1}, {Key: "_id", Value: -1}}).SetSkip(skip).SetLimit(limit)
	cur, err := r.col.Find(ctx, filtro, opts)
	if err != nil {
		return nil, 0, fmt.Errorf("consultar auditoría: %w", err)
	}
	var docs []auditoriaLectura
	if err := cur.All(ctx, &docs); err != nil {
		return nil, 0, fmt.Errorf("decodificar auditoría: %w", err)
	}
	res := make([]*repository.AuditEntry, len(docs))
	for i, d := range docs {
		res[i] = &repository.AuditEntry{
			ID: d.ID.Hex(), Entidad: d.Entidad, EntidadID: d.EntidadID, Accion: d.Accion,
			ActorID: d.ActorID, RolActivo: d.RolActivo, CorrelationID: d.CorrelationID,
			IPOrigen: d.IPOrigen, AgenteUsuario: d.AgenteUsuario,
			ValorAnterior: valorOpcional(d.ValorAnterior), ValorNuevo: valorOpcional(d.ValorNuevo), CreadoEn: d.CreadoEn,
		}
	}
	return res, total, nil
}

// valorOpcional convierte el valor guardado (documento, texto u otro) a un tipo que se
// serializa como JSON legible; los documentos anidados quedan como mapas.
func valorOpcional(v bson.RawValue) interface{} {
	if v.Type == 0 || v.Type == bson.TypeNull {
		return nil
	}
	if v.Type == bson.TypeEmbeddedDocument {
		var m bson.M
		if err := v.Unmarshal(&m); err == nil {
			return m
		}
	}
	var x interface{}
	if err := v.Unmarshal(&x); err != nil {
		return v.String()
	}
	return x
}
