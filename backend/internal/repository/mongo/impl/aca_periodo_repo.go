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

	domainAca "github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/repository"
	mongoConn "github.com/siaa/backend/internal/repository/mongo"
)

type periodoDoc struct {
	ID            primitive.ObjectID      `bson:"_id,omitempty"`
	Codigo        string                  `bson:"codigo"`
	Nombre        string                  `bson:"nombre"`
	FechaInicio   time.Time               `bson:"fechaInicio"`
	FechaFin      time.Time               `bson:"fechaFin"`
	Estado        domainAca.EstadoPeriodo `bson:"estado"`
	SedeID        string                  `bson:"sedeId,omitempty"`
	CodigoExterno *string                 `bson:"codigoExterno,omitempty"`
	Borrado       bool                    `bson:"borrado"`
	CreadoEn      time.Time               `bson:"creadoEn"`
	ActualizadoEn time.Time               `bson:"actualizadoEn"`
}

type periodoRepository struct {
	col *mongo.Collection
}

func NewPeriodoRepository(client *mongoConn.Client) repository.PeriodoRepository {
	return &periodoRepository{col: client.Collection("periodos")}
}

func (r *periodoRepository) Create(ctx context.Context, p *domainAca.Periodo) error {
	doc := periodoDoc{
		Codigo:        p.Codigo(),
		Nombre:        p.Nombre(),
		FechaInicio:   p.FechaInicio(),
		FechaFin:      p.FechaFin(),
		Estado:        p.Estado(),
		SedeID:        p.SedeID(),
		CodigoExterno: p.CodigoExterno(),
		Borrado:       false,
		CreadoEn:      p.CreadoEn(),
		ActualizadoEn: p.ActualizadoEn(),
	}
	if p.ID() != "" {
		if oid, err := primitive.ObjectIDFromHex(p.ID()); err == nil {
			doc.ID = oid
		}
	}
	_, err := r.col.InsertOne(ctx, doc)
	if err != nil {
		return fmt.Errorf("create periodo: %w", err)
	}
	return nil
}

func (r *periodoRepository) Update(ctx context.Context, p *domainAca.Periodo) error {
	oid, err := primitive.ObjectIDFromHex(p.ID())
	if err != nil {
		return fmt.Errorf("id de periodo inválido: %w", err)
	}
	update := bson.M{
		"$set": bson.M{
			"codigo":        p.Codigo(),
			"nombre":        p.Nombre(),
			"fechaInicio":   p.FechaInicio(),
			"fechaFin":      p.FechaFin(),
			"estado":        p.Estado(),
			"sedeId":        p.SedeID(),
			"codigoExterno": p.CodigoExterno(),
			"borrado":       p.Borrado(),
			"actualizadoEn": p.ActualizadoEn(),
		},
	}
	res, err := r.col.UpdateOne(ctx, bson.M{"_id": oid}, update)
	if err != nil {
		return fmt.Errorf("update periodo: %w", err)
	}
	if res.MatchedCount == 0 {
		return errors.New("periodo no encontrado")
	}
	return nil
}

func (r *periodoRepository) GetByID(ctx context.Context, id string) (*domainAca.Periodo, error) {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, fmt.Errorf("id de periodo inválido: %w", err)
	}
	var doc periodoDoc
	err = r.col.FindOne(ctx, bson.M{"_id": oid, "borrado": false}).Decode(&doc)
	if err != nil {
		if errors.Is(err, mongo.ErrNoDocuments) {
			return nil, nil
		}
		return nil, fmt.Errorf("get periodo: %w", err)
	}
	return domainAca.ReconstituirPeriodo(
		doc.ID.Hex(),
		doc.Codigo,
		doc.Nombre,
		doc.FechaInicio,
		doc.FechaFin,
		doc.Estado,
		doc.SedeID,
		doc.CodigoExterno,
		doc.Borrado,
		doc.CreadoEn,
		doc.ActualizadoEn,
	), nil
}

func (r *periodoRepository) ListAll(ctx context.Context) ([]*domainAca.Periodo, error) {
	opts := options.Find().SetSort(bson.D{{Key: "fechaInicio", Value: -1}})
	cur, err := r.col.Find(ctx, bson.M{"borrado": false}, opts)
	if err != nil {
		return nil, fmt.Errorf("list all periodos: %w", err)
	}
	defer cur.Close(ctx)

	var list []*domainAca.Periodo
	for cur.Next(ctx) {
		var doc periodoDoc
		if err := cur.Decode(&doc); err != nil {
			return nil, err
		}
		list = append(list, domainAca.ReconstituirPeriodo(
			doc.ID.Hex(),
			doc.Codigo,
			doc.Nombre,
			doc.FechaInicio,
			doc.FechaFin,
			doc.Estado,
			doc.SedeID,
			doc.CodigoExterno,
			doc.Borrado,
			doc.CreadoEn,
			doc.ActualizadoEn,
		))
	}
	return list, nil
}

func (r *periodoRepository) ListBySedeID(ctx context.Context, sedeID string) ([]*domainAca.Periodo, error) {
	opts := options.Find().SetSort(bson.D{{Key: "fechaInicio", Value: -1}})
	cur, err := r.col.Find(ctx, bson.M{"sedeId": sedeID, "borrado": false}, opts)
	if err != nil {
		return nil, fmt.Errorf("list periodos by sede: %w", err)
	}
	defer cur.Close(ctx)

	var list []*domainAca.Periodo
	for cur.Next(ctx) {
		var doc periodoDoc
		if err := cur.Decode(&doc); err != nil {
			return nil, err
		}
		list = append(list, domainAca.ReconstituirPeriodo(
			doc.ID.Hex(),
			doc.Codigo,
			doc.Nombre,
			doc.FechaInicio,
			doc.FechaFin,
			doc.Estado,
			doc.SedeID,
			doc.CodigoExterno,
			doc.Borrado,
			doc.CreadoEn,
			doc.ActualizadoEn,
		))
	}
	return list, nil
}

func (r *periodoRepository) FindActivoSolapado(ctx context.Context, sedeID string, inicio, fin time.Time, excluirID string) (*domainAca.Periodo, error) {
	filter := bson.M{
		"estado":      domainAca.EstadoActivo,
		"borrado":     false,
		"fechaInicio": bson.M{"$lt": fin},
		"fechaFin":    bson.M{"$gt": inicio},
	}
	if sedeID != "" {
		filter["sedeId"] = sedeID
	}
	if excluirID != "" {
		if oid, err := primitive.ObjectIDFromHex(excluirID); err == nil {
			filter["_id"] = bson.M{"$ne": oid}
		}
	}

	var doc periodoDoc
	err := r.col.FindOne(ctx, filter).Decode(&doc)
	if err != nil {
		if errors.Is(err, mongo.ErrNoDocuments) {
			return nil, nil
		}
		return nil, err
	}
	return domainAca.ReconstituirPeriodo(
		doc.ID.Hex(),
		doc.Codigo,
		doc.Nombre,
		doc.FechaInicio,
		doc.FechaFin,
		doc.Estado,
		doc.SedeID,
		doc.CodigoExterno,
		doc.Borrado,
		doc.CreadoEn,
		doc.ActualizadoEn,
	), nil
}
