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

type programaDoc struct {
	ID            primitive.ObjectID `bson:"_id,omitempty"`
	Codigo        string             `bson:"codigo"`
	Nombre        string             `bson:"nombre"`
	FacultadID    string             `bson:"facultadId"`
	CodigoExterno *string            `bson:"codigoExterno,omitempty"`
	Borrado       bool               `bson:"borrado"`
	CreadoEn      time.Time          `bson:"creadoEn"`
	ActualizadoEn time.Time          `bson:"actualizadoEn"`
}

type asignaturaDoc struct {
	ID            primitive.ObjectID `bson:"_id,omitempty"`
	Codigo        string             `bson:"codigo"`
	Nombre        string             `bson:"nombre"`
	ProgramaID    string             `bson:"programaId"`
	Creditos      int                `bson:"creditos"`
	CodigoExterno *string            `bson:"codigoExterno,omitempty"`
	Borrado       bool               `bson:"borrado"`
	CreadoEn      time.Time          `bson:"creadoEn"`
	ActualizadoEn time.Time          `bson:"actualizadoEn"`
}

// ─────────────────────────────────────────────────────────────
// Programas (US-ACA-01 AC-04)
// ─────────────────────────────────────────────────────────────

func (r *estructuraRepository) CreatePrograma(ctx context.Context, p *domainAca.Programa) error {
	doc := programaDoc{
		Codigo:        p.Codigo(),
		Nombre:        p.Nombre(),
		FacultadID:    p.FacultadID(),
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
	_, err := r.colProgramas.InsertOne(ctx, doc)
	return err
}

func (r *estructuraRepository) UpdatePrograma(ctx context.Context, p *domainAca.Programa) error {
	oid, err := primitive.ObjectIDFromHex(p.ID())
	if err != nil {
		return err
	}
	_, err = r.colProgramas.UpdateOne(ctx, bson.M{"_id": oid}, bson.M{"$set": bson.M{
		"codigo":        p.Codigo(),
		"nombre":        p.Nombre(),
		"facultadId":    p.FacultadID(),
		"codigoExterno": p.CodigoExterno(),
		"actualizadoEn": p.ActualizadoEn(),
	}})
	return err
}

func (r *estructuraRepository) GetProgramaByID(ctx context.Context, id string) (*domainAca.Programa, error) {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, err
	}
	var doc programaDoc
	err = r.colProgramas.FindOne(ctx, bson.M{"_id": oid, "borrado": false}).Decode(&doc)
	if err != nil {
		if errors.Is(err, mongo.ErrNoDocuments) {
			return nil, nil
		}
		return nil, err
	}
	return domainAca.ReconstituirPrograma(doc.ID.Hex(), doc.Codigo, doc.Nombre, doc.FacultadID, doc.CodigoExterno, doc.Borrado, doc.CreadoEn, doc.ActualizadoEn), nil
}

func (r *estructuraRepository) ListProgramas(ctx context.Context, facultadID string) ([]*domainAca.Programa, error) {
	filter := bson.M{"borrado": false}
	if facultadID != "" {
		filter["facultadId"] = facultadID
	}
	cur, err := r.colProgramas.Find(ctx, filter, options.Find().SetSort(bson.D{{Key: "nombre", Value: 1}}))
	if err != nil {
		return nil, err
	}
	defer cur.Close(ctx)

	var list []*domainAca.Programa
	for cur.Next(ctx) {
		var doc programaDoc
		if err := cur.Decode(&doc); err != nil {
			return nil, err
		}
		list = append(list, domainAca.ReconstituirPrograma(doc.ID.Hex(), doc.Codigo, doc.Nombre, doc.FacultadID, doc.CodigoExterno, doc.Borrado, doc.CreadoEn, doc.ActualizadoEn))
	}
	return list, nil
}

func (r *estructuraRepository) DeleteProgramaLogico(ctx context.Context, id string) error {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return err
	}
	_, err = r.colProgramas.UpdateOne(ctx, bson.M{"_id": oid}, bson.M{"$set": bson.M{"borrado": true, "actualizadoEn": time.Now()}})
	return err
}

// ─────────────────────────────────────────────────────────────
// Asignaturas (US-ACA-01 AC-04)
// ─────────────────────────────────────────────────────────────

func (r *estructuraRepository) CreateAsignatura(ctx context.Context, a *domainAca.Asignatura) error {
	doc := asignaturaDoc{
		Codigo:        a.Codigo(),
		Nombre:        a.Nombre(),
		ProgramaID:    a.ProgramaID(),
		Creditos:      a.Creditos(),
		CodigoExterno: a.CodigoExterno(),
		Borrado:       false,
		CreadoEn:      a.CreadoEn(),
		ActualizadoEn: a.ActualizadoEn(),
	}
	if a.ID() != "" {
		if oid, err := primitive.ObjectIDFromHex(a.ID()); err == nil {
			doc.ID = oid
		}
	}
	_, err := r.colAsignaturas.InsertOne(ctx, doc)
	return err
}

func (r *estructuraRepository) UpdateAsignatura(ctx context.Context, a *domainAca.Asignatura) error {
	oid, err := primitive.ObjectIDFromHex(a.ID())
	if err != nil {
		return err
	}
	_, err = r.colAsignaturas.UpdateOne(ctx, bson.M{"_id": oid}, bson.M{"$set": bson.M{
		"codigo":        a.Codigo(),
		"nombre":        a.Nombre(),
		"programaId":    a.ProgramaID(),
		"creditos":      a.Creditos(),
		"codigoExterno": a.CodigoExterno(),
		"actualizadoEn": a.ActualizadoEn(),
	}})
	return err
}

func (r *estructuraRepository) GetAsignaturaByID(ctx context.Context, id string) (*domainAca.Asignatura, error) {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, err
	}
	var doc asignaturaDoc
	err = r.colAsignaturas.FindOne(ctx, bson.M{"_id": oid, "borrado": false}).Decode(&doc)
	if err != nil {
		if errors.Is(err, mongo.ErrNoDocuments) {
			return nil, nil
		}
		return nil, err
	}
	return domainAca.ReconstituirAsignatura(doc.ID.Hex(), doc.Codigo, doc.Nombre, doc.ProgramaID, doc.Creditos, doc.CodigoExterno, doc.Borrado, doc.CreadoEn, doc.ActualizadoEn), nil
}

func (r *estructuraRepository) ListAsignaturas(ctx context.Context, programaID string) ([]*domainAca.Asignatura, error) {
	filter := bson.M{"borrado": false}
	if programaID != "" {
		filter["programaId"] = programaID
	}
	cur, err := r.colAsignaturas.Find(ctx, filter, options.Find().SetSort(bson.D{{Key: "nombre", Value: 1}}))
	if err != nil {
		return nil, err
	}
	defer cur.Close(ctx)

	var list []*domainAca.Asignatura
	for cur.Next(ctx) {
		var doc asignaturaDoc
		if err := cur.Decode(&doc); err != nil {
			return nil, err
		}
		list = append(list, domainAca.ReconstituirAsignatura(doc.ID.Hex(), doc.Codigo, doc.Nombre, doc.ProgramaID, doc.Creditos, doc.CodigoExterno, doc.Borrado, doc.CreadoEn, doc.ActualizadoEn))
	}
	return list, nil
}

func (r *estructuraRepository) DeleteAsignaturaLogico(ctx context.Context, id string) error {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return err
	}
	_, err = r.colAsignaturas.UpdateOne(ctx, bson.M{"_id": oid}, bson.M{"$set": bson.M{"borrado": true, "actualizadoEn": time.Now()}})
	return err
}
