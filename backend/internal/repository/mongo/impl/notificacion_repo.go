package impl

import (
	"context"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"

	"github.com/siaa/backend/internal/domain/notificacion"
	"github.com/siaa/backend/internal/repository"
	mongoConn "github.com/siaa/backend/internal/repository/mongo"
)

type notificacionDoc struct {
	ID             primitive.ObjectID `bson:"_id,omitempty"`
	UsuarioID      string             `bson:"usuarioId"`
	Tipo           string             `bson:"tipo"`
	Titulo         string             `bson:"titulo"`
	Cuerpo         string             `bson:"cuerpo"`
	Datos          map[string]string  `bson:"datos,omitempty"`
	ClaveDedupe    string             `bson:"claveDedupe"`
	Estado         string             `bson:"estado"`
	Canal          string             `bson:"canal,omitempty"`
	Intentos       int                `bson:"intentos"`
	UltimoError    string             `bson:"ultimoError,omitempty"`
	Leida          bool               `bson:"leida"`
	ProgramadaPara time.Time          `bson:"programadaPara"`
	VenceEn        *time.Time         `bson:"venceEn,omitempty"`
	EnviadaEn      *time.Time         `bson:"enviadaEn,omitempty"`
	CreadaEn       time.Time          `bson:"creadaEn"`
}

func (d *notificacionDoc) aDominio() *notificacion.Notificacion {
	return &notificacion.Notificacion{
		ID: d.ID.Hex(), UsuarioID: d.UsuarioID, Tipo: notificacion.Tipo(d.Tipo), Titulo: d.Titulo, Cuerpo: d.Cuerpo,
		Datos: d.Datos, ClaveDedupe: d.ClaveDedupe, Estado: notificacion.Estado(d.Estado), Canal: d.Canal,
		Intentos: d.Intentos, UltimoError: d.UltimoError, Leida: d.Leida, ProgramadaPara: d.ProgramadaPara,
		VenceEn: d.VenceEn, EnviadaEn: d.EnviadaEn, CreadaEn: d.CreadaEn,
	}
}

type notificacionRepo struct {
	col *mongo.Collection
}

// NewNotificacionRepository crea la cola de avisos y bandeja de usuarios (EP-10).
func NewNotificacionRepository(client *mongoConn.Client) repository.NotificacionRepository {
	return &notificacionRepo{col: client.Collection("notificaciones")}
}

func (r *notificacionRepo) Encolar(ctx context.Context, n *notificacion.Notificacion) (bool, error) {
	if n.CreadaEn.IsZero() {
		n.CreadaEn = time.Now().UTC()
	}
	if n.Estado == "" {
		n.Estado = notificacion.EstadoPendiente
	}
	res, err := r.col.InsertOne(ctx, notificacionDoc{
		UsuarioID: n.UsuarioID, Tipo: string(n.Tipo), Titulo: n.Titulo, Cuerpo: n.Cuerpo, Datos: n.Datos,
		ClaveDedupe: n.ClaveDedupe, Estado: string(n.Estado), ProgramadaPara: n.ProgramadaPara,
		VenceEn: n.VenceEn, CreadaEn: n.CreadaEn,
	})
	if mongo.IsDuplicateKeyError(err) {
		return false, nil
	}
	if err != nil {
		return false, fmt.Errorf("encolar notificación: %w", err)
	}
	if oid, ok := res.InsertedID.(primitive.ObjectID); ok {
		n.ID = oid.Hex()
	}
	return true, nil
}

func (r *notificacionRepo) Pendientes(ctx context.Context, hasta time.Time, limite int) ([]*notificacion.Notificacion, error) {
	opts := options.Find().SetSort(bson.D{{Key: "programadaPara", Value: 1}}).SetLimit(int64(limite))
	return r.buscar(ctx, bson.M{"estado": notificacion.EstadoPendiente, "programadaPara": bson.M{"$lte": hasta}}, opts)
}

func (r *notificacionRepo) Bandeja(ctx context.Context, usuarioID string, limite int) ([]*notificacion.Notificacion, error) {
	opts := options.Find().SetSort(bson.D{{Key: "creadaEn", Value: -1}}).SetLimit(int64(limite))
	return r.buscar(ctx, bson.M{
		"usuarioId": usuarioID,
		"estado":    bson.M{"$in": []notificacion.Estado{notificacion.EstadoEnviada, notificacion.EstadoSinCanal, notificacion.EstadoFallida}},
	}, opts)
}

func (r *notificacionRepo) buscar(ctx context.Context, filtro bson.M, opts *options.FindOptions) ([]*notificacion.Notificacion, error) {
	cur, err := r.col.Find(ctx, filtro, opts)
	if err != nil {
		return nil, fmt.Errorf("consultar notificaciones: %w", err)
	}
	var docs []notificacionDoc
	if err := cur.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decodificar notificaciones: %w", err)
	}
	res := make([]*notificacion.Notificacion, len(docs))
	for i := range docs {
		res[i] = docs[i].aDominio()
	}
	return res, nil
}

func (r *notificacionRepo) Actualizar(ctx context.Context, n *notificacion.Notificacion) error {
	oid, err := primitive.ObjectIDFromHex(n.ID)
	if err != nil {
		return fmt.Errorf("id de notificación inválido: %w", err)
	}
	_, err = r.col.UpdateByID(ctx, oid, bson.M{"$set": bson.M{
		"estado": n.Estado, "canal": n.Canal, "intentos": n.Intentos, "ultimoError": n.UltimoError,
		"programadaPara": n.ProgramadaPara, "enviadaEn": n.EnviadaEn,
	}})
	return err
}

func (r *notificacionRepo) MarcarLeida(ctx context.Context, id, usuarioID string) (bool, error) {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return false, nil
	}
	res, err := r.col.UpdateOne(ctx, bson.M{"_id": oid, "usuarioId": usuarioID}, bson.M{"$set": bson.M{"leida": true}})
	if err != nil {
		return false, err
	}
	return res.MatchedCount == 1, nil
}
