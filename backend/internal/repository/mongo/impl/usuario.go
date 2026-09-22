// Package impl — repositorio MongoDB para usuarios.
package impl

import (
	"context"
	"errors"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"

	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/domain/user"
	"github.com/siaa/backend/internal/repository"
	mongoConn "github.com/siaa/backend/internal/repository/mongo"
)

// ─── Documento BSON ──────────────────────────────────────────

type usuarioDoc struct {
	ID                   primitive.ObjectID `bson:"_id,omitempty"`
	Correo               string             `bson:"correo"`
	PasswordHash         string             `bson:"passwordHash"`
	Nombre               string             `bson:"nombre"`
	Apellido             string             `bson:"apellido"`
	Activo               bool               `bson:"activo"`
	Eliminado            bool               `bson:"eliminado"`
	Roles                []rolAsignadoDoc   `bson:"roles"`
	Ambitos              []ambitoDoc        `bson:"ambitos"`
	IntentosFallidos     int                `bson:"intentosFallidos"`
	BloqueadoHasta       *time.Time         `bson:"bloqueadoHasta,omitempty"`
	UltimoFalloEn        *time.Time         `bson:"ultimoFalloEn,omitempty"`
	DispositivoVinculado *string            `bson:"dispositivoVinculado,omitempty"`
	CreadoEn             time.Time          `bson:"creadoEn"`
	ActualizadoEn        time.Time          `bson:"actualizadoEn"`
}

type rolAsignadoDoc struct {
	RolID          string     `bson:"rolId"`
	Nombre         string     `bson:"nombre"`
	VigenciaInicio *time.Time `bson:"vigenciaInicio,omitempty"`
	VigenciaFin    *time.Time `bson:"vigenciaFin,omitempty"`
}

type ambitoDoc struct {
	Tipo string `bson:"tipo"`
	ID   string `bson:"id"`
}

// ─── Repositorio ─────────────────────────────────────────────

type usuarioRepository struct {
	col *mongo.Collection
}

// NewUsuarioRepository crea la implementación MongoDB de UsuarioRepository.
func NewUsuarioRepository(client *mongoConn.Client) repository.UsuarioRepository {
	return &usuarioRepository{col: client.Collection("usuarios")}
}

func (r *usuarioRepository) FindByCorreo(ctx context.Context, correo string) (*user.Usuario, error) {
	var doc usuarioDoc
	err := r.col.FindOne(ctx, bson.D{
		{Key: "correo", Value: correo},
		{Key: "eliminado", Value: false},
	}).Decode(&doc)
	if errors.Is(err, mongo.ErrNoDocuments) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("findByCorreo: %w", err)
	}
	return docToUsuario(&doc), nil
}

func (r *usuarioRepository) FindByID(ctx context.Context, id string) (*user.Usuario, error) {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, nil
	}
	var doc usuarioDoc
	err = r.col.FindOne(ctx, bson.D{{Key: "_id", Value: oid}}).Decode(&doc)
	if errors.Is(err, mongo.ErrNoDocuments) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("findById: %w", err)
	}
	return docToUsuario(&doc), nil
}

func (r *usuarioRepository) UpdateIntentosFallidos(ctx context.Context, id string, intentos int, bloqueadoHasta *time.Time, ultimoFalloEn *time.Time) error {
	oid, _ := primitive.ObjectIDFromHex(id)
	update := bson.D{{Key: "$set", Value: bson.D{
		{Key: "intentosFallidos", Value: intentos},
		{Key: "bloqueadoHasta", Value: bloqueadoHasta},
		{Key: "ultimoFalloEn", Value: ultimoFalloEn},
		{Key: "actualizadoEn", Value: time.Now().UTC()},
	}}}
	_, err := r.col.UpdateByID(ctx, oid, update)
	return err
}

func (r *usuarioRepository) ResetIntentosFallidos(ctx context.Context, id string) error {
	oid, _ := primitive.ObjectIDFromHex(id)
	update := bson.D{{Key: "$set", Value: bson.D{
		{Key: "intentosFallidos", Value: 0},
		{Key: "bloqueadoHasta", Value: nil},
		{Key: "ultimoFalloEn", Value: nil},
		{Key: "actualizadoEn", Value: time.Now().UTC()},
	}}}
	_, err := r.col.UpdateByID(ctx, oid, update)
	return err
}

