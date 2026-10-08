package impl

import (
	"context"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"

	"github.com/siaa/backend/internal/repository"
	mongoConn "github.com/siaa/backend/internal/repository/mongo"
)

// grupoEstudiantesRepo persiste un documento por pareja grupo–estudiante en la colección
// grupo_estudiantes (índice único grupoId+estudianteId).
type grupoEstudiantesRepo struct {
	col *mongo.Collection
}

type grupoEstudianteDoc struct {
	GrupoID      string    `bson:"grupoId"`
	EstudianteID string    `bson:"estudianteId"`
	AsignadoPor  string    `bson:"asignadoPor"`
	AsignadoEn   time.Time `bson:"asignadoEn"`
}

// NewGrupoEstudiantesRepository crea el repositorio de integrantes de grupo.
func NewGrupoEstudiantesRepository(client *mongoConn.Client) repository.GrupoEstudiantesRepository {
	return &grupoEstudiantesRepo{col: client.Collection("grupo_estudiantes")}
}

func (r *grupoEstudiantesRepo) Listar(ctx context.Context, grupoID string) ([]string, error) {
	return r.distintos(ctx, "estudianteId", bson.M{"grupoId": grupoID})
}

func (r *grupoEstudiantesRepo) GruposDeEstudiante(ctx context.Context, estudianteID string) ([]string, error) {
	return r.distintos(ctx, "grupoId", bson.M{"estudianteId": estudianteID})
}

func (r *grupoEstudiantesRepo) Pertenece(ctx context.Context, grupoID, estudianteID string) (bool, error) {
	n, err := r.col.CountDocuments(ctx, bson.M{"grupoId": grupoID, "estudianteId": estudianteID})
	return n > 0, err
}

func (r *grupoEstudiantesRepo) Reemplazar(ctx context.Context, grupoID string, ids []string, actorID string, ahora time.Time) error {
	if ids == nil {
		ids = []string{}
	}
	if _, err := r.col.DeleteMany(ctx, bson.M{"grupoId": grupoID, "estudianteId": bson.M{"$nin": ids}}); err != nil {
		return fmt.Errorf("retirar estudiantes del grupo: %w", err)
	}
	actuales, err := r.Listar(ctx, grupoID)
	if err != nil {
		return err
	}
	ya := make(map[string]bool, len(actuales))
	for _, id := range actuales {
		ya[id] = true
	}
	nuevos := make([]interface{}, 0, len(ids))
	for _, id := range ids {
		if !ya[id] {
			ya[id] = true
			nuevos = append(nuevos, grupoEstudianteDoc{GrupoID: grupoID, EstudianteID: id, AsignadoPor: actorID, AsignadoEn: ahora})
		}
	}
	if len(nuevos) == 0 {
		return nil
	}
	if _, err := r.col.InsertMany(ctx, nuevos); err != nil && !mongo.IsDuplicateKeyError(err) {
		return fmt.Errorf("agregar estudiantes al grupo: %w", err)
	}
	return nil
}

func (r *grupoEstudiantesRepo) distintos(ctx context.Context, campo string, filtro bson.M) ([]string, error) {
	valores, err := r.col.Distinct(ctx, campo, filtro)
	if err != nil {
		return nil, fmt.Errorf("listar integrantes de grupo: %w", err)
	}
	res := make([]string, 0, len(valores))
	for _, v := range valores {
		if s, ok := v.(string); ok {
			res = append(res, s)
		}
	}
	return res, nil
}
