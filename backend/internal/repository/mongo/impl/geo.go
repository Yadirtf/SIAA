// Package impl — repositorios MongoDB para la jerarquía física de espacios (US-GEO-01).
package impl

import (
	"context"
	"errors"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"

	"github.com/siaa/backend/internal/domain/geo"
	"github.com/siaa/backend/internal/repository"
	mongoConn "github.com/siaa/backend/internal/repository/mongo"
)

// ─────────────────────────────────────────────────────────────
// 1. SEDES
// ─────────────────────────────────────────────────────────────

type sedeDoc struct {
	ID            primitive.ObjectID `bson:"_id,omitempty"`
	Codigo        string             `bson:"codigo"`
	Nombre        string             `bson:"nombre"`
	Direccion     string             `bson:"direccion"`
	Activo        bool               `bson:"activo"`
	Eliminado     bool               `bson:"eliminado"`
	CreadoEn      time.Time          `bson:"creadoEn"`
	ActualizadoEn time.Time          `bson:"actualizadoEn"`
}

type sedeRepository struct {
	col *mongo.Collection
}

func NewSedeRepository(client *mongoConn.Client) repository.SedeRepository {
	return &sedeRepository{col: client.Collection("sedes")}
}

func (r *sedeRepository) Create(ctx context.Context, s *geo.Sede) error {
	doc := sedeDoc{
		Codigo:        s.Codigo,
		Nombre:        s.Nombre,
		Direccion:     s.Direccion,
		Activo:        s.Activo,
		Eliminado:     false,
		CreadoEn:      s.CreadoEn,
		ActualizadoEn: s.ActualizadoEn,
	}
	if s.ID != "" {
		if oid, err := primitive.ObjectIDFromHex(s.ID); err == nil {
			doc.ID = oid
		}
	}
	res, err := r.col.InsertOne(ctx, doc)
	if err != nil {
		return fmt.Errorf("create sede: %w", err)
	}
	if oid, ok := res.InsertedID.(primitive.ObjectID); ok {
		s.ID = oid.Hex()
	}
	return nil
}

func (r *sedeRepository) FindByID(ctx context.Context, id string) (*geo.Sede, error) {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, nil
	}
	var doc sedeDoc
	err = r.col.FindOne(ctx, bson.D{
		{Key: "_id", Value: oid},
		{Key: "eliminado", Value: false},
	}).Decode(&doc)
	if errors.Is(err, mongo.ErrNoDocuments) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("findSedeByID: %w", err)
	}
	return &geo.Sede{
		ID:            doc.ID.Hex(),
		Codigo:        doc.Codigo,
		Nombre:        doc.Nombre,
		Direccion:     doc.Direccion,
		Activo:        doc.Activo,
		Eliminado:     doc.Eliminado,
		CreadoEn:      doc.CreadoEn,
		ActualizadoEn: doc.ActualizadoEn,
	}, nil
}

func (r *sedeRepository) FindByCodigo(ctx context.Context, codigo string) (*geo.Sede, error) {
	var doc sedeDoc
	err := r.col.FindOne(ctx, bson.D{
		{Key: "codigo", Value: codigo},
		{Key: "eliminado", Value: false},
	}).Decode(&doc)
	if errors.Is(err, mongo.ErrNoDocuments) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("findSedeByCodigo: %w", err)
	}
	return &geo.Sede{
		ID:            doc.ID.Hex(),
		Codigo:        doc.Codigo,
		Nombre:        doc.Nombre,
		Direccion:     doc.Direccion,
		Activo:        doc.Activo,
		Eliminado:     doc.Eliminado,
		CreadoEn:      doc.CreadoEn,
		ActualizadoEn: doc.ActualizadoEn,
	}, nil
}

func (r *sedeRepository) List(ctx context.Context) ([]*geo.Sede, error) {
	cursor, err := r.col.Find(ctx, bson.D{{Key: "eliminado", Value: false}})
	if err != nil {
		return nil, fmt.Errorf("listSedes: %w", err)
	}
	defer cursor.Close(ctx)

	var sedes []*geo.Sede
	for cursor.Next(ctx) {
		var doc sedeDoc
		if err := cursor.Decode(&doc); err != nil {
			return nil, fmt.Errorf("decode sede: %w", err)
		}
		sedes = append(sedes, &geo.Sede{
			ID:            doc.ID.Hex(),
			Codigo:        doc.Codigo,
			Nombre:        doc.Nombre,
			Direccion:     doc.Direccion,
			Activo:        doc.Activo,
			Eliminado:     doc.Eliminado,
			CreadoEn:      doc.CreadoEn,
			ActualizadoEn: doc.ActualizadoEn,
		})
	}
	return sedes, nil
}

