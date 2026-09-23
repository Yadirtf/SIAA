// Package impl — repositorios MongoDB para la estructura académica, horarios y asignaciones (EP-04).
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

// ─────────────────────────────────────────────────────────────
// 1. PERIODOS
// ─────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────
// 2. ESTRUCTURA ACADÉMICA (Facultades, Programas, Asignaturas, Grupos)
// ─────────────────────────────────────────────────────────────

type facultadDoc struct {
	ID            primitive.ObjectID `bson:"_id,omitempty"`
	Codigo        string             `bson:"codigo"`
	Nombre        string             `bson:"nombre"`
	SedeID        string             `bson:"sedeId,omitempty"`
	CodigoExterno *string            `bson:"codigoExterno,omitempty"`
	Borrado       bool               `bson:"borrado"`
	CreadoEn      time.Time          `bson:"creadoEn"`
	ActualizadoEn time.Time          `bson:"actualizadoEn"`
}

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

type estructuraRepository struct {
	colFacultades  *mongo.Collection
	colProgramas   *mongo.Collection
	colAsignaturas *mongo.Collection
	colGrupos      *mongo.Collection
}

func NewEstructuraRepository(client *mongoConn.Client) repository.EstructuraRepository {
	return &estructuraRepository{
		colFacultades:  client.Collection("facultades"),
		colProgramas:   client.Collection("programas"),
		colAsignaturas: client.Collection("asignaturas"),
		colGrupos:      client.Collection("grupos"),
	}
}

// Facultades
func (r *estructuraRepository) CreateFacultad(ctx context.Context, f *domainAca.Facultad) error {
	doc := facultadDoc{
		Codigo:        f.Codigo(),
		Nombre:        f.Nombre(),
		SedeID:        f.SedeID(),
		CodigoExterno: f.CodigoExterno(),
		Borrado:       false,
		CreadoEn:      f.CreadoEn(),
		ActualizadoEn: f.ActualizadoEn(),
	}
	if f.ID() != "" {
		if oid, err := primitive.ObjectIDFromHex(f.ID()); err == nil {
			doc.ID = oid
		}
	}
	_, err := r.colFacultades.InsertOne(ctx, doc)
	return err
}

func (r *estructuraRepository) UpdateFacultad(ctx context.Context, f *domainAca.Facultad) error {
	oid, err := primitive.ObjectIDFromHex(f.ID())
	if err != nil {
		return err
	}
	_, err = r.colFacultades.UpdateOne(ctx, bson.M{"_id": oid}, bson.M{"$set": bson.M{
		"codigo":        f.Codigo(),
		"nombre":        f.Nombre(),
		"sedeId":        f.SedeID(),
		"codigoExterno": f.CodigoExterno(),
		"actualizadoEn": f.ActualizadoEn(),
	}})
	return err
}

func (r *estructuraRepository) GetFacultadByID(ctx context.Context, id string) (*domainAca.Facultad, error) {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, err
	}
	var doc facultadDoc
	err = r.colFacultades.FindOne(ctx, bson.M{"_id": oid, "borrado": false}).Decode(&doc)
	if err != nil {
		if errors.Is(err, mongo.ErrNoDocuments) {
			return nil, nil
		}
		return nil, err
	}
	return domainAca.ReconstituirFacultad(doc.ID.Hex(), doc.Codigo, doc.Nombre, doc.SedeID, doc.CodigoExterno, doc.Borrado, doc.CreadoEn, doc.ActualizadoEn), nil
}

func (r *estructuraRepository) ListFacultades(ctx context.Context, sedeID string) ([]*domainAca.Facultad, error) {
	filter := bson.M{"borrado": false}
	if sedeID != "" {
		filter["sedeId"] = sedeID
	}
	cur, err := r.colFacultades.Find(ctx, filter, options.Find().SetSort(bson.D{{Key: "nombre", Value: 1}}))
	if err != nil {
		return nil, err
	}
	defer cur.Close(ctx)

	var list []*domainAca.Facultad
	for cur.Next(ctx) {
		var doc facultadDoc
		if err := cur.Decode(&doc); err != nil {
			return nil, err
		}
		list = append(list, domainAca.ReconstituirFacultad(doc.ID.Hex(), doc.Codigo, doc.Nombre, doc.SedeID, doc.CodigoExterno, doc.Borrado, doc.CreadoEn, doc.ActualizadoEn))
	}
	return list, nil
}

func (r *estructuraRepository) DeleteFacultadLogico(ctx context.Context, id string) error {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return err
	}
	_, err = r.colFacultades.UpdateOne(ctx, bson.M{"_id": oid}, bson.M{"$set": bson.M{"borrado": true, "actualizadoEn": time.Now()}})
	return err
}

// Programas
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

// Asignaturas
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

// Grupos
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

// ─────────────────────────────────────────────────────────────
// 3. ASIGNACIONES (Docente - Grupo - Aula - Franja)
// ─────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────
// 4. CALENDARIO DE EXCEPCIONES (US-ACA-04)
// ─────────────────────────────────────────────────────────────

type calendarioExcepcionDoc struct {
	ID            primitive.ObjectID        `bson:"_id,omitempty"`
	Nombre        string                    `bson:"nombre"`
	Tipo          domainAca.TipoExcepcion   `bson:"tipo"`
	Ambito        domainAca.AmbitoExcepcion `bson:"ambito"`
	AmbitoID      string                    `bson:"ambitoId,omitempty"`
	FechaInicio   time.Time                 `bson:"fechaInicio"`
	FechaFin      time.Time                 `bson:"fechaFin"`
	Borrado       bool                      `bson:"borrado"`
	CreadoEn      time.Time                 `bson:"creadoEn"`
	ActualizadoEn time.Time                 `bson:"actualizadoEn"`
}

