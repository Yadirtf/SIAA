package integration

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"go.mongodb.org/mongo-driver/bson"

	"github.com/siaa/backend/internal/app"
)

const agentePrueba = "SIAA-Pruebas/1.0 (integracion)"

// llamarConAgente envía la petición con User-Agent y X-Forwarded-For desde la red privada
// (Traefik), como llega en producción.
func (e *entorno) llamarConAgente(metodo, ruta string, cuerpo interface{}, token string) (int, map[string]interface{}) {
	e.t.Helper()
	b, _ := json.Marshal(cuerpo)
	req := httptest.NewRequest(metodo, "/api/v1"+ruta, bytes.NewReader(b))
	req.RemoteAddr = "10.0.0.5:4321"
	req.Header.Set("X-Forwarded-For", "181.50.10.20")
	req.Header.Set("User-Agent", agentePrueba)
	req.Header.Set("Content-Type", "application/json")
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}
	rec := httptest.NewRecorder()
	e.app.Router.ServeHTTP(rec, req)
	var datos map[string]interface{}
	_ = json.Unmarshal(rec.Body.Bytes(), &datos)
	return rec.Code, datos
}

func (e *entorno) entradaAuditoria(filtro bson.M) bson.M {
	e.t.Helper()
	var doc bson.M
	if err := e.cliente.DB().Collection("auditoria").FindOne(context.Background(), filtro).Decode(&doc); err != nil {
		e.t.Fatalf("no se encontró la entrada de auditoría %v: %v", filtro, err)
	}
	return doc
}

// US-AUD-01 AC-01/AC-02: el cambio de un parámetro queda auditado con actor, rol activo, valor
// anterior y nuevo, IP y agente de usuario; toda entrada de la petición lleva esos datos.
func TestAuditoria_ParametrosConOrigenCompleto(t *testing.T) {
	e := nuevoEntorno(t)
	s := construirEscenario(e)

	for _, valor := range []int{20, 25} {
		if code, d := e.llamarConAgente(http.MethodPut, "/parametros", map[string]interface{}{
			"ambito": "SEDE", "ambito_id": s.sede, "clave": "holgura_entrada_antes_min", "valor": valor,
		}, s.admin); code != http.StatusOK {
			t.Fatalf("guardar parámetro: %d %v", code, d)
		}
	}
	doc := e.entradaAuditoria(bson.M{"accion": "PARAMETRO_ACTUALIZADO", "valorNuevo.valor": 25})
	if doc["ipOrigen"] != "181.50.10.20" || doc["agenteUsuario"] != agentePrueba {
		t.Fatalf("la entrada debe traer IP y agente de usuario: %v", doc)
	}
	if doc["rolActivo"] == nil || doc["rolActivo"] == "" || doc["actorId"] == "" || doc["correlationId"] == "" {
		t.Fatalf("la entrada debe traer actor, rol activo y correlationId: %v", doc)
	}
	anterior, _ := doc["valorAnterior"].(bson.M)
	nuevo, _ := doc["valorNuevo"].(bson.M)
	if fmt.Sprint(anterior["valor"]) != "20" || nuevo["clave"] != "holgura_entrada_antes_min" || nuevo["ambito"] != "SEDE" {
		t.Fatalf("se esperaba 20 → 25 en la clave y ámbito auditados: %v → %v", anterior, nuevo)
	}

	// Un rechazo sin sesión (login fallido) también queda con origen y rol SIN_SESION.
	e.llamarConAgente(http.MethodPost, "/auth/login", map[string]interface{}{"correo": correoDocente, "password": "mala-clave-123"}, "")
	n, err := e.cliente.DB().Collection("auditoria").CountDocuments(context.Background(), bson.M{
		"$or": bson.A{
			bson.M{"rolActivo": bson.M{"$in": bson.A{nil, ""}}},
			bson.M{"agenteUsuario": agentePrueba, "ipOrigen": bson.M{"$ne": "181.50.10.20"}},
		},
	})
	if err != nil || n != 0 {
		t.Fatalf("ninguna entrada puede quedar sin rol activo ni con IP distinta: %d %v", n, err)
	}
}