func (r *sedeRepository) Update(ctx context.Context, s *geo.Sede) error {
	oid, err := primitive.ObjectIDFromHex(s.ID)
	if err != nil {
		return fmt.Errorf("invalid sede ID: %w", err)
	}
	update := bson.D{{Key: "$set", Value: bson.D{
		{Key: "codigo", Value: s.Codigo},
		{Key: "nombre", Value: s.Nombre},
		{Key: "direccion", Value: s.Direccion},
		{Key: "activo", Value: s.Activo},
		{Key: "actualizadoEn", Value: time.Now().UTC()},
	}}}
	_, err = r.col.UpdateByID(ctx, oid, update)
	return err
}

func (r *sedeRepository) SoftDelete(ctx context.Context, id string) error {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return fmt.Errorf("invalid sede ID: %w", err)
	}
	update := bson.D{{Key: "$set", Value: bson.D{
		{Key: "eliminado", Value: true},
		{Key: "activo", Value: false},
		{Key: "actualizadoEn", Value: time.Now().UTC()},
	}}}
	_, err = r.col.UpdateByID(ctx, oid, update)
	return err
}

// ─────────────────────────────────────────────────────────────
// 2. BLOQUES
// ─────────────────────────────────────────────────────────────

type bloqueDoc struct {
	ID            primitive.ObjectID `bson:"_id,omitempty"`
	SedeID        string             `bson:"sedeId"`
	Codigo        string             `bson:"codigo"`
	Nombre        string             `bson:"nombre"`
	Pisos         []int              `bson:"pisos"`
	Activo        bool               `bson:"activo"`
	Eliminado     bool               `bson:"eliminado"`
	CreadoEn      time.Time          `bson:"creadoEn"`
	ActualizadoEn time.Time          `bson:"actualizadoEn"`
}

type bloqueRepository struct {
	col *mongo.Collection
}

func NewBloqueRepository(client *mongoConn.Client) repository.BloqueRepository {
	return &bloqueRepository{col: client.Collection("bloques")}
}

func (r *bloqueRepository) Create(ctx context.Context, b *geo.Bloque) error {
	doc := bloqueDoc{
		SedeID:        b.SedeID,
		Codigo:        b.Codigo,
		Nombre:        b.Nombre,
		Pisos:         b.Pisos,
		Activo:        b.Activo,
		Eliminado:     false,
		CreadoEn:      b.CreadoEn,
		ActualizadoEn: b.ActualizadoEn,
	}
	if b.ID != "" {
		if oid, err := primitive.ObjectIDFromHex(b.ID); err == nil {
			doc.ID = oid
		}
	}
	res, err := r.col.InsertOne(ctx, doc)
	if err != nil {
		return fmt.Errorf("create bloque: %w", err)
	}
	if oid, ok := res.InsertedID.(primitive.ObjectID); ok {
		b.ID = oid.Hex()
	}
	return nil
}

func (r *bloqueRepository) FindByID(ctx context.Context, id string) (*geo.Bloque, error) {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, nil
	}
	var doc bloqueDoc
	err = r.col.FindOne(ctx, bson.D{
		{Key: "_id", Value: oid},
		{Key: "eliminado", Value: false},
	}).Decode(&doc)
	if errors.Is(err, mongo.ErrNoDocuments) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("findBloqueByID: %w", err)
	}
	return &geo.Bloque{
		ID:            doc.ID.Hex(),
		SedeID:        doc.SedeID,
		Codigo:        doc.Codigo,
		Nombre:        doc.Nombre,
		Pisos:         doc.Pisos,
		Activo:        doc.Activo,
		Eliminado:     doc.Eliminado,
		CreadoEn:      doc.CreadoEn,
		ActualizadoEn: doc.ActualizadoEn,
	}, nil
}

