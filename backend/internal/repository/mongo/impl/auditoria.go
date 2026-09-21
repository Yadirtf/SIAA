// Package impl — repositorio MongoDB para la bitácora de auditoría.
package impl

import (
	"context"
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"

	mongoConn "github.com/siaa/backend/internal/repository/mongo"
	"github.com/siaa/backend/internal/repository"
)

// ─── Documento BSON ──────────────────────────────────────────

type auditoriaDoc struct {
	ID            primitive.ObjectID `bson:"_id,omitempty"`
	Entidad       string             `bson:"entidad"`
	EntidadID     string             `bson:"entidadId"`
	Accion        string             `bson:"accion"`
	ActorID       string             `bson:"actorId"`
	RolActivo     string             `bson:"rolActivo,omitempty"`
	CorrelationID string             `bson:"correlationId,omitempty"`
	IPOrigen      string             `bson:"ipOrigen,omitempty"`
	AgenteUsuario string             `bson:"agenteUsuario,omitempty"`
	ValorAnterior interface{}        `bson:"valorAnterior,omitempty"`
	ValorNuevo    interface{}        `bson:"valorNuevo,omitempty"`
	CreadoEn      time.Time          `bson:"creadoEn"`
}

// ─── Repositorio ─────────────────────────────────────────────

type auditoriaRepository struct {
	col *mongo.Collection
}

// NewAuditoriaRepository crea la implementación MongoDB de AuditoriaRepository.
func NewAuditoriaRepository(client *mongoConn.Client) repository.AuditoriaRepository {
	return &auditoriaRepository{col: client.Collection("auditoria")}
}

func (r *auditoriaRepository) Create(ctx context.Context, e *repository.AuditEntry) error {
	doc := &auditoriaDoc{
		Entidad:       e.Entidad,
		EntidadID:     e.EntidadID,
		Accion:        e.Accion,
		ActorID:       e.ActorID,
		RolActivo:     e.RolActivo,
		CorrelationID: e.CorrelationID,
		IPOrigen:      e.IPOrigen,
		AgenteUsuario: e.AgenteUsuario,
		ValorAnterior: e.ValorAnterior,
		ValorNuevo:    e.ValorNuevo,
		CreadoEn:      e.CreadoEn,
	}
	_, err := r.col.InsertOne(ctx, doc, options.InsertOne())
	return err
}
