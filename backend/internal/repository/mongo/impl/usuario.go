// Package impl — repositorio MongoDB para usuarios.
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

	"github.com/siaa/backend/internal/domain/user"
	"github.com/siaa/backend/internal/repository"
	mongoConn "github.com/siaa/backend/internal/repository/mongo"
)

// ─── Repositorio ─────────────────────────────────────────────

type usuarioRepository struct {
	col *mongo.Collection
}

// NewUsuarioRepository crea la implementación MongoDB de UsuarioRepository.
func NewUsuarioRepository(client *mongoConn.Client) repository.UsuarioRepository {
	return &usuarioRepository{col: client.Collection("usuarios")}
}

func (r *usuarioRepository) FindByCorreo(ctx context.Context, correo string) (*user.Usuario, error) {
	var doc usuarioDoc
	err := r.col.FindOne(ctx, bson.D{
		{Key: "correo", Value: correo},
		{Key: "eliminado", Value: false},
	}).Decode(&doc)
	if errors.Is(err, mongo.ErrNoDocuments) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("findByCorreo: %w", err)
	}
	return docToUsuario(&doc), nil
}

func (r *usuarioRepository) FindByID(ctx context.Context, id string) (*user.Usuario, error) {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, nil
	}
	var doc usuarioDoc
	err = r.col.FindOne(ctx, bson.D{{Key: "_id", Value: oid}}).Decode(&doc)
	if errors.Is(err, mongo.ErrNoDocuments) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("findById: %w", err)
	}
	return docToUsuario(&doc), nil
}

func (r *usuarioRepository) UpdateIntentosFallidos(ctx context.Context, id string, intentos int, bloqueadoHasta *time.Time, ultimoFalloEn *time.Time) error {
	oid, _ := primitive.ObjectIDFromHex(id)
	update := bson.D{{Key: "$set", Value: bson.D{
		{Key: "intentosFallidos", Value: intentos},
		{Key: "bloqueadoHasta", Value: bloqueadoHasta},
		{Key: "ultimoFalloEn", Value: ultimoFalloEn},
		{Key: "actualizadoEn", Value: time.Now().UTC()},
	}}}
	_, err := r.col.UpdateByID(ctx, oid, update)
	return err
}

func (r *usuarioRepository) ResetIntentosFallidos(ctx context.Context, id string) error {
	oid, _ := primitive.ObjectIDFromHex(id)
	update := bson.D{{Key: "$set", Value: bson.D{
		{Key: "intentosFallidos", Value: 0},
		{Key: "bloqueadoHasta", Value: nil},
		{Key: "ultimoFalloEn", Value: nil},
		{Key: "actualizadoEn", Value: time.Now().UTC()},
	}}}
	_, err := r.col.UpdateByID(ctx, oid, update)
	return err
}

func (r *usuarioRepository) UpdatePassword(ctx context.Context, id, passwordHash string) error {
	oid, _ := primitive.ObjectIDFromHex(id)
	update := bson.D{{Key: "$set", Value: bson.D{
		{Key: "passwordHash", Value: passwordHash},
		{Key: "actualizadoEn", Value: time.Now().UTC()},
	}}}
	_, err := r.col.UpdateByID(ctx, oid, update)
	return err
}

func (r *usuarioRepository) Create(ctx context.Context, u *user.Usuario) error {
	doc := usuarioToDoc(u)
	result, err := r.col.InsertOne(ctx, doc)
	if err != nil {
		return fmt.Errorf("create usuario: %w", err)
	}
	u.ID = result.InsertedID.(primitive.ObjectID).Hex()
	return nil
}

func (r *usuarioRepository) Update(ctx context.Context, u *user.Usuario) error {
	oid, _ := primitive.ObjectIDFromHex(u.ID)
	doc := usuarioToDoc(u)
	doc.ActualizadoEn = time.Now().UTC()
	_, err := r.col.ReplaceOne(ctx, bson.D{{Key: "_id", Value: oid}}, doc)
	return err
}

func (r *usuarioRepository) Listar(ctx context.Context, limite int) ([]*user.Usuario, error) {
	findOpts := options.Find().SetSort(bson.D{{Key: "nombre", Value: 1}})
	if limite > 0 {
		findOpts.SetLimit(int64(limite))
	}
	cursor, err := r.col.Find(ctx, bson.D{{Key: "eliminado", Value: false}}, findOpts)
	if err != nil {
		return nil, fmt.Errorf("listar usuarios: %w", err)
	}
	defer cursor.Close(ctx)

	var docs []usuarioDoc
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decodificar usuarios: %w", err)
	}

	usuarios := make([]*user.Usuario, len(docs))
	for i := range docs {
		usuarios[i] = docToUsuario(&docs[i])
	}
	return usuarios, nil
}