func (r *bloqueRepository) FindByCodigo(ctx context.Context, sedeID, codigo string) (*geo.Bloque, error) {
	var doc bloqueDoc
	err := r.col.FindOne(ctx, bson.D{
		{Key: "sedeId", Value: sedeID},
		{Key: "codigo", Value: codigo},
		{Key: "eliminado", Value: false},
	}).Decode(&doc)
	if errors.Is(err, mongo.ErrNoDocuments) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("findBloqueByCodigo: %w", err)
	}
	return &geo.Bloque{
		ID:            doc.ID.Hex(),
		SedeID:        doc.SedeID,
		Codigo:        doc.Codigo,
		Nombre:        doc.Nombre,
		Pisos:         doc.Pisos,
		Activo:        doc.Activo,
		Eliminado:     doc.Eliminado,
		CreadoEn:      doc.CreadoEn,
		ActualizadoEn: doc.ActualizadoEn,
	}, nil
}

func (r *bloqueRepository) ListBySede(ctx context.Context, sedeID string) ([]*geo.Bloque, error) {
	cursor, err := r.col.Find(ctx, bson.D{
		{Key: "sedeId", Value: sedeID},
		{Key: "eliminado", Value: false},
	})
	if err != nil {
		return nil, fmt.Errorf("listBloquesBySede: %w", err)
	}
	defer cursor.Close(ctx)

	var bloques []*geo.Bloque
	for cursor.Next(ctx) {
		var doc bloqueDoc
		if err := cursor.Decode(&doc); err != nil {
			return nil, fmt.Errorf("decode bloque: %w", err)
		}
		bloques = append(bloques, &geo.Bloque{
			ID:            doc.ID.Hex(),
			SedeID:        doc.SedeID,
			Codigo:        doc.Codigo,
			Nombre:        doc.Nombre,
			Pisos:         doc.Pisos,
			Activo:        doc.Activo,
			Eliminado:     doc.Eliminado,
			CreadoEn:      doc.CreadoEn,
			ActualizadoEn: doc.ActualizadoEn,
		})
	}
	return bloques, nil
}

func (r *bloqueRepository) List(ctx context.Context) ([]*geo.Bloque, error) {
	cursor, err := r.col.Find(ctx, bson.D{{Key: "eliminado", Value: false}})
	if err != nil {
		return nil, fmt.Errorf("listBloques: %w", err)
	}
	defer cursor.Close(ctx)

	var bloques []*geo.Bloque
	for cursor.Next(ctx) {
		var doc bloqueDoc
		if err := cursor.Decode(&doc); err != nil {
			return nil, fmt.Errorf("decode bloque: %w", err)
		}
		bloques = append(bloques, &geo.Bloque{
			ID:            doc.ID.Hex(),
			SedeID:        doc.SedeID,
			Codigo:        doc.Codigo,
			Nombre:        doc.Nombre,
			Pisos:         doc.Pisos,
			Activo:        doc.Activo,
			Eliminado:     doc.Eliminado,
			CreadoEn:      doc.CreadoEn,
			ActualizadoEn: doc.ActualizadoEn,
		})
	}
	return bloques, nil
}

func (r *bloqueRepository) Update(ctx context.Context, b *geo.Bloque) error {
	oid, err := primitive.ObjectIDFromHex(b.ID)
	if err != nil {
		return fmt.Errorf("invalid bloque ID: %w", err)
	}
	update := bson.D{{Key: "$set", Value: bson.D{
		{Key: "codigo", Value: b.Codigo},
		{Key: "nombre", Value: b.Nombre},
		{Key: "pisos", Value: b.Pisos},
		{Key: "activo", Value: b.Activo},
		{Key: "actualizadoEn", Value: time.Now().UTC()},
	}}}
	_, err = r.col.UpdateByID(ctx, oid, update)
	return err
}

func (r *bloqueRepository) SoftDelete(ctx context.Context, id string) error {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return fmt.Errorf("invalid bloque ID: %w", err)
	}
	update := bson.D{{Key: "$set", Value: bson.D{
		{Key: "eliminado", Value: true},
		{Key: "activo", Value: false},
		{Key: "actualizadoEn", Value: time.Now().UTC()},
	}}}
	_, err = r.col.UpdateByID(ctx, oid, update)
	return err
}

// ─────────────────────────────────────────────────────────────
// 3. ESPACIOS
// ─────────────────────────────────────────────────────────────

