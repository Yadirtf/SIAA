package impl

import (
	"context"
	"errors"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"

	"github.com/siaa/backend/internal/platform/security"
	"github.com/siaa/backend/internal/repository"
	mongoConn "github.com/siaa/backend/internal/repository/mongo"
)

// adjuntoRepo guarda los soportes cifrados con AES-GCM; MongoDB nunca ve el contenido plano.
type adjuntoRepo struct {
	col      *mongo.Collection
	cifrador *security.Cifrador
}

type adjuntoDoc struct {
	ID        string    `bson:"_id"`
	Contenido []byte    `bson:"contenido"`
	CreadoEn  time.Time `bson:"creadoEn"`
}

// NewAdjuntoRepository crea el almacén cifrado de soportes (límite de 16 MB por documento).
func NewAdjuntoRepository(client *mongoConn.Client, cifrador *security.Cifrador) repository.AdjuntoRepository {
	return &adjuntoRepo{col: client.Collection("justificacion_adjuntos"), cifrador: cifrador}
}

func (r *adjuntoRepo) Guardar(ctx context.Context, id string, contenido []byte) error {
	cifrado, err := r.cifrador.Cifrar(contenido)
	if err != nil {
		return err
	}
	if _, err := r.col.InsertOne(ctx, adjuntoDoc{ID: id, Contenido: cifrado, CreadoEn: time.Now().UTC()}); err != nil {
		return fmt.Errorf("guardar adjunto: %w", err)
	}
	return nil
}

func (r *adjuntoRepo) Obtener(ctx context.Context, id string) ([]byte, error) {
	var doc adjuntoDoc
	if err := r.col.FindOne(ctx, bson.M{"_id": id}).Decode(&doc); err != nil {
		if errors.Is(err, mongo.ErrNoDocuments) {
			return nil, nil
		}
		return nil, fmt.Errorf("obtener adjunto: %w", err)
	}
	return r.cifrador.Descifrar(doc.Contenido)
}
