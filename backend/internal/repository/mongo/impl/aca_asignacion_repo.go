package impl

import (
	"context"
	"errors"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"

	domainAca "github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/repository"
	mongoConn "github.com/siaa/backend/internal/repository/mongo"
)

type franjaDoc struct {
	DiaSemana   int    `bson:"diaSemana"`
	HoraInicio  string `bson:"horaInicio"`
	HoraFin     string `bson:"horaFin"`
	ZonaHoraria string `bson:"zonaHoraria"`
}

type asignacionDoc struct {
	ID                 primitive.ObjectID            `bson:"_id,omitempty"`
	PeriodoID          string                        `bson:"periodoId"`
	DocenteIDs         []string                      `bson:"docenteIds"`
	DocenteNombre      string                        `bson:"docenteNombre"`
	GrupoID            string                        `bson:"grupoId"`
	AsignaturaID       string                        `bson:"asignaturaId"`
	FacultadID         string                        `bson:"facultadId"`
	EspacioID          string                        `bson:"espacioId,omitempty"`
	EspacioNombre      string                        `bson:"espacioNombre,omitempty"`
	Franja             franjaDoc                     `bson:"franja"`
	Modalidad          domainAca.ModalidadAsignacion `bson:"modalidad"`
	ExentaGeoespacial  bool                          `bson:"exentaGeoespacial"`
	ParametrosOverride map[string]interface{}        `bson:"parametrosOverride,omitempty"`
	Estado             domainAca.EstadoAsignacion    `bson:"estado"`
	FechaInicio        time.Time                     `bson:"fechaInicio"`
	FechaFin           time.Time                     `bson:"fechaFin"`
	CodigoExterno      *string                       `bson:"codigoExterno,omitempty"`
	Borrado            bool                          `bson:"borrado"`
	CreadoEn           time.Time                     `bson:"creadoEn"`
	ActualizadoEn      time.Time                     `bson:"actualizadoEn"`
}

type asignacionRepository struct {
	col *mongo.Collection
}

func NewAsignacionRepository(client *mongoConn.Client) repository.AsignacionRepository {
	return &asignacionRepository{col: client.Collection("asignaciones")}
}

func (r *asignacionRepository) Create(ctx context.Context, a *domainAca.Asignacion) error {
	doc := asignacionDoc{
		PeriodoID:     a.PeriodoID(),
		DocenteIDs:    a.DocenteIDs(),
		DocenteNombre: a.DocenteNombre(),
		GrupoID:       a.GrupoID(),
		AsignaturaID:  a.AsignaturaID(),
		FacultadID:    a.FacultadID(),
		EspacioID:     a.EspacioID(),
		EspacioNombre: a.EspacioNombre(),
		Franja: franjaDoc{
			DiaSemana:   a.Franja().DiaSemana(),
			HoraInicio:  a.Franja().HoraInicio(),
			HoraFin:     a.Franja().HoraFin(),
			ZonaHoraria: a.Franja().ZonaHoraria(),
		},
		Modalidad:          a.Modalidad(),
		ExentaGeoespacial:  a.ExentaGeoespacial(),
		ParametrosOverride: a.ParametrosOverride(),
		Estado:             a.Estado(),
		FechaInicio:        a.FechaInicio(),
		FechaFin:           a.FechaFin(),
		CodigoExterno:      a.CodigoExterno(),
		Borrado:            false,
		CreadoEn:           a.CreadoEn(),
		ActualizadoEn:      a.ActualizadoEn(),
	}
	if a.ID() != "" {
		if oid, err := primitive.ObjectIDFromHex(a.ID()); err == nil {
			doc.ID = oid
		}
	}
	_, err := r.col.InsertOne(ctx, doc)
	return err
}

func (r *asignacionRepository) Update(ctx context.Context, a *domainAca.Asignacion) error {
	oid, err := primitive.ObjectIDFromHex(a.ID())
	if err != nil {
		return err
	}
	update := bson.M{
		"$set": bson.M{
			"periodoId":     a.PeriodoID(),
			"docenteIds":    a.DocenteIDs(),
			"docenteNombre": a.DocenteNombre(),
			"grupoId":       a.GrupoID(),
			"asignaturaId":  a.AsignaturaID(),
			"facultadId":    a.FacultadID(),
			"espacioId":     a.EspacioID(),
			"espacioNombre": a.EspacioNombre(),
			"franja": franjaDoc{
				DiaSemana:   a.Franja().DiaSemana(),
				HoraInicio:  a.Franja().HoraInicio(),
				HoraFin:     a.Franja().HoraFin(),
				ZonaHoraria: a.Franja().ZonaHoraria(),
			},
			"modalidad":          a.Modalidad(),
			"exentaGeoespacial":  a.ExentaGeoespacial(),
			"parametrosOverride": a.ParametrosOverride(),
			"estado":             a.Estado(),
			"fechaInicio":        a.FechaInicio(),
			"fechaFin":           a.FechaFin(),
			"codigoExterno":      a.CodigoExterno(),
			"actualizadoEn":      a.ActualizadoEn(),
		},
	}
	_, err = r.col.UpdateOne(ctx, bson.M{"_id": oid}, update)
	return err
}