type espacioDoc struct {
	ID                  primitive.ObjectID `bson:"_id,omitempty"`
	SedeID              string             `bson:"sedeId"`
	Torre               *string            `bson:"torre,omitempty"`
	BloqueID            *string            `bson:"bloqueId,omitempty"`
	Piso                *int               `bson:"piso,omitempty"`
	Codigo              string             `bson:"codigo"`
	Nombre              string             `bson:"nombre"`
	Capacidad           int                `bson:"capacidad"`
	Tipo                string             `bson:"tipo"`
	FacultadResponsable string             `bson:"facultadResponsable"`
	Estado              string             `bson:"estado"`
	NivelValidacion     string             `bson:"nivelValidacion"`
	BufferMetros        float64            `bson:"bufferMetros"`
	VersionGeometria    int                `bson:"versionGeometria"`
	Activo              bool               `bson:"activo"`
	Eliminado           bool               `bson:"eliminado"`
	CreadoEn            time.Time          `bson:"creadoEn"`
	ActualizadoEn       time.Time          `bson:"actualizadoEn"`
}

type espacioRepository struct {
	col *mongo.Collection
}

func NewEspacioRepository(client *mongoConn.Client) repository.EspacioRepository {
	return &espacioRepository{col: client.Collection("espacios")}
}

func (r *espacioRepository) Create(ctx context.Context, e *geo.Espacio) error {
	doc := espacioDoc{
		SedeID:              e.SedeID,
		Torre:               e.Torre,
		BloqueID:            e.BloqueID,
		Piso:                e.Piso,
		Codigo:              e.Codigo,
		Nombre:              e.Nombre,
		Capacidad:           e.Capacidad,
		Tipo:                string(e.Tipo),
		FacultadResponsable: e.FacultadResponsable,
		Estado:              string(e.Estado),
		NivelValidacion:     string(e.NivelValidacion),
		BufferMetros:        e.BufferMetros,
		VersionGeometria:    e.VersionGeometria,
		Activo:              e.Activo,
		Eliminado:           false,
		CreadoEn:            e.CreadoEn,
		ActualizadoEn:       e.ActualizadoEn,
	}
	if e.ID != "" {
		if oid, err := primitive.ObjectIDFromHex(e.ID); err == nil {
			doc.ID = oid
		}
	}
	res, err := r.col.InsertOne(ctx, doc)
	if err != nil {
		return fmt.Errorf("create espacio: %w", err)
	}
	if oid, ok := res.InsertedID.(primitive.ObjectID); ok {
		e.ID = oid.Hex()
	}
	return nil
}

func (r *espacioRepository) FindByID(ctx context.Context, id string) (*geo.Espacio, error) {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, nil
	}
	var doc espacioDoc
	err = r.col.FindOne(ctx, bson.D{
		{Key: "_id", Value: oid},
		{Key: "eliminado", Value: false},
	}).Decode(&doc)
	if errors.Is(err, mongo.ErrNoDocuments) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("findEspacioByID: %w", err)
	}
	return docToEspacio(&doc), nil
}

func (r *espacioRepository) FindByCodigo(ctx context.Context, codigo string) (*geo.Espacio, error) {
	var doc espacioDoc
	err := r.col.FindOne(ctx, bson.D{
		{Key: "codigo", Value: codigo},
		{Key: "eliminado", Value: false},
	}).Decode(&doc)
	if errors.Is(err, mongo.ErrNoDocuments) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("findEspacioByCodigo: %w", err)
	}
	return docToEspacio(&doc), nil
}

func (r *espacioRepository) List(ctx context.Context, filter repository.EspacioFilter) ([]*geo.Espacio, error) {
	criteria := bson.D{{Key: "eliminado", Value: false}}

	if filter.SedeID != "" {
		criteria = append(criteria, bson.E{Key: "sedeId", Value: filter.SedeID})
	}
	if filter.BloqueID != "" {
		criteria = append(criteria, bson.E{Key: "bloqueId", Value: filter.BloqueID})
	}
	if filter.Piso != nil {
		criteria = append(criteria, bson.E{Key: "piso", Value: *filter.Piso})
	}
	if filter.Tipo != nil {
		criteria = append(criteria, bson.E{Key: "tipo", Value: string(*filter.Tipo)})
	}
	if filter.Estado != nil {
		criteria = append(criteria, bson.E{Key: "estado", Value: string(*filter.Estado)})
	}

	cursor, err := r.col.Find(ctx, criteria)
	if err != nil {
		return nil, fmt.Errorf("listEspacios: %w", err)
	}
	defer cursor.Close(ctx)

	var espacios []*geo.Espacio
	for cursor.Next(ctx) {
		var doc espacioDoc
		if err := cursor.Decode(&doc); err != nil {
			return nil, fmt.Errorf("decode espacio: %w", err)
		}
		espacios = append(espacios, docToEspacio(&doc))
	}
	return espacios, nil
}

