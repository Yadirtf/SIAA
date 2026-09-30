// Package impl — repositorio MongoDB para recovery tokens.
package impl

import (
	"context"
	"errors"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"

	"github.com/siaa/backend/internal/repository"
	mongoConn "github.com/siaa/backend/internal/repository/mongo"
)

// ─── Documento BSON ──────────────────────────────────────────

type recoveryTokenDoc struct {
	ID        primitive.ObjectID `bson:"_id,omitempty"`
	UsuarioID string             `bson:"usuarioId"`
	TokenHash string             `bson:"tokenHash"`
	ExpiraEn  time.Time          `bson:"expiraEn"`
	Usado     bool               `bson:"usado"`
	CreadoEn  time.Time          `bson:"creadoEn"`
}

// ─── Repositorio ─────────────────────────────────────────────

type recoveryTokenRepository struct {
	col *mongo.Collection
}

// NewRecoveryTokenRepository crea la implementación MongoDB de RecoveryTokenRepository.
func NewRecoveryTokenRepository(client *mongoConn.Client) repository.RecoveryTokenRepository {
	return &recoveryTokenRepository{col: client.Collection("recovery_tokens")}
}

func (r *recoveryTokenRepository) Create(ctx context.Context, t *repository.RecoveryToken) error {
	doc := &recoveryTokenDoc{
		UsuarioID: t.UsuarioID,
		TokenHash: t.TokenHash,
		ExpiraEn:  t.ExpiraEn,
		Usado:     false,
		CreadoEn:  t.CreadoEn,
	}
	result, err := r.col.InsertOne(ctx, doc)
	if err != nil {
		return fmt.Errorf("create recovery token: %w", err)
	}
	t.ID = result.InsertedID.(primitive.ObjectID).Hex()
	return nil
}

func (r *recoveryTokenRepository) FindByHash(ctx context.Context, hash string) (*repository.RecoveryToken, error) {
	var doc recoveryTokenDoc
	filter := bson.D{
		{Key: "tokenHash", Value: hash},
		{Key: "usado", Value: false},
	}
	err := r.col.FindOne(ctx, filter).Decode(&doc)
	if errors.Is(err, mongo.ErrNoDocuments) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &repository.RecoveryToken{
		ID:        doc.ID.Hex(),
		UsuarioID: doc.UsuarioID,
		TokenHash: doc.TokenHash,
		ExpiraEn:  doc.ExpiraEn,
		Usado:     doc.Usado,
		CreadoEn:  doc.CreadoEn,
	}, nil
}

func (r *recoveryTokenRepository) MarkUsed(ctx context.Context, id string) error {
	oid, _ := primitive.ObjectIDFromHex(id)
	_, err := r.col.UpdateByID(ctx, oid,
		bson.D{{Key: "$set", Value: bson.D{{Key: "usado", Value: true}}}},
	)
	return err
}