// US-AUD-04 AC-03: con una investigación en curso sobre el docente, su marcaje vencido no se
// anonimiza; se audita la suspensión y se avisa a quien la marcó. Al liberarla, se anonimiza.
func TestRetencion_SuspendidaPorInvestigacion(t *testing.T) {
	e := nuevoEntorno(t)
	s := construirEscenario(e)
	activa := e.exigir(http.MethodGet, "/me/sesiones/activa", nil, s.docente, http.StatusOK)
	sesionID := texto(activa["sesion"].(map[string]interface{})["id"])
	creado := e.exigir(http.MethodPost, "/marcajes", s.marcaje(sesionID, 1.1477, -76.6511, "k-investigacion"), s.docente, http.StatusCreated)
	marcajeID := texto(creado["marcajeId"])

	// Validación y permiso: el docente no puede marcar investigaciones.
	e.exigir(http.MethodPost, "/privacidad/investigaciones", map[string]interface{}{
		"alcance": "USUARIO", "objetivoId": s.docenteID, "motivo": "Queja disciplinaria 42",
	}, s.docente, http.StatusForbidden)
	e.exigir(http.MethodPost, "/privacidad/investigaciones", map[string]interface{}{"alcance": "OTRO", "objetivoId": "x", "motivo": "corto"}, s.admin, http.StatusUnprocessableEntity)

	inv := e.exigir(http.MethodPost, "/privacidad/investigaciones", map[string]interface{}{
		"alcance": "USUARIO", "objetivoId": s.docenteID, "motivo": "Queja disciplinaria 42",
	}, s.admin, http.StatusCreated)
	invID := texto(inv["id"])
	if lista := e.exigir(http.MethodGet, "/privacidad/investigaciones", nil, s.admin, http.StatusOK); len(elementos(lista)) != 1 {
		t.Fatalf("debe listarse la investigación activa: %v", lista)
	}
	if e.auditorias("INVESTIGACION_MARCADA", invID) != 1 {
		t.Fatal("marcar la investigación debe auditarse")
	}

	worker := app.NuevoRetencionWorker(e.cliente)
	ctx := context.Background()
	vencido := time.Now().AddDate(2, 0, 0).UTC()
	if n, err := worker.EjecutarCiclo(ctx, vencido); err != nil || n != 0 {
		t.Fatalf("bajo investigación no se anonimiza: %d, %v", n, err)
	}
	if coordenadas(e, marcajeID) == nil {
		t.Fatal("el marcaje bajo investigación debe conservar sus coordenadas")
	}
	sus := e.entradaAuditoria(bson.M{"accion": "RETENCION_SUSPENDIDA", "entidadId": invID})
	if v, _ := sus["valorNuevo"].(bson.M); v["registrosRetenidos"] != int64(1) || sus["rolActivo"] != "SISTEMA" {
		t.Fatalf("la suspensión debe auditarse con el volumen retenido: %v", sus)
	}
	avisos, err := e.cliente.DB().Collection("notificaciones").CountDocuments(ctx, bson.M{"tipo": "RETENCION_SUSPENDIDA"})
	if err != nil || avisos != 1 {
		t.Fatalf("se debe avisar a quien marcó la investigación: %d, %v", avisos, err)
	}
	// Un segundo ciclo el mismo día no repite el aviso ni la entrada.
	if _, err := worker.EjecutarCiclo(ctx, vencido); err != nil || e.auditorias("RETENCION_SUSPENDIDA", invID) != 1 {
		t.Fatalf("la suspensión se registra una vez por día: %v", err)
	}

	e.exigir(http.MethodPost, "/privacidad/investigaciones/"+invID+"/liberar", nil, s.admin, http.StatusOK)
	e.exigir(http.MethodPost, "/privacidad/investigaciones/"+invID+"/liberar", nil, s.admin, http.StatusConflict)
	if e.auditorias("INVESTIGACION_LIBERADA", invID) != 1 {
		t.Fatal("liberar la investigación debe auditarse")
	}
	if n, err := worker.EjecutarCiclo(ctx, vencido); err != nil || n < 1 {
		t.Fatalf("liberada la investigación, se anonimiza: %d, %v", n, err)
	}
	if coordenadas(e, marcajeID) != nil {
		t.Fatal("tras liberar, las coordenadas vencidas deben anonimizarse")
	}
}

// US-PLT-05 AC-01: /metrics refleja los comandos y el pool de MongoDB y los resultados de marcaje.
func TestMetricas_BaseDatosYResultadosMarcaje(t *testing.T) {
	e := nuevoEntorno(t)
	s := construirEscenario(e)
	activa := e.exigir(http.MethodGet, "/me/sesiones/activa", nil, s.docente, http.StatusOK)
	sesionID := texto(activa["sesion"].(map[string]interface{})["id"])
	e.exigir(http.MethodPost, "/marcajes", s.marcaje(sesionID, 1.1477, -76.6511, "k-metricas"), s.docente, http.StatusCreated)

	m := e.exigir(http.MethodGet, "/metrics", nil, "", http.StatusOK)
	db, _ := m["baseDatos"].(map[string]interface{})
	if total, _ := db["comandosTotal"].(float64); total < 1 {
		t.Fatalf("baseDatos debe contar los comandos ejecutados: %v", db)
	}
	if lat, _ := db["latenciaComandos"].(map[string]interface{}); lat["p95Ms"] == nil {
		t.Fatalf("baseDatos debe traer la latencia de comandos: %v", db)
	}
	if maximo, _ := db["conexionesMaximas"].(float64); maximo != 100 {
		t.Fatalf("baseDatos debe informar el tamaño del pool: %v", db)
	}
	resultados, _ := m["resultadosMarcaje"].(map[string]interface{})
	if len(resultados) == 0 {
		t.Fatalf("resultadosMarcaje debe contar el marcaje registrado: %v", m["resultadosMarcaje"])
	}
}