func (r *espacioRepository) Update(ctx context.Context, e *geo.Espacio) error {
	oid, err := primitive.ObjectIDFromHex(e.ID)
	if err != nil {
		return fmt.Errorf("invalid espacio ID: %w", err)
	}
	update := bson.D{{Key: "$set", Value: bson.D{
		{Key: "sedeId", Value: e.SedeID},
		{Key: "torre", Value: e.Torre},
		{Key: "bloqueId", Value: e.BloqueID},
		{Key: "piso", Value: e.Piso},
		{Key: "codigo", Value: e.Codigo},
		{Key: "nombre", Value: e.Nombre},
		{Key: "capacidad", Value: e.Capacidad},
		{Key: "tipo", Value: string(e.Tipo)},
		{Key: "facultadResponsable", Value: e.FacultadResponsable},
		{Key: "estado", Value: string(e.Estado)},
		{Key: "nivelValidacion", Value: string(e.NivelValidacion)},
		{Key: "bufferMetros", Value: e.BufferMetros},
		{Key: "versionGeometria", Value: e.VersionGeometria},
		{Key: "activo", Value: e.Activo},
		{Key: "actualizadoEn", Value: time.Now().UTC()},
	}}}
	_, err = r.col.UpdateByID(ctx, oid, update)
	return err
}

func (r *espacioRepository) SoftDelete(ctx context.Context, id string) error {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return fmt.Errorf("invalid espacio ID: %w", err)
	}
	update := bson.D{{Key: "$set", Value: bson.D{
		{Key: "eliminado", Value: true},
		{Key: "activo", Value: false},
		{Key: "actualizadoEn", Value: time.Now().UTC()},
	}}}
	_, err = r.col.UpdateByID(ctx, oid, update)
	return err
}

func docToEspacio(doc *espacioDoc) *geo.Espacio {
	return &geo.Espacio{
		ID:                  doc.ID.Hex(),
		SedeID:              doc.SedeID,
		Torre:               doc.Torre,
		BloqueID:            doc.BloqueID,
		Piso:                doc.Piso,
		Codigo:              doc.Codigo,
		Nombre:              doc.Nombre,
		Capacidad:           doc.Capacidad,
		Tipo:                geo.TipoEspacio(doc.Tipo),
		FacultadResponsable: doc.FacultadResponsable,
		Estado:              geo.EstadoEspacio(doc.Estado),
		NivelValidacion:     geo.NivelValidacion(doc.NivelValidacion),
		BufferMetros:        doc.BufferMetros,
		VersionGeometria:    doc.VersionGeometria,
		Activo:              doc.Activo,
		Eliminado:           doc.Eliminado,
		CreadoEn:            doc.CreadoEn,
		ActualizadoEn:       doc.ActualizadoEn,
	}
}

// ─────────────────────────────────────────────────────────────
// 4. SESIONES FUTURAS CHECKER
// ─────────────────────────────────────────────────────────────

type sesionFutureChecker struct {
	col *mongo.Collection
}

func NewSesionFutureChecker(client *mongoConn.Client) repository.SesionFutureChecker {
	return &sesionFutureChecker{col: client.Collection("sesiones")}
}

func (s *sesionFutureChecker) CountSesionesFuturasPorEspacio(ctx context.Context, espacioID string, desde time.Time) (int64, error) {
	count, err := s.col.CountDocuments(ctx, bson.D{
		{Key: "espacioId", Value: espacioID},
		{Key: "inicioProgramado", Value: bson.D{{Key: "$gt", Value: desde}}},
		{Key: "estado", Value: bson.D{{Key: "$ne", Value: "CANCELADA"}}},
		{Key: "eliminado", Value: bson.D{{Key: "$ne", Value: true}}},
	})
	if err != nil {
		return 0, fmt.Errorf("countSesionesFuturas: %w", err)
	}
	return count, nil
}