func (r *usuarioRepository) UpdatePassword(ctx context.Context, id, passwordHash string) error {
	oid, _ := primitive.ObjectIDFromHex(id)
	update := bson.D{{Key: "$set", Value: bson.D{
		{Key: "passwordHash", Value: passwordHash},
		{Key: "actualizadoEn", Value: time.Now().UTC()},
	}}}
	_, err := r.col.UpdateByID(ctx, oid, update)
	return err
}

func (r *usuarioRepository) Create(ctx context.Context, u *user.Usuario) error {
	doc := usuarioToDoc(u)
	result, err := r.col.InsertOne(ctx, doc)
	if err != nil {
		return fmt.Errorf("create usuario: %w", err)
	}
	u.ID = result.InsertedID.(primitive.ObjectID).Hex()
	return nil
}

func (r *usuarioRepository) Update(ctx context.Context, u *user.Usuario) error {
	oid, _ := primitive.ObjectIDFromHex(u.ID)
	doc := usuarioToDoc(u)
	doc.ActualizadoEn = time.Now().UTC()
	_, err := r.col.ReplaceOne(ctx, bson.D{{Key: "_id", Value: oid}}, doc)
	return err
}

// ─── Conversores BSON ↔ dominio ──────────────────────────────

func docToUsuario(d *usuarioDoc) *user.Usuario {
	u := &user.Usuario{
		ID:                   d.ID.Hex(),
		Correo:               d.Correo,
		PasswordHash:         d.PasswordHash,
		Nombre:               d.Nombre,
		Apellido:             d.Apellido,
		Activo:               d.Activo,
		Eliminado:            d.Eliminado,
		IntentosFallidos:     d.IntentosFallidos,
		BloqueadoHasta:       d.BloqueadoHasta,
		UltimoFalloEn:        d.UltimoFalloEn,
		DispositivoVinculado: d.DispositivoVinculado,
		CreadoEn:             d.CreadoEn,
		ActualizadoEn:        d.ActualizadoEn,
	}
	for _, r := range d.Roles {
		u.Roles = append(u.Roles, user.RolAsignado{
			RolID:          r.RolID,
			Nombre:         rbac.RoleName(r.Nombre),
			VigenciaInicio: r.VigenciaInicio,
			VigenciaFin:    r.VigenciaFin,
		})
	}
	for _, a := range d.Ambitos {
		u.Ambitos = append(u.Ambitos, rbac.Scope{
			Tipo: rbac.ScopeType(a.Tipo),
			ID:   a.ID,
		})
	}
	return u
}

func usuarioToDoc(u *user.Usuario) *usuarioDoc {
	d := &usuarioDoc{
		Correo:               u.Correo,
		PasswordHash:         u.PasswordHash,
		Nombre:               u.Nombre,
		Apellido:             u.Apellido,
		Activo:               u.Activo,
		Eliminado:            u.Eliminado,
		IntentosFallidos:     u.IntentosFallidos,
		BloqueadoHasta:       u.BloqueadoHasta,
		UltimoFalloEn:        u.UltimoFalloEn,
		DispositivoVinculado: u.DispositivoVinculado,
		CreadoEn:             u.CreadoEn,
		ActualizadoEn:        u.ActualizadoEn,
	}
	if u.ID != "" {
		if oid, err := primitive.ObjectIDFromHex(u.ID); err == nil {
			d.ID = oid
		}
	}
	for _, r := range u.Roles {
		d.Roles = append(d.Roles, rolAsignadoDoc{
			RolID:          r.RolID,
			Nombre:         string(r.Nombre),
			VigenciaInicio: r.VigenciaInicio,
			VigenciaFin:    r.VigenciaFin,
		})
	}
	for _, a := range u.Ambitos {
		d.Ambitos = append(d.Ambitos, ambitoDoc{
			Tipo: string(a.Tipo),
			ID:   a.ID,
		})
	}
	return d
}
