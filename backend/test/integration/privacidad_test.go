package integration

import (
	"context"
	"net/http"
	"testing"
	"time"

	"go.mongodb.org/mongo-driver/bson"

	"github.com/siaa/backend/internal/app"
)

// Criterio de la fase 4 (Ley 1581): un docente sin consentimiento no puede marcar, y las
// coordenadas más antiguas que la retención configurada quedan anonimizadas.
func TestPrivacidad_ConsentimientoYRetencion(t *testing.T) {
	e := nuevoEntorno(t)
	s := construirEscenarioSinConsentimiento(e, nil)

	// El aviso es público (RNF-LEG-003) y el estado inicial exige decidir.
	politica := e.exigir(http.MethodGet, "/privacidad/politica", nil, "", http.StatusOK)
	if politica["version"] == "" || politica["contenido"] == "" {
		t.Fatalf("la política debe traer versión y contenido: %v", politica)
	}
	estado := e.exigir(http.MethodGet, "/me/consentimiento", nil, s.docente, http.StatusOK)
	if estado["requiereAceptacion"] != true || estado["versionVigente"] != politica["version"] {
		t.Fatalf("sin decisión debe requerir aceptación de la versión vigente: %v", estado)
	}

	activa := e.exigir(http.MethodGet, "/me/sesiones/activa", nil, s.docente, http.StatusOK)
	sesionID := texto(activa["sesion"].(map[string]interface{})["id"])
	solicitud := s.marcaje(sesionID, 1.1477, -76.6511, "k-privacidad")
	sinConsentimiento := e.exigir(http.MethodPost, "/marcajes", solicitud, s.docente, http.StatusForbidden)
	if sinConsentimiento["codigo"] != "CONSENTIMIENTO_REQUERIDO" {
		t.Fatalf("el marcaje sin consentimiento debe rechazarse con CONSENTIMIENTO_REQUERIDO: %v", sinConsentimiento)
	}
	e.exigir(http.MethodPost, "/marcajes/sync", map[string]interface{}{"items": []interface{}{solicitud}}, s.docente, http.StatusForbidden)

	// Rechazar deja constancia y sigue bloqueando; una versión obsoleta es un conflicto.
	e.exigir(http.MethodPost, "/me/consentimiento", map[string]interface{}{"version": "0.1", "acepta": true}, s.docente, http.StatusConflict)
	rechazo := e.exigir(http.MethodPost, "/me/consentimiento", map[string]interface{}{
		"version": politica["version"], "acepta": false, "dispositivoId": s.dispositivo,
	}, s.docente, http.StatusOK)
	if rechazo["decision"] != "RECHAZADO" || rechazo["requiereAceptacion"] != true {
		t.Fatalf("el rechazo debe quedar registrado: %v", rechazo)
	}
	e.exigir(http.MethodPost, "/marcajes", solicitud, s.docente, http.StatusForbidden)
	// Consultar sigue permitido sin consentimiento (US-LEG-01 AC-05).
	e.exigir(http.MethodGet, "/me/historial", nil, s.docente, http.StatusOK)

	s.aceptarPrivacidad(e)
	creado := e.exigir(http.MethodPost, "/marcajes", solicitud, s.docente, http.StatusCreated)
	marcajeID := texto(creado["marcajeId"])
	if marcajeID == "" {
		t.Fatalf("tras aceptar, el marcaje debe registrarse: %v", creado)
	}
	if n := e.auditorias("CONSENTIMIENTO_ACEPTADO", ""); n != 1 {
		t.Fatalf("la aceptación debe auditarse, hay %d", n)
	}
	if n := e.auditorias("CONSENTIMIENTO_RECHAZADO", ""); n != 1 {
		t.Fatalf("el rechazo debe auditarse, hay %d", n)
	}

	// La retención solo se configura en ámbito GLOBAL.
	e.exigir(http.MethodPut, "/parametros", map[string]interface{}{
		"ambito": "SEDE", "ambito_id": s.sede, "clave": "retencion_coordenadas_dias", "valor": 60,
	}, s.admin, http.StatusUnprocessableEntity)
	e.exigir(http.MethodPut, "/parametros", map[string]interface{}{
		"ambito": "GLOBAL", "clave": "retencion_coordenadas_dias", "valor": 30,
	}, s.admin, http.StatusOK)

	worker := app.NuevoRetencionWorker(e.cliente)
	ctx := context.Background()
	if n, err := worker.EjecutarCiclo(ctx, time.Now().AddDate(0, 0, 10).UTC()); err != nil || n != 0 {
		t.Fatalf("dentro del plazo no se anonimiza nada: %d, %v", n, err)
	}
	if coordenadas(e, marcajeID) == nil {
		t.Fatal("el marcaje reciente debe conservar sus coordenadas")
	}
	if n, err := worker.EjecutarCiclo(ctx, time.Now().AddDate(0, 0, 31).UTC()); err != nil || n < 1 {
		t.Fatalf("pasado el plazo se anonimiza el marcaje: %d, %v", n, err)
	}
	if c := coordenadas(e, marcajeID); c != nil {
		t.Fatalf("las coordenadas vencidas deben quedar anonimizadas, quedan %v", c)
	}
	var doc bson.M
	if err := e.cliente.DB().Collection("marcajes").FindOne(ctx, bson.M{"_id": marcajeID}).Decode(&doc); err != nil {
		t.Fatalf("leer marcaje anonimizado: %v", err)
	}
	if doc["anonimizadoEn"] == nil || doc["resultado"] == nil {
		t.Fatalf("se conserva el resultado y se marca la anonimización: %v", doc)
	}
	// La copia del marcaje en la bitácora tampoco conserva la ubicación.
	conUbicacion, err := e.cliente.DB().Collection("auditoria").CountDocuments(ctx, bson.M{
		"entidad": "marcajes", "valorNuevo.geolocalizacion.coordenadas.0": bson.M{"$exists": true},
	})
	if err != nil || conUbicacion != 0 {
		t.Fatalf("la bitácora no debe conservar coordenadas vencidas: %d, %v", conUbicacion, err)
	}
	if n := e.auditorias("UBICACIONES_ANONIMIZADAS", ""); n != 1 {
		t.Fatalf("la anonimización debe auditarse, hay %d", n)
	}
	if n, err := worker.EjecutarCiclo(ctx, time.Now().AddDate(0, 0, 31).UTC()); err != nil || n != 0 {
		t.Fatalf("un segundo ciclo no repite la anonimización: %d, %v", n, err)
	}
}

// coordenadas devuelve las coordenadas guardadas de un marcaje (nil si fueron anonimizadas).
func coordenadas(e *entorno, marcajeID string) interface{} {
	e.t.Helper()
	var doc struct {
		Geo struct {
			Coordenadas interface{} `bson:"coordenadas"`
		} `bson:"geolocalizacion"`
	}
	if err := e.cliente.DB().Collection("marcajes").FindOne(context.Background(), bson.M{"_id": marcajeID}).Decode(&doc); err != nil {
		e.t.Fatalf("leer marcaje %s: %v", marcajeID, err)
	}
	return doc.Geo.Coordenadas
}
