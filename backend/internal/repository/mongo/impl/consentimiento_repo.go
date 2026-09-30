package impl

import (
	"context"
	"errors"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"

	"github.com/siaa/backend/internal/domain/privacidad"
	"github.com/siaa/backend/internal/repository"
	mongoConn "github.com/siaa/backend/internal/repository/mongo"
)

type consentimientoDoc struct {
	ID            primitive.ObjectID `bson:"_id,omitempty"`
	UsuarioID     string             `bson:"usuarioId"`
	Version       string             `bson:"version"`
	Decision      string             `bson:"decision"`
	DispositivoID string             `bson:"dispositivoId,omitempty"`
	IPOrigen      string             `bson:"ipOrigen,omitempty"`
	DecididoEn    time.Time          `bson:"decididoEn"`
}

type consentimientoRepo struct {
	col *mongo.Collection
}

// NewConsentimientoRepository crea el repositorio de decisiones de consentimiento (US-LEG-01).
func NewConsentimientoRepository(client *mongoConn.Client) repository.ConsentimientoRepository {
	return &consentimientoRepo{col: client.Collection("consentimientos")}
}

func (r *consentimientoRepo) Registrar(ctx context.Context, c *privacidad.Consentimiento) error {
	res, err := r.col.InsertOne(ctx, consentimientoDoc{
		UsuarioID: c.UsuarioID, Version: c.Version, Decision: string(c.Decision),
		DispositivoID: c.DispositivoID, IPOrigen: c.IPOrigen, DecididoEn: c.DecididoEn,
	})
	if err != nil {
		return fmt.Errorf("registrar consentimiento: %w", err)
	}
	if oid, ok := res.InsertedID.(primitive.ObjectID); ok {
		c.ID = oid.Hex()
	}
	return nil
}

func (r *consentimientoRepo) Ultimo(ctx context.Context, usuarioID string) (*privacidad.Consentimiento, error) {
	var d consentimientoDoc
	opts := options.FindOne().SetSort(bson.D{{Key: "decididoEn", Value: -1}, {Key: "_id", Value: -1}})
	if err := r.col.FindOne(ctx, bson.M{"usuarioId": usuarioID}, opts).Decode(&d); err != nil {
		if errors.Is(err, mongo.ErrNoDocuments) {
			return nil, nil
		}
		return nil, fmt.Errorf("leer consentimiento: %w", err)
	}
	return &privacidad.Consentimiento{
		ID: d.ID.Hex(), UsuarioID: d.UsuarioID, Version: d.Version, Decision: privacidad.Decision(d.Decision),
		DispositivoID: d.DispositivoID, IPOrigen: d.IPOrigen, DecididoEn: d.DecididoEn,
	}, nil
}
