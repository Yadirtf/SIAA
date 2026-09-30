package integration

import (
	"context"
	"net/http"
	"testing"
	"time"
)

// Flujo principal del docente (EP-06): sesión activa, rechazo fuera del aula, marcaje válido,
// idempotencia, historial y consultas administrativas.
func TestMarcaje_FlujoDocenteCompleto(t *testing.T) {
	e := nuevoEntorno(t)
	s := construirEscenario(e)

	hoy := e.exigir(http.MethodGet, "/me/sesiones/hoy", nil, s.docente, http.StatusOK)
	if len(elementos(hoy)) != 1 {
		t.Fatalf("se esperaba 1 sesión hoy: %v", hoy)
	}
	activa := e.exigir(http.MethodGet, "/me/sesiones/activa", nil, s.docente, http.StatusOK)
	sesion, _ := activa["sesion"].(map[string]interface{})
	sesionID := texto(sesion["id"])
	if sesionID == "" {
		t.Fatalf("no hay sesión activa: %v", activa)
	}
	parametros, _ := activa["parametros"].(map[string]interface{})
	if parametros["holguraEntradaDespuesMin"] != float64(20) {
		t.Fatalf("la holgura de la sede (20) no se congeló en la sesión: %v", parametros)
	}

	// Un primer intento a ~33 m del aula se rechaza, pero no bloquea el marcaje posterior (ADR-07).
	fuera := e.exigir(http.MethodPost, "/marcajes", s.marcaje(sesionID, 1.1481, -76.6511, "k-fuera"), s.docente, http.StatusCreated)
	if fuera["resultado"] != "RECHAZADO_FUERA_DE_AREA" {
		t.Fatalf("resultado fuera del aula: %v", fuera)
	}
	dentro := e.exigir(http.MethodPost, "/marcajes", s.marcaje(sesionID, 1.1477, -76.6511, "k-dentro"), s.docente, http.StatusCreated)
	if dentro["resultado"] != "PRESENTE" {
		t.Fatalf("resultado dentro del aula: %v", dentro)
	}
	repetido := e.exigir(http.MethodPost, "/marcajes", s.marcaje(sesionID, 1.1477, -76.6511, "k-dentro"), s.docente, http.StatusCreated)
	if repetido["marcajeId"] != dentro["marcajeId"] {
		t.Fatalf("el marcaje repetido debe devolver el existente: %v vs %v", repetido, dentro)
	}

	historial := e.exigir(http.MethodGet, "/me/historial?limite=10&pagina=1", nil, s.docente, http.StatusOK)
	if len(elementos(historial)) == 0 {
		t.Fatalf("historial vacío: %v", historial)
	}
	e.exigir(http.MethodGet, "/me/historial?mes="+time.Now().In(bogota).Format("2006-01"), nil, s.docente, http.StatusOK)

	listado := e.exigir(http.MethodGet, "/marcajes?sesionId="+sesionID+"&tipo=ENTRADA&pagina=1&limite=20", nil, s.admin, http.StatusOK)
	if len(elementos(listado)) == 0 {
		t.Fatalf("el admin no ve los marcajes de la sesión: %v", listado)
	}
	desde := time.Now().Add(-24 * time.Hour).UTC().Format(time.RFC3339)
	hasta := time.Now().Add(24 * time.Hour).UTC().Format(time.RFC3339)
	e.exigir(http.MethodGet, "/marcajes?resultado=PRESENTE&desde="+desde+"&hasta="+hasta, nil, s.admin, http.StatusOK)

	// RF-ROL-003: el docente solo ve sus propios marcajes aunque pida los de otro usuario.
	propios := e.exigir(http.MethodGet, "/marcajes?usuarioId=otro-usuario", nil, s.docente, http.StatusOK)
	for _, m := range elementos(propios) {
		if m["usuarioId"] != s.docenteID {
			t.Fatalf("el docente vio un marcaje ajeno: %v", m)
		}
	}
	if len(elementos(propios)) == 0 {
		t.Fatalf("el docente debe ver sus propios marcajes: %v", propios)
	}
	// Sin token no hay acceso.
	if estado, _ := e.llamar(http.MethodGet, "/me/historial", nil, ""); estado != http.StatusUnauthorized {
		t.Fatalf("GET /me/historial sin token: estado %d, esperado 401", estado)
	}

	// Ajuste administrativo (US-MAR-09): motivo corto rechazado, válido aceptado.
	id := texto(dentro["marcajeId"])
	e.sinErrorInterno(http.MethodPatch, "/marcajes/"+id, map[string]interface{}{"accion": "AJUSTAR", "nuevoResultado": "TARDANZA", "motivo": "corto"}, s.admin)
	ajuste := e.exigir(http.MethodPatch, "/marcajes/"+id, map[string]interface{}{
		"accion": "AJUSTAR", "nuevoResultado": "TARDANZA", "motivo": "Ajuste por verificación de cámaras del bloque",
	}, s.admin, http.StatusOK)
	// RF-JUS-004: el ajuste es un evento nuevo y el original conserva su resultado.
	if ajuste["id"] == id || ajuste["ajusteDe"] != id || ajuste["origen"] != "AJUSTE" || ajuste["resultado"] != "TARDANZA" {
		t.Fatalf("el ajuste debe ser un evento nuevo que apunte al original: %v", ajuste)
	}
	for _, m := range elementos(e.exigir(http.MethodGet, "/marcajes?sesionId="+sesionID, nil, s.admin, http.StatusOK)) {
		if m["id"] == id && (m["resultado"] == "TARDANZA" || m["reemplazadoPor"] != ajuste["id"]) {
			t.Fatalf("el marcaje original no debe modificarse: %v", m)
		}
	}
	e.exigir(http.MethodPatch, "/marcajes/"+id, map[string]interface{}{
		"accion": "AJUSTAR", "nuevoResultado": "PRESENTE", "motivo": "Segundo ajuste sobre el evento ya reemplazado",
	}, s.admin, http.StatusConflict)
	e.sinErrorInterno(http.MethodPatch, "/marcajes/000000000000000000000000", map[string]interface{}{
		"accion": "ANULAR", "anulado": true, "motivo": "Anulación de un marcaje que no existe en la base",
	}, s.admin)

	// Marcaje manual de respaldo y ventana estudiantil / lista manual (US-MAR-09, 13, 14).
	e.sinErrorInterno(http.MethodPost, "/marcajes/manual", map[string]interface{}{
		"sesionId": sesionID, "usuarioId": s.docenteID, "tipo": "SALIDA", "resultado": "VALIDO",
		"motivo": "Falla del GPS del dispositivo del docente",
	}, s.admin)
	e.sinErrorInterno(http.MethodPost, "/sesiones/"+sesionID+"/ventana-estudiantil", map[string]interface{}{"duracionMinutos": 10}, s.admin)
	e.sinErrorInterno(http.MethodPost, "/sesiones/"+sesionID+"/lista-manual", map[string]interface{}{
		"motivo":      "Lista tomada en papel por caída de red",
		"estudiantes": []map[string]interface{}{{"estudianteId": s.docenteID, "presente": true}},
	}, s.admin)

	// Sincronización offline (US-MAR-10): un lote con el marcaje ya registrado y uno inválido.
	e.sinErrorInterno(http.MethodPost, "/marcajes/sync", map[string]interface{}{
		"items": []map[string]interface{}{
			s.marcaje(sesionID, 1.1477, -76.6511, "k-offline-1"),
			s.marcaje("000000000000000000000000", 1.1477, -76.6511, "k-offline-2"),
		},
	}, s.docente)

	// Worker de ausencias (US-MAR-07) al cierre del día: no debe fallar con sesiones consolidadas.
	if _, err := e.app.AusenciasWorker.EjecutarCiclo(context.Background(), time.Now().Add(26*time.Hour).UTC()); err != nil {
		t.Fatalf("worker de ausencias: %v", err)
	}
}

