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

// workersAvisos construye las etapas de notificación sin franja de silencio.
func workersAvisos(t *testing.T, e *entorno) *app.WorkersNotificaciones {
	t.Helper()
	t.Setenv("NOTIF_SILENCIO_INICIO", "00:00")
	t.Setenv("NOTIF_SILENCIO_FIN", "00:00")
	cfg, err := config.Load()
	if err != nil {
		t.Fatalf("configuración: %v", err)
	}
	w, err := app.NuevoWorkersNotificaciones(cfg, applog.New(applog.LevelError, io.Discard), e.cliente)
	if err != nil {
		t.Fatalf("workers de notificaciones: %v", err)
	}
	return w
}

// avisoDeTipo busca en la bandeja el aviso del tipo dado.
func avisoDeTipo(e *entorno, token, tipo string) map[string]interface{} {
	for _, n := range bandejaDe(e, token, "?limite=50") {
		if n["tipo"] == tipo {
			return n
		}
	}
	return nil
}

// US-JUS-04 AC-02: una justificación sin resolver tras 48 h se recuerda una sola vez al revisor.
func TestAvisos_RecordatorioRevisionJustificacion(t *testing.T) {
	t.Setenv("JUSTIFICACION_PLAZO_DIAS", "10")
	e := nuevoEntorno(t)
	s := construirEscenario(e)
	pasada, _ := sesionesDePrueba(e, s)
	estado, j := e.enviarMultipart("/justificaciones", map[string]string{
		"sesionId": pasada, "tipo": "INCAPACIDAD", "descripcion": "Incapacidad médica por tres días",
	}, []soporte{{"incapacidad.pdf", pdfMinimo}}, s.docente)
	if estado != http.StatusCreated {
		t.Fatalf("radicar: %d %v", estado, j)
	}
	coord := coordinadorDeFacultad(e, s)
	w := workersAvisos(t, e)
	ctx := context.Background()
	ahora := time.Now().UTC()

	if n, err := w.Revision.EjecutarCiclo(ctx, ahora); err != nil || n != 0 {
		t.Fatalf("antes de 48 h no se recuerda: %d %v", n, err)
	}
	if n, err := w.Revision.EjecutarCiclo(ctx, ahora.Add(49*time.Hour)); err != nil || n != 1 {
		t.Fatalf("tras 48 h se recuerda al coordinador de la facultad: %d %v", n, err)
	}
	if n, _ := w.Revision.EjecutarCiclo(ctx, ahora.Add(50*time.Hour)); n != 0 {
		t.Fatalf("el recordatorio sale una sola vez: %d", n)
	}
	if _, err := w.Despachador.EjecutarCiclo(ctx, time.Now().UTC()); err != nil {
		t.Fatalf("despachador: %v", err)
	}
	aviso := avisoDeTipo(e, coord, "RECORDATORIO_REVISION")
	if aviso == nil || aviso["datos"].(map[string]interface{})["justificacionId"] != j["id"] {
		t.Fatalf("el revisor debe recibir el recordatorio con la justificación: %v", aviso)
	}
	if avisoDeTipo(e, s.docente, "RECORDATORIO_REVISION") != nil {
		t.Fatal("el solicitante no recibe el recordatorio de revisión")
	}
}

// US-ROL-05 AC-02: tres días antes de vencer un rol se avisa una vez al administrador que lo asignó.
func TestAvisos_VencimientoDeRol(t *testing.T) {
	e := nuevoEntorno(t)
	admin := e.token(correoAdmin, claveAdmin)
	vence := time.Now().UTC().Add(50 * time.Hour).Format(time.RFC3339)
	lejano := time.Now().UTC().Add(20 * 24 * time.Hour).Format(time.RFC3339)
	e.exigir(http.MethodPost, "/usuarios", map[string]interface{}{
		"correo": "suplente@siaa.edu.co", "nombre": "Sofía", "apellido": "Rincón", "password": "Suplente2026*x",
		"roles": []map[string]interface{}{{"nombre": "MONITOR", "vigenciaFin": vence}, {"nombre": "DOCENTE", "vigenciaFin": lejano}},
	}, admin, http.StatusCreated)

	w := workersAvisos(t, e)
	ctx := context.Background()
	if n, err := w.VencimientoRoles.EjecutarCiclo(ctx, time.Now().UTC()); err != nil || n != 1 {
		t.Fatalf("solo el rol que vence en 3 días se avisa: %d %v", n, err)
	}
	if n, _ := w.VencimientoRoles.EjecutarCiclo(ctx, time.Now().UTC().Add(time.Hour)); n != 0 {
		t.Fatalf("el aviso sale una sola vez por vencimiento: %d", n)
	}
	if _, err := w.Despachador.EjecutarCiclo(ctx, time.Now().UTC()); err != nil {
		t.Fatalf("despachador: %v", err)
	}
	aviso := avisoDeTipo(e, admin, "VENCIMIENTO_ROL")
	if aviso == nil || aviso["datos"].(map[string]interface{})["rol"] != "MONITOR" {
		t.Fatalf("el administrador que asignó el rol debe recibir el aviso: %v", aviso)
	}
}
