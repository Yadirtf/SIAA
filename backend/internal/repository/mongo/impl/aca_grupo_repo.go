package impl

import (
	"context"
	"errors"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"

	domainAca "github.com/siaa/backend/internal/domain/academico"
)

type grupoDoc struct {
	ID            primitive.ObjectID `bson:"_id,omitempty"`
	Numero        string             `bson:"numero"`
	AsignaturaID  string             `bson:"asignaturaId"`
	PeriodoID     string             `bson:"periodoId"`
	Cupo          int                `bson:"cupo"`
	CodigoExterno *string            `bson:"codigoExterno,omitempty"`
	Borrado       bool               `bson:"borrado"`
	CreadoEn      time.Time          `bson:"creadoEn"`
	ActualizadoEn time.Time          `bson:"actualizadoEn"`
}

// ─────────────────────────────────────────────────────────────
// Grupos (US-ACA-01 AC-04)
// ─────────────────────────────────────────────────────────────

func (r *estructuraRepository) CreateGrupo(ctx context.Context, g *domainAca.Grupo) error {
	doc := grupoDoc{
		Numero:        g.Numero(),
		AsignaturaID:  g.AsignaturaID(),
		PeriodoID:     g.PeriodoID(),
		Cupo:          g.Cupo(),
		CodigoExterno: g.CodigoExterno(),
		Borrado:       false,
		CreadoEn:      g.CreadoEn(),
		ActualizadoEn: g.ActualizadoEn(),
	}
	if g.ID() != "" {
		if oid, err := primitive.ObjectIDFromHex(g.ID()); err == nil {
			doc.ID = oid
		}
	}
	_, err := r.colGrupos.InsertOne(ctx, doc)
	return err
}

func (r *estructuraRepository) UpdateGrupo(ctx context.Context, g *domainAca.Grupo) error {
	oid, err := primitive.ObjectIDFromHex(g.ID())
	if err != nil {
		return err
	}
	_, err = r.colGrupos.UpdateOne(ctx, bson.M{"_id": oid}, bson.M{"$set": bson.M{
		"numero":        g.Numero(),
		"asignaturaId":  g.AsignaturaID(),
		"periodoId":     g.PeriodoID(),
		"cupo":          g.Cupo(),
		"codigoExterno": g.CodigoExterno(),
		"actualizadoEn": g.ActualizadoEn(),
	}})
	return err
}

func (r *estructuraRepository) GetGrupoByID(ctx context.Context, id string) (*domainAca.Grupo, error) {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, err
	}
	var doc grupoDoc
	err = r.colGrupos.FindOne(ctx, bson.M{"_id": oid, "borrado": false}).Decode(&doc)
	if err != nil {
		if errors.Is(err, mongo.ErrNoDocuments) {
			return nil, nil
		}
		return nil, err
	}
	return domainAca.ReconstituirGrupo(doc.ID.Hex(), doc.Numero, doc.AsignaturaID, doc.PeriodoID, doc.Cupo, doc.CodigoExterno, doc.Borrado, doc.CreadoEn, doc.ActualizadoEn), nil
}

func (r *estructuraRepository) ListGrupos(ctx context.Context, asignaturaID string, periodoID string) ([]*domainAca.Grupo, error) {
	filter := bson.M{"borrado": false}
	if asignaturaID != "" {
		filter["asignaturaId"] = asignaturaID
	}
	if periodoID != "" {
		filter["periodoId"] = periodoID
	}
	cur, err := r.colGrupos.Find(ctx, filter, options.Find().SetSort(bson.D{{Key: "numero", Value: 1}}))
	if err != nil {
		return nil, err
	}
	defer cur.Close(ctx)

	var list []*domainAca.Grupo
	for cur.Next(ctx) {
		var doc grupoDoc
		if err := cur.Decode(&doc); err != nil {
			return nil, err
		}
		list = append(list, domainAca.ReconstituirGrupo(doc.ID.Hex(), doc.Numero, doc.AsignaturaID, doc.PeriodoID, doc.Cupo, doc.CodigoExterno, doc.Borrado, doc.CreadoEn, doc.ActualizadoEn))
	}
	return list, nil
}

func (r *estructuraRepository) DeleteGrupoLogico(ctx context.Context, id string) error {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return err
	}
	_, err = r.colGrupos.UpdateOne(ctx, bson.M{"_id": oid}, bson.M{"$set": bson.M{"borrado": true, "actualizadoEn": time.Now()}})
	return err
}
