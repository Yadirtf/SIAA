// Package impl — búsqueda paginada de usuarios para la gestión administrativa.
package impl

import (
	"context"
	"errors"
	"fmt"
	"regexp"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"

	"github.com/siaa/backend/internal/domain/user"
	"github.com/siaa/backend/internal/repository"
)

func (r *usuarioRepository) FindByDocumento(ctx context.Context, documento string) (*user.Usuario, error) {
	var doc usuarioDoc
	err := r.col.FindOne(ctx, bson.M{"documento": documento, "eliminado": false}).Decode(&doc)
	if errors.Is(err, mongo.ErrNoDocuments) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("findByDocumento: %w", err)
	}
	return docToUsuario(&doc), nil
}

func (r *usuarioRepository) Buscar(ctx context.Context, f repository.FiltroUsuarios) ([]*user.Usuario, int64, error) {
	filtro := filtroUsuarios(f)
	total, err := r.col.CountDocuments(ctx, filtro)
	if err != nil {
		return nil, 0, fmt.Errorf("contar usuarios: %w", err)
	}
	limite := f.Limite
	if limite <= 0 || limite > 200 {
		limite = 50
	}
	pagina := f.Pagina
	if pagina <= 0 {
		pagina = 1
	}
	opts := options.Find().
		SetSort(bson.D{{Key: "nombre", Value: 1}, {Key: "apellido", Value: 1}}).
		SetSkip(int64((pagina - 1) * limite)).
		SetLimit(int64(limite))
	cursor, err := r.col.Find(ctx, filtro, opts)
	if err != nil {
		return nil, 0, fmt.Errorf("buscar usuarios: %w", err)
	}
	defer cursor.Close(ctx)
	var docs []usuarioDoc
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, 0, fmt.Errorf("decodificar usuarios: %w", err)
	}
	res := make([]*user.Usuario, len(docs))
	for i := range docs {
		res[i] = docToUsuario(&docs[i])
	}
	return res, total, nil
}

func filtroUsuarios(f repository.FiltroUsuarios) bson.M {
	filtro := bson.M{"eliminado": false}
	var y []bson.M
	if f.Texto != "" {
		re := regexTexto(f.Texto)
		y = append(y, bson.M{"$or": []bson.M{
			{"nombre": re}, {"apellido": re}, {"correo": re}, {"documento": re},
		}})
	}
	if f.Rol != "" {
		filtro["roles.nombre"] = f.Rol
	}
	if f.Activo != nil {
		filtro["activo"] = *f.Activo
	}
	if v := f.Visibilidad; v != nil {
		y = append(y, bson.M{"$or": []bson.M{
			{"ambitos.id": bson.M{"$in": noNulo(v.AmbitoIDs)}},
			{"roles.nombre": bson.M{"$in": noNulo(v.RolesVisibles)}},
		}})
	}
	if len(y) > 0 {
		filtro["$and"] = y
	}
	return filtro
}

// regexTexto construye una expresión insensible a mayúsculas con el texto escapado.
func regexTexto(texto string) bson.M {
	return bson.M{"$regex": regexp.QuoteMeta(texto), "$options": "i"}
}

func noNulo(v []string) []string {
	if v == nil {
		return []string{}
	}
	return v
}
