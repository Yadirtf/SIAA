// Package impl — Repositorio MongoDB para roles y permisos (US-ROL-03).
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
	"github.com/siaa/backend/internal/repository"
	mongoConn "github.com/siaa/backend/internal/repository/mongo"
)

type rolDoc struct {
	ID            primitive.ObjectID `bson:"_id,omitempty"`
	Nombre        string             `bson:"nombre"`
	Descripcion   string             `bson:"descripcion"`
	Permisos      []string           `bson:"permisos"`
	EsPredefinido bool               `bson:"esPredefinido"`
	CreadoEn      time.Time          `bson:"creadoEn"`
	ActualizadoEn time.Time          `bson:"actualizadoEn"`
}

type rolRepository struct {
	col         *mongo.Collection
	colUsuarios *mongo.Collection
}

func NewRolRepository(client *mongoConn.Client) repository.RolRepository {
	return &rolRepository{
		col:         client.Collection("roles"),
		colUsuarios: client.Collection("usuarios"),
	}
}

func (r *rolRepository) Listar(ctx context.Context) ([]*rbac.Rol, error) {
	cursor, err := r.col.Find(ctx, bson.M{})
	if err != nil {
		return nil, fmt.Errorf("listar roles: %w", err)
	}
	defer cursor.Close(ctx)

	var docs []rolDoc
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decodificar roles: %w", err)
	}

	result := make([]*rbac.Rol, 0, len(docs))
	for _, d := range docs {
		result = append(result, docToRol(d))
	}
	return result, nil
}

func (r *rolRepository) FindByID(ctx context.Context, id string) (*rbac.Rol, error) {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, errors.New("identificador de rol inválido")
	}

	var d rolDoc
	if err := r.col.FindOne(ctx, bson.M{"_id": oid}).Decode(&d); err != nil {
		if errors.Is(err, mongo.ErrNoDocuments) {
			return nil, nil
		}
		return nil, fmt.Errorf("buscar rol por ID: %w", err)
	}
	return docToRol(d), nil
}

func (r *rolRepository) FindByNombre(ctx context.Context, nombre string) (*rbac.Rol, error) {
	var d rolDoc
	if err := r.col.FindOne(ctx, bson.M{"nombre": nombre}).Decode(&d); err != nil {
		if errors.Is(err, mongo.ErrNoDocuments) {
			return nil, nil
		}
		return nil, fmt.Errorf("buscar rol por nombre: %w", err)
	}
	return docToRol(d), nil
}

func (r *rolRepository) Create(ctx context.Context, rol *rbac.Rol) error {
	pStrings := make([]string, len(rol.Permisos))
	for i, p := range rol.Permisos {
		pStrings[i] = string(p)
	}

	doc := rolDoc{
		Nombre:        rol.Nombre,
		Descripcion:   rol.Descripcion,
		Permisos:      pStrings,
		EsPredefinido: rol.EsPredefinido,
		CreadoEn:      rol.CreadoEn,
		ActualizadoEn: rol.ActualizadoEn,
	}

	res, err := r.col.InsertOne(ctx, doc)
	if err != nil {
		return fmt.Errorf("insertar rol: %w", err)
	}
	rol.ID = res.InsertedID.(primitive.ObjectID).Hex()
	return nil
}

func (r *rolRepository) Update(ctx context.Context, rol *rbac.Rol) error {
	oid, err := primitive.ObjectIDFromHex(rol.ID)
	if err != nil {
		return errors.New("identificador de rol inválido")
	}

	pStrings := make([]string, len(rol.Permisos))
	for i, p := range rol.Permisos {
		pStrings[i] = string(p)
	}

	update := bson.M{
		"$set": bson.M{
			"descripcion":   rol.Descripcion,
			"permisos":      pStrings,
			"actualizadoEn": rol.ActualizadoEn,
		},
	}

	_, err = r.col.UpdateOne(ctx, bson.M{"_id": oid}, update)
	if err != nil {
		return fmt.Errorf("actualizar rol: %w", err)
	}
	return nil
}

func (r *rolRepository) Delete(ctx context.Context, id string) error {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return errors.New("identificador de rol inválido")
	}

	_, err = r.col.DeleteOne(ctx, bson.M{"_id": oid})
	if err != nil {
		return fmt.Errorf("eliminar rol: %w", err)
	}
	return nil
}

func (r *rolRepository) CountUsuariosConRol(ctx context.Context, nombre string) (int, error) {
	if r.colUsuarios == nil {
		return 0, nil
	}
	count, err := r.colUsuarios.CountDocuments(ctx, bson.M{
		"roles.nombre": nombre,
		"eliminado":    false,
	})
	if err != nil {
		return 0, fmt.Errorf("contar usuarios con rol: %w", err)
	}
	return int(count), nil
}

func docToRol(d rolDoc) *rbac.Rol {
	perms := make([]rbac.Permission, len(d.Permisos))
	for i, p := range d.Permisos {
		perms[i] = rbac.Permission(p)
	}
	return &rbac.Rol{
		ID:            d.ID.Hex(),
		Nombre:        d.Nombre,
		Descripcion:   d.Descripcion,
		Permisos:      perms,
		EsPredefinido: d.EsPredefinido,
		CreadoEn:      d.CreadoEn,
		ActualizadoEn: d.ActualizadoEn,
	}
}