// Un dispositivo que reporta ubicación simulada se rechaza por integridad (RF-MAR, paso de integridad).
func TestMarcaje_RechazaUbicacionSimulada(t *testing.T) {
	e := nuevoEntorno(t)
	s := construirEscenario(e)
	activa := e.exigir(http.MethodGet, "/me/sesiones/activa", nil, s.docente, http.StatusOK)
	sesionID := texto(activa["sesion"].(map[string]interface{})["id"])

	solicitud := s.marcaje(sesionID, 1.1477, -76.6511, "k-mock")
	solicitud["integridad"] = map[string]interface{}{"mockLocation": true, "rooteado": false, "emulador": false, "attestationOk": true}
	r := e.exigir(http.MethodPost, "/marcajes", solicitud, s.docente, http.StatusCreated)
	if r["resultado"] != "RECHAZADO_INTEGRIDAD" {
		t.Fatalf("ubicación simulada: %v", r)
	}
	// Una sesión inexistente se rechaza sin error interno.
	e.sinErrorInterno(http.MethodPost, "/marcajes", s.marcaje("000000000000000000000000", 1.1477, -76.6511, "k-x"), s.docente)
	// Cuerpo inválido.
	if estado, _ := e.llamar(http.MethodPost, "/marcajes", "no-es-un-objeto", s.docente); estado < 400 || estado >= 500 {
		t.Fatalf("cuerpo inválido: estado %d", estado)
	}
}
