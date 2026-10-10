// Package impl — repositorio MongoDB de investigaciones que suspenden la retención (US-AUD-04 AC-03).
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

type investigacionDoc struct {
	ID          primitive.ObjectID `bson:"_id,omitempty"`
	Alcance     string             `bson:"alcance"`
	ObjetivoID  string             `bson:"objetivoId"`
	Motivo      string             `bson:"motivo"`
	CreadaPor   string             `bson:"creadaPor"`
	CreadaEn    time.Time          `bson:"creadaEn"`
	LiberadaPor string             `bson:"liberadaPor,omitempty"`
	LiberadaEn  *time.Time         `bson:"liberadaEn,omitempty"`
}

func (d investigacionDoc) aDominio() *privacidad.Investigacion {
	return &privacidad.Investigacion{
		ID: d.ID.Hex(), Alcance: privacidad.AlcanceInvestigacion(d.Alcance), ObjetivoID: d.ObjetivoID,
		Motivo: d.Motivo, CreadaPor: d.CreadaPor, CreadaEn: d.CreadaEn,
		LiberadaPor: d.LiberadaPor, LiberadaEn: d.LiberadaEn,
	}
}

type investigacionRepo struct {
	col *mongo.Collection
}

// NewInvestigacionRepository crea el repositorio de la colección investigaciones_retencion.
func NewInvestigacionRepository(client *mongoConn.Client) repository.InvestigacionRepository {
	return &investigacionRepo{col: client.Collection("investigaciones_retencion")}
}

func (r *investigacionRepo) Crear(ctx context.Context, i *privacidad.Investigacion) error {
	res, err := r.col.InsertOne(ctx, investigacionDoc{
		Alcance: string(i.Alcance), ObjetivoID: i.ObjetivoID, Motivo: i.Motivo,
		CreadaPor: i.CreadaPor, CreadaEn: i.CreadaEn,
	})
	if err != nil {
		return fmt.Errorf("crear investigación: %w", err)
	}
	if oid, ok := res.InsertedID.(primitive.ObjectID); ok {
		i.ID = oid.Hex()
	}
	return nil
}

func (r *investigacionRepo) Obtener(ctx context.Context, id string) (*privacidad.Investigacion, error) {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, nil
	}
	var d investigacionDoc
	if err := r.col.FindOne(ctx, bson.M{"_id": oid}).Decode(&d); err != nil {
		if errors.Is(err, mongo.ErrNoDocuments) {
			return nil, nil
		}
		return nil, fmt.Errorf("leer investigación: %w", err)
	}
	return d.aDominio(), nil
}

func (r *investigacionRepo) Activas(ctx context.Context) ([]*privacidad.Investigacion, error) {
	cur, err := r.col.Find(ctx, bson.M{"liberadaEn": bson.M{"$exists": false}},
		options.Find().SetSort(bson.D{{Key: "creadaEn", Value: -1}}))
	if err != nil {
		return nil, fmt.Errorf("listar investigaciones: %w", err)
	}
	var docs []investigacionDoc
	if err := cur.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("leer investigaciones: %w", err)
	}
	out := make([]*privacidad.Investigacion, 0, len(docs))
	for _, d := range docs {
		out = append(out, d.aDominio())
	}
	return out, nil
}

// Liberar solo cierra una investigación que siga activa (evita dos cierres concurrentes).
func (r *investigacionRepo) Liberar(ctx context.Context, i *privacidad.Investigacion) error {
	oid, err := primitive.ObjectIDFromHex(i.ID)
	if err != nil {
		return fmt.Errorf("id de investigación inválido: %w", err)
	}
	res, err := r.col.UpdateOne(ctx, bson.M{"_id": oid, "liberadaEn": bson.M{"$exists": false}},
		bson.M{"$set": bson.M{"liberadaEn": i.LiberadaEn, "liberadaPor": i.LiberadaPor}})
	if err != nil {
		return fmt.Errorf("liberar investigación: %w", err)
	}
	if res.MatchedCount == 0 {
		return errors.New("la investigación ya no está activa")
	}
	return nil
}