type calendarioExcepcionRepository struct {
	col *mongo.Collection
}

func NewCalendarioExcepcionRepository(client *mongoConn.Client) repository.CalendarioExcepcionRepository {
	return &calendarioExcepcionRepository{col: client.Collection("calendario_excepciones")}
}

func (r *calendarioExcepcionRepository) Create(ctx context.Context, e *domainAca.CalendarioExcepcion) error {
	doc := calendarioExcepcionDoc{
		Nombre:        e.Nombre(),
		Tipo:          e.Tipo(),
		Ambito:        e.Ambito(),
		AmbitoID:      e.AmbitoID(),
		FechaInicio:   e.FechaInicio(),
		FechaFin:      e.FechaFin(),
		Borrado:       false,
		CreadoEn:      e.CreadoEn(),
		ActualizadoEn: e.ActualizadoEn(),
	}
	if e.ID() != "" {
		if oid, err := primitive.ObjectIDFromHex(e.ID()); err == nil {
			doc.ID = oid
		}
	}
	_, err := r.col.InsertOne(ctx, doc)
	return err
}

func (r *calendarioExcepcionRepository) Update(ctx context.Context, e *domainAca.CalendarioExcepcion) error {
	oid, err := primitive.ObjectIDFromHex(e.ID())
	if err != nil {
		return err
	}
	update := bson.M{
		"$set": bson.M{
			"nombre":        e.Nombre(),
			"tipo":          e.Tipo(),
			"ambito":        e.Ambito(),
			"ambitoId":      e.AmbitoID(),
			"fechaInicio":   e.FechaInicio(),
			"fechaFin":      e.FechaFin(),
			"actualizadoEn": e.ActualizadoEn(),
		},
	}
	_, err = r.col.UpdateOne(ctx, bson.M{"_id": oid}, update)
	return err
}

func (r *calendarioExcepcionRepository) GetByID(ctx context.Context, id string) (*domainAca.CalendarioExcepcion, error) {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, err
	}
	var doc calendarioExcepcionDoc
	err = r.col.FindOne(ctx, bson.M{"_id": oid, "borrado": false}).Decode(&doc)
	if err != nil {
		if errors.Is(err, mongo.ErrNoDocuments) {
			return nil, nil
		}
		return nil, err
	}
	return domainAca.ReconstituirCalendarioExcepcion(
		doc.ID.Hex(),
		doc.Nombre,
		doc.Tipo,
		doc.Ambito,
		doc.AmbitoID,
		doc.FechaInicio,
		doc.FechaFin,
		doc.Borrado,
		doc.CreadoEn,
		doc.ActualizadoEn,
	), nil
}

func (r *calendarioExcepcionRepository) ListAll(ctx context.Context) ([]*domainAca.CalendarioExcepcion, error) {
	cur, err := r.col.Find(ctx, bson.M{"borrado": false}, options.Find().SetSort(bson.D{{Key: "fechaInicio", Value: 1}}))
	if err != nil {
		return nil, err
	}
	defer cur.Close(ctx)

	var list []*domainAca.CalendarioExcepcion
	for cur.Next(ctx) {
		var doc calendarioExcepcionDoc
		if err := cur.Decode(&doc); err != nil {
			return nil, err
		}
		list = append(list, domainAca.ReconstituirCalendarioExcepcion(
			doc.ID.Hex(),
			doc.Nombre,
			doc.Tipo,
			doc.Ambito,
			doc.AmbitoID,
			doc.FechaInicio,
			doc.FechaFin,
			doc.Borrado,
			doc.CreadoEn,
			doc.ActualizadoEn,
		))
	}
	return list, nil
}

func (r *calendarioExcepcionRepository) ListByRango(ctx context.Context, inicio, fin time.Time) ([]*domainAca.CalendarioExcepcion, error) {
	filter := bson.M{
		"borrado":     false,
		"fechaInicio": bson.M{"$lte": fin},
		"fechaFin":    bson.M{"$gte": inicio},
	}
	cur, err := r.col.Find(ctx, filter, options.Find().SetSort(bson.D{{Key: "fechaInicio", Value: 1}}))
	if err != nil {
		return nil, err
	}
	defer cur.Close(ctx)

	var list []*domainAca.CalendarioExcepcion
	for cur.Next(ctx) {
		var doc calendarioExcepcionDoc
		if err := cur.Decode(&doc); err != nil {
			return nil, err
		}
		list = append(list, domainAca.ReconstituirCalendarioExcepcion(
			doc.ID.Hex(),
			doc.Nombre,
			doc.Tipo,
			doc.Ambito,
			doc.AmbitoID,
			doc.FechaInicio,
			doc.FechaFin,
			doc.Borrado,
			doc.CreadoEn,
			doc.ActualizadoEn,
		))
	}
	return list, nil
}

func (r *calendarioExcepcionRepository) DeleteLogico(ctx context.Context, id string) error {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return err
	}
	_, err = r.col.UpdateOne(ctx, bson.M{"_id": oid}, bson.M{"$set": bson.M{"borrado": true, "actualizadoEn": time.Now()}})
	return err
}
