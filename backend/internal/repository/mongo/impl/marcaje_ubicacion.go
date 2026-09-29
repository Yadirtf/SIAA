package impl

import (
	"context"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo/options"

	"github.com/siaa/backend/internal/domain/marcaje"
)

// completarUbicacion copia al marcaje la sede, la facultad y el aula de su sesión, para que
// los listados apliquen el alcance ABAC sin cruzar colecciones (RF-ROL-003). Todos los
// orígenes (app, manual, lista, ausencia automática) pasan por aquí.
func (r *marcajeMongoRepo) completarUbicacion(ctx context.Context, m *marcaje.Marcaje) {
	if m.SedeID != "" && m.FacultadID != "" {
		return
	}
	oid, err := primitive.ObjectIDFromHex(m.SesionID)
	if err != nil {
		return
	}
	var s struct {
		SedeID     string `bson:"sedeId"`
		FacultadID string `bson:"facultadId"`
		EspacioID  string `bson:"espacioId"`
	}
	proy := options.FindOne().SetProjection(bson.M{"sedeId": 1, "facultadId": 1, "espacioId": 1})
	if err := r.db.Collection("sesiones").FindOne(ctx, bson.M{"_id": oid}, proy).Decode(&s); err != nil {
		return
	}
	if m.SedeID == "" {
		m.SedeID = s.SedeID
	}
	if m.FacultadID == "" {
		m.FacultadID = s.FacultadID
	}
	if m.EspacioID == "" {
		m.EspacioID = s.EspacioID
	}
}
