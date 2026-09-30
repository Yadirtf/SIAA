package integration

import (
	"context"
	"io"
	"net/http"
	"testing"
	"time"

	"github.com/siaa/backend/internal/app"
	"github.com/siaa/backend/internal/platform/config"
	applog "github.com/siaa/backend/internal/platform/log"
)

// EP-10: el docente registra su token y preferencias; los cambios de horario y el cierre de
// ventana llegan a su bandeja aunque no haya canal push configurado.
func TestNotificaciones_BandejaPreferenciasYCambios(t *testing.T) {
	e := nuevoEntorno(t)
	s := construirEscenario(e)

	// Preferencias por defecto: todo activo, el cambio de horario es obligatorio.
	prefs := e.exigir(http.MethodGet, "/me/notificaciones/preferencias", nil, s.docente, http.StatusOK)
	if prefs["recordatorioSesion"] != true || len(prefs["obligatorias"].([]interface{})) != 1 {
		t.Fatalf("preferencias por defecto inesperadas: %v", prefs)
	}
	guardadas := e.exigir(http.MethodPut, "/me/notificaciones/preferencias", map[string]interface{}{
		"recordatorioSesion": false, "cierreVentana": true, "resultadoJustificacion": true, "cambioHorario": false,
	}, s.docente, http.StatusOK)
	if guardadas["recordatorioSesion"] != false || guardadas["cambioHorario"] != true {
		t.Fatalf("el cambio de horario no se puede desactivar: %v", guardadas)
	}

	token := map[string]interface{}{"token": "token-fcm-integracion", "plataforma": "ANDROID", "dispositivoId": s.dispositivo}
	e.exigir(http.MethodPost, "/me/notificaciones/tokens", token, s.docente, http.StatusNoContent)
	e.exigir(http.MethodPost, "/me/notificaciones/tokens", token, s.docente, http.StatusNoContent)
	e.exigir(http.MethodPost, "/me/notificaciones/tokens", map[string]interface{}{"token": "x", "plataforma": "SYMBIAN"}, s.docente, http.StatusUnprocessableEntity)

	// El programador encola el recordatorio (desactivado por el docente) y el aviso de cierre de
	// la sesión en curso, sin franja de silencio para que el resultado no dependa de la hora.
	t.Setenv("NOTIF_SILENCIO_INICIO", "00:00")
	t.Setenv("NOTIF_SILENCIO_FIN", "00:00")
	t.Setenv("NOTIF_CIERRE_MIN", "30")
	cfg, err := config.Load()
	if err != nil {
		t.Fatalf("configuración: %v", err)
	}
	workers, err := app.NuevoWorkersNotificaciones(cfg, applog.New(applog.LevelError, io.Discard), e.cliente)
	if err != nil {
		t.Fatalf("workers de notificaciones: %v", err)
	}
	ctx := context.Background()
	ahora := time.Now().UTC()
	programar := func() {
		t.Helper()
		// La primera ejecución solo fija la marca de agua; la segunda cubre los últimos 20 minutos.
		for _, instante := range []time.Time{ahora.Add(-20 * time.Minute), ahora} {
			if _, err := workers.Programador.EjecutarCiclo(ctx, instante); err != nil {
				t.Fatalf("programador: %v", err)
			}
		}
	}
	programar()

	// Cancelar la clase avisa al docente (CAMBIO_HORARIO).
	activa := e.exigir(http.MethodGet, "/me/sesiones/activa", nil, s.docente, http.StatusOK)
	sesionID := texto(activa["sesion"].(map[string]interface{})["id"])
	e.exigir(http.MethodPost, "/sesiones/"+sesionID+"/cancelar", map[string]interface{}{"motivo": "Paro de transporte"}, s.admin, http.StatusNoContent)

	if _, err := workers.Despachador.EjecutarCiclo(ctx, time.Now().UTC()); err != nil {
		t.Fatalf("despachador: %v", err)
	}
	bandeja := bandejaDe(e, s.docente, "?limite=30")
	tipos := map[string]map[string]interface{}{}
	for _, n := range bandeja {
		tipos[texto(n["tipo"])] = n
	}
	cambio, ok := tipos["CAMBIO_HORARIO"]
	if !ok {
		t.Fatalf("la cancelación debe llegar a la bandeja: %v", bandeja)
	}
	if datos := cambio["datos"].(map[string]interface{}); datos["sesionId"] != sesionID || datos["ruta"] == "" || cambio["leida"] != false {
		t.Fatalf("el aviso debe llevar la sesión y la ruta a abrir: %v", cambio)
	}
	if _, ok := tipos["CIERRE_VENTANA"]; !ok {
		t.Fatalf("el cierre de ventana debe llegar a la bandeja: %v", bandeja)
	}
	if _, ok := tipos["RECORDATORIO_SESION"]; ok {
		t.Fatalf("el recordatorio desactivado no debe llegar: %v", bandeja)
	}

	e.exigir(http.MethodPost, "/me/notificaciones/"+texto(cambio["id"])+"/leida", nil, s.docente, http.StatusNoContent)
	// Otro usuario no puede marcar avisos ajenos.
	e.exigir(http.MethodPost, "/me/notificaciones/"+texto(cambio["id"])+"/leida", nil, s.admin, http.StatusNotFound)
	for _, n := range bandejaDe(e, s.docente, "") {
		if n["id"] == cambio["id"] && n["leida"] != true {
			t.Fatalf("el aviso debe quedar leído: %v", n)
		}
	}
	e.exigir(http.MethodDelete, "/me/notificaciones/tokens", map[string]interface{}{"token": "token-fcm-integracion"}, s.docente, http.StatusNoContent)

	// Un segundo ciclo del programador no duplica avisos (clave de deduplicación).
	programar()
	if _, err := workers.Despachador.EjecutarCiclo(ctx, time.Now().UTC()); err != nil {
		t.Fatalf("despachador repetido: %v", err)
	}
	if n := len(bandejaDe(e, s.docente, "")); n != len(bandeja) {
		t.Fatalf("no deben duplicarse avisos: antes %d, ahora %d", len(bandeja), n)
	}
}

// bandejaDe lee la bandeja del usuario, que el API devuelve como arreglo.
func bandejaDe(e *entorno, token, consulta string) []map[string]interface{} {
	e.t.Helper()
	codigo, datos := e.llamar(http.MethodGet, "/me/notificaciones"+consulta, nil, token)
	if codigo != http.StatusOK {
		e.t.Fatalf("GET /me/notificaciones: %d %v", codigo, datos)
	}
	return elementos(datos)
}
