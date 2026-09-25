// Package impl — repositorio MongoDB para dispositivos vinculados (US-AUT-03).
package impl

import (
	"context"
	"errors"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"

	"github.com/siaa/backend/internal/domain/user"
	"github.com/siaa/backend/internal/repository"
	mongoConn "github.com/siaa/backend/internal/repository/mongo"
)

type dispositivoDoc struct {
	ID                  string     `bson:"_id"`
	UsuarioID           string     `bson:"usuarioId"`
	InstalacionID       string     `bson:"instalacionId"`
	Modelo              string     `bson:"modelo"`
	SO                  string     `bson:"so"`
	VersionApp          string     `bson:"versionApp"`
	Confiable           bool       `bson:"confiable"`
	PendienteAprobacion bool       `bson:"pendienteAprobacion"`
	CreadoEn            time.Time  `bson:"creadoEn"`
	ActualizadoEn       time.Time  `bson:"actualizadoEn"`
	RevocadoEn          *time.Time `bson:"revocadoEn,omitempty"`
}

func toDispositivoDoc(d *user.Dispositivo) *dispositivoDoc {
	return &dispositivoDoc{
		ID:                  d.ID,
		UsuarioID:           d.UsuarioID,
		InstalacionID:       d.InstalacionID,
		Modelo:              d.Modelo,
		SO:                  d.SO,
		VersionApp:          d.VersionApp,
		Confiable:           d.Confiable,
		PendienteAprobacion: d.PendienteAprobacion,
		CreadoEn:            d.CreadoEn,
		ActualizadoEn:       d.ActualizadoEn,
		RevocadoEn:          d.RevocadoEn,
	}
}

func fromDispositivoDoc(doc *dispositivoDoc) *user.Dispositivo {
	if doc == nil {
		return nil
	}
	return &user.Dispositivo{
		ID:                  doc.ID,
		UsuarioID:           doc.UsuarioID,
		InstalacionID:       doc.InstalacionID,
		Modelo:              doc.Modelo,
		SO:                  doc.SO,
		VersionApp:          doc.VersionApp,
		Confiable:           doc.Confiable,
		PendienteAprobacion: doc.PendienteAprobacion,
		CreadoEn:            doc.CreadoEn,
		ActualizadoEn:       doc.ActualizadoEn,
		RevocadoEn:          doc.RevocadoEn,
	}
}

type dispositivoRepository struct {
	col *mongo.Collection
}

// NewDispositivoRepository crea una nueva instancia del repositorio MongoDB de dispositivos.
func NewDispositivoRepository(client *mongoConn.Client) repository.DispositivoRepository {
	return &dispositivoRepository{col: client.Collection("dispositivos")}
}

func (r *dispositivoRepository) FindByID(ctx context.Context, id string) (*user.Dispositivo, error) {
	var doc dispositivoDoc
	err := r.col.FindOne(ctx, bson.M{"_id": id}).Decode(&doc)
	if err != nil {
		if errors.Is(err, mongo.ErrNoDocuments) {
			return nil, nil
		}
		return nil, fmt.Errorf("dispositivoRepo.FindByID: %w", err)
	}
	return fromDispositivoDoc(&doc), nil
}

func (r *dispositivoRepository) FindByInstalacion(ctx context.Context, usuarioID, instalacionID string) (*user.Dispositivo, error) {
	var doc dispositivoDoc
	filter := bson.M{
		"usuarioId":     usuarioID,
		"instalacionId": instalacionID,
	}
	err := r.col.FindOne(ctx, filter).Decode(&doc)
	if err != nil {
		if errors.Is(err, mongo.ErrNoDocuments) {
			return nil, nil
		}
		return nil, fmt.Errorf("dispositivoRepo.FindByInstalacion: %w", err)
	}
	return fromDispositivoDoc(&doc), nil
}

func (r *dispositivoRepository) Create(ctx context.Context, d *user.Dispositivo) error {
	doc := toDispositivoDoc(d)
	_, err := r.col.InsertOne(ctx, doc)
	if err != nil {
		return fmt.Errorf("dispositivoRepo.Create: %w", err)
	}
	return nil
}

func (r *dispositivoRepository) FindByUsuario(ctx context.Context, usuarioID string) ([]*user.Dispositivo, error) {
	opts := options.Find().SetSort(bson.D{{Key: "creadoEn", Value: -1}})
	cursor, err := r.col.Find(ctx, bson.M{"usuarioId": usuarioID}, opts)
	if err != nil {
		return nil, fmt.Errorf("dispositivoRepo.FindByUsuario: %w", err)
	}
	defer cursor.Close(ctx)

	var docs []dispositivoDoc
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("dispositivoRepo.FindByUsuario.Decode: %w", err)
	}

	result := make([]*user.Dispositivo, len(docs))
	for i := range docs {
		result[i] = fromDispositivoDoc(&docs[i])
	}
	return result, nil
}

func (r *dispositivoRepository) FindRecentByInstalacion(ctx context.Context, instalacionID string, desde time.Time) ([]*user.Dispositivo, error) {
	filter := bson.M{
		"instalacionId": instalacionID,
		"creadoEn":      bson.M{"$gte": desde},
	}
	cursor, err := r.col.Find(ctx, filter)
	if err != nil {
		return nil, fmt.Errorf("dispositivoRepo.FindRecentByInstalacion: %w", err)
	}
	defer cursor.Close(ctx)

	var docs []dispositivoDoc
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("dispositivoRepo.FindRecentByInstalacion.Decode: %w", err)
	}

	result := make([]*user.Dispositivo, len(docs))
	for i := range docs {
		result[i] = fromDispositivoDoc(&docs[i])
	}
	return result, nil
}

func (r *dispositivoRepository) Update(ctx context.Context, d *user.Dispositivo) error {
	doc := toDispositivoDoc(d)
	filter := bson.M{"_id": d.ID}
	_, err := r.col.ReplaceOne(ctx, filter, doc)
	if err != nil {
		return fmt.Errorf("dispositivoRepo.Update: %w", err)
	}
	return nil
}
