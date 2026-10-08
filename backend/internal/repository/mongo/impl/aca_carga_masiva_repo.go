package impl

import (
	"context"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/mongo"

	"github.com/siaa/backend/internal/platform/security"
	"github.com/siaa/backend/internal/repository"
	mongoConn "github.com/siaa/backend/internal/repository/mongo"
)

// cargaMasivaRepo guarda el archivo original de cada carga (cifrado: trae documentos de
// docentes) junto con el actor y el resumen de resultados (US-ACA-07 AC-06).
type cargaMasivaRepo struct {
	col      *mongo.Collection
	cifrador *security.Cifrador
}

type cargaMasivaDoc struct {
	ID        string                 `bson:"_id"`
	Nombre    string                 `bson:"nombre"`
	Formato   string                 `bson:"formato"`
	Contenido []byte                 `bson:"contenido"`
	ActorID   string                 `bson:"actorId"`
	Resumen   map[string]interface{} `bson:"resumen"`
	CreadoEn  time.Time              `bson:"creadoEn"`
}

// NewCargaMasivaRepository crea el almacén de cargas masivas académicas.
func NewCargaMasivaRepository(client *mongoConn.Client, cifrador *security.Cifrador) repository.CargaMasivaRepository {
	return &cargaMasivaRepo{col: client.Collection("cargas_masivas"), cifrador: cifrador}
}

func (r *cargaMasivaRepo) Guardar(ctx context.Context, c *repository.CargaMasiva) error {
	cifrado, err := r.cifrador.Cifrar(c.Contenido)
	if err != nil {
		return err
	}
	doc := cargaMasivaDoc{ID: c.ID, Nombre: c.Nombre, Formato: c.Formato, Contenido: cifrado,
		ActorID: c.ActorID, Resumen: c.Resumen, CreadoEn: c.CreadoEn}
	if _, err := r.col.InsertOne(ctx, doc); err != nil {
		return fmt.Errorf("guardar carga masiva: %w", err)
	}
	return nil
}
