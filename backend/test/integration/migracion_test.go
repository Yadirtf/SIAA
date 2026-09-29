package integration

import (
	"context"
	"net/http"
	"testing"

	"go.mongodb.org/mongo-driver/bson"

	"github.com/siaa/backend/internal/repository/mongo/migrations"
)

// Las sesiones y marcajes previos al alcance ABAC recuperan sede y facultad al migrar.
func TestMigracion_UbicacionAlcance(t *testing.T) {
	e := nuevoEntorno(t)
	s := construirEscenario(e)
	_, sesiones := e.llamar(http.MethodGet, "/sesiones?periodoId="+s.periodo, nil, s.admin)
	sesionID := texto(elementos(sesiones)[0]["id"])
	e.exigir(http.MethodPost, "/marcajes/manual", map[string]interface{}{
		"sesionId": sesionID, "usuarioId": s.docenteID, "tipo": "ENTRADA", "resultado": "PRESENTE",
		"motivo": "Registro manual por falla del dispositivo",
	}, s.admin, http.StatusCreated)

	ctx := context.Background()
	db := e.cliente.DB()
	quitar := bson.M{"$unset": bson.M{"sedeId": "", "facultadId": ""}}
	for _, col := range []string{"sesiones", "marcajes"} {
		if _, err := db.Collection(col).UpdateMany(ctx, bson.M{}, quitar); err != nil {
			t.Fatalf("preparar %s: %v", col, err)
		}
	}
	if err := migrations.MigrarUbicacionAlcance(ctx, db); err != nil {
		t.Fatalf("migrar: %v", err)
	}
	for _, col := range []string{"sesiones", "marcajes"} {
		var doc bson.M
		if err := db.Collection(col).FindOne(ctx, bson.M{}).Decode(&doc); err != nil {
			t.Fatalf("leer %s: %v", col, err)
		}
		if doc["facultadId"] != s.facultad || doc["sedeId"] != s.sede {
			t.Fatalf("%s sin ubicación tras migrar: facultad=%v sede=%v", col, doc["facultadId"], doc["sedeId"])
		}
	}
}
