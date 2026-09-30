package integration

import (
	"context"
	"net/http"
	"testing"
	"time"

	"go.mongodb.org/mongo-driver/bson"
)

// Criterio de la fase 3: un marcaje offline sincronizado después del cierre revierte la
// ausencia automática, y un dispositivo con ubicación simulada queda auditado.
func TestMarcaje_OfflineTardioRevierteAusenciaYMockAuditado(t *testing.T) {
	e := nuevoEntorno(t)
	s := construirEscenario(e)
	activa := e.exigir(http.MethodGet, "/me/sesiones/activa", nil, s.docente, http.StatusOK)
	sesionID := texto(activa["sesion"].(map[string]interface{})["id"])

	// El docente marcó dentro del aula sin conexión; la cola guardó la hora de captura.
	capturado := s.marcaje(sesionID, 1.1477, -76.6511, "k-offline-tardio")

	// El worker cierra la ventana (día siguiente) y registra la ausencia.
	cierre := time.Now().Add(26 * time.Hour).UTC()
	generadas, err := e.app.AusenciasWorker.EjecutarCiclo(context.Background(), cierre)
	if err != nil || generadas < 1 {
		t.Fatalf("el worker debía generar la ausencia: %d, %v", generadas, err)
	}
	// Ciclo repetido: la marca de agua y la idempotencia evitan duplicados (ADR-09).
	if n, err := e.app.AusenciasWorker.EjecutarCiclo(context.Background(), cierre); err != nil || n != 0 {
		t.Fatalf("un segundo ciclo no debe generar ausencias: %d, %v", n, err)
	}
	ausencia := marcajeEntrada(e, s, sesionID, "AUSENTE")

	// La cola offline se sincroniza después del cierre.
	sync := e.exigir(http.MethodPost, "/marcajes/sync", map[string]interface{}{"items": []interface{}{capturado}}, s.docente, http.StatusOK)
	resultados, _ := sync["resultados"].([]interface{})
	item, _ := resultados[0].(map[string]interface{})
	if item["exitoso"] != true {
		t.Fatalf("el marcaje offline debía ser válido: %v", sync)
	}
	vigente := marcajeEntrada(e, s, sesionID, "")
	if vigente["origen"] != "OFFLINE" || vigente["ajusteDe"] != ausencia["id"] {
		t.Fatalf("el marcaje offline debe reemplazar a la ausencia: %v", vigente)
	}
	for _, m := range elementos(e.exigir(http.MethodGet, "/marcajes?sesionId="+sesionID+"&tipo=ENTRADA", nil, s.admin, http.StatusOK)) {
		if m["id"] == ausencia["id"] && (m["resultado"] != "AUSENTE" || m["reemplazadoPor"] != vigente["id"]) {
			t.Fatalf("la ausencia debe conservarse apuntando al reemplazo: %v", m)
		}
	}
	if estado := e.exigir(http.MethodGet, "/sesiones/"+sesionID, nil, s.admin, http.StatusOK)["estado"]; estado != "REALIZADA" {
		t.Fatalf("la sesión debe quedar REALIZADA, está %v", estado)
	}
	if n := e.auditorias("AUSENCIA_REVERTIDA_OFFLINE", texto(ausencia["id"])); n != 1 {
		t.Fatalf("la reversión debe auditarse, hay %d", n)
	}
	// Reenviar la misma cola no duplica ni vuelve a revertir.
	e.exigir(http.MethodPost, "/marcajes/sync", map[string]interface{}{"items": []interface{}{capturado}}, s.docente, http.StatusOK)
	if n := e.auditorias("AUSENCIA_REVERTIDA_OFFLINE", ""); n != 1 {
		t.Fatalf("reenviar la cola no debe revertir de nuevo, hay %d", n)
	}

	// Un intento con ubicación simulada sobre la sesión ya marcada queda auditado.
	mock := s.marcaje(sesionID, 1.1477, -76.6511, "k-mock-posterior")
	mock["integridad"] = map[string]interface{}{"mockLocation": true, "rooteado": false, "emulador": false, "attestationOk": true}
	e.exigir(http.MethodPost, "/marcajes", mock, s.docente, http.StatusCreated)
	if n := e.auditorias("MARCAJE_INTENTO_INTEGRIDAD", texto(vigente["id"])); n != 1 {
		t.Fatalf("el intento con mock debe auditarse aunque el marcaje exista, hay %d", n)
	}
	var marca bson.M
	if err := e.cliente.DB().Collection("procesos").FindOne(context.Background(), bson.M{"_id": "ausencias"}).Decode(&marca); err != nil {
		t.Fatalf("el worker debe guardar su marca de agua: %v", err)
	}
}

// marcajeEntrada devuelve la entrada vigente (consolidada) de la sesión, con el resultado pedido si se indica.
func marcajeEntrada(e *entorno, s *escenario, sesionID, resultado string) map[string]interface{} {
	e.t.Helper()
	for _, m := range elementos(e.exigir(http.MethodGet, "/marcajes?sesionId="+sesionID+"&tipo=ENTRADA", nil, s.admin, http.StatusOK)) {
		if m["consolidado"] == true && (resultado == "" || m["resultado"] == resultado) {
			return m
		}
	}
	e.t.Fatalf("no hay entrada vigente %q en la sesión %s", resultado, sesionID)
	return nil
}
