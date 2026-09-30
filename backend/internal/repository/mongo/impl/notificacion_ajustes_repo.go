package impl

import (
	"context"
	"errors"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"

	"github.com/siaa/backend/internal/domain/notificacion"
	"github.com/siaa/backend/internal/repository"
	mongoConn "github.com/siaa/backend/internal/repository/mongo"
)

// ─── Tokens push (US-NOT-01 AC-01, AC-03) ───────────────────────────

type tokenPushDoc struct {
	Token         string    `bson:"_id"`
	UsuarioID     string    `bson:"usuarioId"`
	DispositivoID string    `bson:"dispositivoId"`
	Plataforma    string    `bson:"plataforma"`
	ActualizadoEn time.Time `bson:"actualizadoEn"`
}

type tokenPushRepo struct {
	col *mongo.Collection
}

// NewTokenPushRepository crea el repositorio de tokens FCM, con el token como clave.
func NewTokenPushRepository(client *mongoConn.Client) repository.TokenPushRepository {
	return &tokenPushRepo{col: client.Collection("tokens_push")}
}

func (r *tokenPushRepo) Guardar(ctx context.Context, t repository.TokenPush) error {
	_, err := r.col.ReplaceOne(ctx, bson.M{"_id": t.Token}, tokenPushDoc(t), options.Replace().SetUpsert(true))
	if err != nil {
		return fmt.Errorf("guardar token push: %w", err)
	}
	return nil
}

func (r *tokenPushRepo) Eliminar(ctx context.Context, token string) error {
	_, err := r.col.DeleteOne(ctx, bson.M{"_id": token})
	return err
}

func (r *tokenPushRepo) ListarPorUsuario(ctx context.Context, usuarioID string) ([]repository.TokenPush, error) {
	cur, err := r.col.Find(ctx, bson.M{"usuarioId": usuarioID})
	if err != nil {
		return nil, fmt.Errorf("listar tokens push: %w", err)
	}
	var docs []tokenPushDoc
	if err := cur.All(ctx, &docs); err != nil {
		return nil, err
	}
	res := make([]repository.TokenPush, len(docs))
	for i, d := range docs {
		res[i] = repository.TokenPush(d)
	}
	return res, nil
}

// ─── Preferencias (RF-NOT-003) ─────────────────────────────────────

type preferenciasRepo struct {
	col *mongo.Collection
}

// NewPreferenciasRepository crea el repositorio de preferencias de notificación.
func NewPreferenciasRepository(client *mongoConn.Client) repository.PreferenciasRepository {
	return &preferenciasRepo{col: client.Collection("preferencias_notificacion")}
}

func (r *preferenciasRepo) Obtener(ctx context.Context, usuarioID string) (*notificacion.Preferencias, error) {
	var d struct {
		Preferencias notificacion.Preferencias `bson:"preferencias"`
	}
	if err := r.col.FindOne(ctx, bson.M{"_id": usuarioID}).Decode(&d); err != nil {
		if errors.Is(err, mongo.ErrNoDocuments) {
			return nil, nil
		}
		return nil, fmt.Errorf("leer preferencias: %w", err)
	}
	return &d.Preferencias, nil
}

func (r *preferenciasRepo) Guardar(ctx context.Context, usuarioID string, p notificacion.Preferencias) error {
	_, err := r.col.UpdateOne(ctx, bson.M{"_id": usuarioID},
		bson.M{"$set": bson.M{"preferencias": p, "actualizadoEn": time.Now().UTC()}}, options.Update().SetUpsert(true))
	return err
}
