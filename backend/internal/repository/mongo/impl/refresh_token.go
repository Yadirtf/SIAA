// Package impl — repositorio MongoDB para refresh tokens.
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

type refreshTokenDoc struct {
	ID          primitive.ObjectID `bson:"_id,omitempty"`
	UsuarioID   string             `bson:"usuarioId"`
	TokenHash   string             `bson:"tokenHash"`
	FamiliaID   string             `bson:"familiaId"`
	ExpiraEn    time.Time          `bson:"expiraEn"`
	Revocado    bool               `bson:"revocado"`
	Dispositivo string             `bson:"dispositivo"`
	CreadoEn    time.Time          `bson:"creadoEn"`
}

// ─── Repositorio ─────────────────────────────────────────────

type refreshTokenRepository struct {
	col *mongo.Collection
}

// NewRefreshTokenRepository crea la implementación MongoDB de RefreshTokenRepository.
func NewRefreshTokenRepository(client *mongoConn.Client) repository.RefreshTokenRepository {
	return &refreshTokenRepository{col: client.Collection("refresh_tokens")}
}

func (r *refreshTokenRepository) Create(ctx context.Context, t *repository.RefreshToken) error {
	doc := &refreshTokenDoc{
		UsuarioID:   t.UsuarioID,
		TokenHash:   t.TokenHash,
		FamiliaID:   t.FamiliaID,
		ExpiraEn:    t.ExpiraEn,
		Revocado:    false,
		Dispositivo: t.Dispositivo,
		CreadoEn:    t.CreadoEn,
	}
	result, err := r.col.InsertOne(ctx, doc)
	if err != nil {
		return fmt.Errorf("create refresh token: %w", err)
	}
	t.ID = result.InsertedID.(primitive.ObjectID).Hex()
	return nil
}

func (r *refreshTokenRepository) FindByHash(ctx context.Context, hash string) (*repository.RefreshToken, error) {
	var doc refreshTokenDoc
	err := r.col.FindOne(ctx, bson.D{{Key: "tokenHash", Value: hash}}).Decode(&doc)
	if errors.Is(err, mongo.ErrNoDocuments) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &repository.RefreshToken{
		ID:          doc.ID.Hex(),
		UsuarioID:   doc.UsuarioID,
		TokenHash:   doc.TokenHash,
		FamiliaID:   doc.FamiliaID,
		ExpiraEn:    doc.ExpiraEn,
		Revocado:    doc.Revocado,
		Dispositivo: doc.Dispositivo,
		CreadoEn:    doc.CreadoEn,
	}, nil
}

func (r *refreshTokenRepository) RevokeByID(ctx context.Context, id string) error {
	oid, _ := primitive.ObjectIDFromHex(id)
	_, err := r.col.UpdateByID(ctx, oid,
		bson.D{{Key: "$set", Value: bson.D{{Key: "revocado", Value: true}}}},
	)
	return err
}

func (r *refreshTokenRepository) RevokeByFamilia(ctx context.Context, familiaID string) error {
	_, err := r.col.UpdateMany(ctx,
		bson.D{{Key: "familiaId", Value: familiaID}},
		bson.D{{Key: "$set", Value: bson.D{{Key: "revocado", Value: true}}}},
	)
	return err
}

func (r *refreshTokenRepository) RevokeByUsuario(ctx context.Context, usuarioID string) error {
	_, err := r.col.UpdateMany(ctx,
		bson.D{{Key: "usuarioId", Value: usuarioID}},
		bson.D{{Key: "$set", Value: bson.D{{Key: "revocado", Value: true}}}},
	)
	return err
}