func (r *asignacionRepository) GetByID(ctx context.Context, id string) (*domainAca.Asignacion, error) {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, err
	}
	var doc asignacionDoc
	err = r.col.FindOne(ctx, bson.M{"_id": oid, "borrado": false}).Decode(&doc)
	if err != nil {
		if errors.Is(err, mongo.ErrNoDocuments) {
			return nil, nil
		}
		return nil, err
	}
	return mapDocToAsignacion(doc), nil
}

func (r *asignacionRepository) ListByPeriodoID(ctx context.Context, periodoID string) ([]domainAca.Asignacion, error) {
	cur, err := r.col.Find(ctx, bson.M{"periodoId": periodoID, "borrado": false})
	if err != nil {
		return nil, err
	}
	defer cur.Close(ctx)

	var list []domainAca.Asignacion
	for cur.Next(ctx) {
		var doc asignacionDoc
		if err := cur.Decode(&doc); err != nil {
			return nil, err
		}
		list = append(list, *mapDocToAsignacion(doc))
	}
	return list, nil
}

func (r *asignacionRepository) ListByDocenteID(ctx context.Context, periodoID string, docenteID string) ([]domainAca.Asignacion, error) {
	filter := bson.M{
		"docenteIds": docenteID,
		"borrado":    false,
	}
	if periodoID != "" {
		filter["periodoId"] = periodoID
	}
	cur, err := r.col.Find(ctx, filter)
	if err != nil {
		return nil, err
	}
	defer cur.Close(ctx)

	var list []domainAca.Asignacion
	for cur.Next(ctx) {
		var doc asignacionDoc
		if err := cur.Decode(&doc); err != nil {
			return nil, err
		}
		list = append(list, *mapDocToAsignacion(doc))
	}
	return list, nil
}

func (r *asignacionRepository) ListByEspacioID(ctx context.Context, periodoID string, espacioID string) ([]domainAca.Asignacion, error) {
	filter := bson.M{
		"espacioId": espacioID,
		"borrado":   false,
	}
	if periodoID != "" {
		filter["periodoId"] = periodoID
	}
	cur, err := r.col.Find(ctx, filter)
	if err != nil {
		return nil, err
	}
	defer cur.Close(ctx)

	var list []domainAca.Asignacion
	for cur.Next(ctx) {
		var doc asignacionDoc
		if err := cur.Decode(&doc); err != nil {
			return nil, err
		}
		list = append(list, *mapDocToAsignacion(doc))
	}
	return list, nil
}

func (r *asignacionRepository) DeleteLogico(ctx context.Context, id string) error {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return err
	}
	_, err = r.col.UpdateOne(ctx, bson.M{"_id": oid}, bson.M{"$set": bson.M{"borrado": true, "actualizadoEn": time.Now()}})
	return err
}

func mapDocToAsignacion(doc asignacionDoc) *domainAca.Asignacion {
	franja := domainAca.ReconstituirFranjaHoraria(
		doc.Franja.DiaSemana,
		doc.Franja.HoraInicio,
		doc.Franja.HoraFin,
		doc.Franja.ZonaHoraria,
	)
	return domainAca.ReconstituirAsignacion(
		doc.ID.Hex(),
		doc.PeriodoID,
		doc.DocenteIDs,
		doc.DocenteNombre,
		doc.GrupoID,
		doc.AsignaturaID,
		doc.FacultadID,
		doc.EspacioID,
		doc.EspacioNombre,
		franja,
		doc.Modalidad,
		doc.ExentaGeoespacial,
		doc.ParametrosOverride,
		doc.Estado,
		doc.FechaInicio,
		doc.FechaFin,
		doc.CodigoExterno,
		doc.Borrado,
		doc.CreadoEn,
		doc.ActualizadoEn,
	)
}
