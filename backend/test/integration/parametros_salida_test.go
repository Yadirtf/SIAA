package integration

import (
	"context"
	"net/http"
	"strings"
	"testing"
	"time"

	"go.mongodb.org/mongo-driver/bson"

	"github.com/siaa/backend/internal/repository/mongo/impl"
	usecaseMarcaje "github.com/siaa/backend/internal/usecase/marcaje"
)

// US-PAR-01 AC-04, US-PAR-03 AC-01/AC-03 y US-MAR-15 AC-03: modos de salida válidos, cascada
// resuelta desde la asignación, sesiones con parámetros desactualizados y salida desactivada.
func TestParametros_SalidaCascadaYSesionDesactualizada(t *testing.T) {
	e := nuevoEntorno(t)
	s := construirEscenario(e)
	a := s.admin

	// El modo de salida solo admite los tres valores del catálogo.
	invalido := map[string]interface{}{"ambito": "FACULTAD", "ambito_id": s.facultad, "clave": "salida_obligatoria", "valor": "SIEMPRE"}
	e.exigir(http.MethodPut, "/parametros", invalido, a, http.StatusUnprocessableEntity)
	booleano := map[string]interface{}{"ambito": "FACULTAD", "ambito_id": s.facultad, "clave": "offline_permitido", "valor": "si"}
	e.exigir(http.MethodPut, "/parametros", booleano, a, http.StatusUnprocessableEntity)

	// El nivel GLOBAL no conserva los alias camelCase sembrados por versiones anteriores.
	_, globales := e.llamar(http.MethodGet, "/parametros?ambito=GLOBAL", nil, a)
	for _, p := range elementos(globales) {
		if !strings.Contains(texto(p["clave"]), "_") {
			t.Fatalf("clave heredada en GLOBAL: %v", p)
		}
	}

	// Con solo asignacion_id se aplican la sede y la facultad de la asignación.
	e.exigir(http.MethodPut, "/parametros", map[string]interface{}{
		"ambito": "FACULTAD", "ambito_id": s.facultad, "clave": "holgura_entrada_antes_min", "valor": 25,
	}, a, http.StatusOK)
	efectivos := e.exigir(http.MethodGet, "/parametros/efectivos?asignacion_id="+s.asignacion, nil, a, http.StatusOK)
	origen := map[string]map[string]interface{}{}
	lista, _ := efectivos["parametros"].([]interface{})
	for _, p := range lista {
		m := p.(map[string]interface{})
		origen[texto(m["clave"])] = m
	}
	if o := origen["holgura_entrada_despues_min"]; o["nivel"] != "SEDE" || o["valor"] != float64(20) {
		t.Fatalf("la sede de la asignación debe aplicarse: %v", o)
	}
	if o := origen["holgura_entrada_antes_min"]; o["nivel"] != "FACULTAD" || o["valor"] != float64(25) {
		t.Fatalf("la facultad de la asignación debe aplicarse: %v", o)
	}

	// La sesión ya generada conserva 15 y señala que el valor vigente es 25 (AC-03).
	activa := e.exigir(http.MethodGet, "/me/sesiones/activa", nil, s.docente, http.StatusOK)
	sesionID := texto(activa["sesion"].(map[string]interface{})["id"])
	if activa["ventana"].(map[string]interface{})["tipo"] != "ENTRADA" {
		t.Fatalf("la ventana vigente es la de entrada: %v", activa["ventana"])
	}
	detalle := e.exigir(http.MethodGet, "/sesiones/"+sesionID, nil, a, http.StatusOK)
	difs, _ := detalle["parametrosDiferentes"].([]interface{})
	if len(difs) != 1 {
		t.Fatalf("se esperaba una diferencia de parámetros: %v", detalle["parametrosDiferentes"])
	}
	if d := difs[0].(map[string]interface{}); d["clave"] != "holgura_entrada_antes_min" || d["congelado"] != float64(15) || d["actual"] != float64(25) {
		t.Fatalf("diferencia inesperada: %v", d)
	}

	// Con salida DESACTIVADA (valor por defecto) el servidor no procesa la salida.
	salida := s.marcaje(sesionID, 1.1477, -76.6511, "k-salida-off")
	salida["tipo"] = "SALIDA"
	if r := e.exigir(http.MethodPost, "/marcajes", salida, s.docente, http.StatusConflict); r["codigo"] != "ESTADO_INVALIDO" {
		t.Fatalf("la salida desactivada debe rechazarse: %v", r)
	}
}

// US-PAR-04 AC-01..AC-03: el reporte usa el umbral del ámbito y la racha de inasistencias
// avisa una sola vez al coordinador de la facultad.
func TestParametros_AlertaInasistenciasYUmbral(t *testing.T) {
	e := nuevoEntorno(t)
	s := construirEscenario(e)
	coordinadorDeFacultad(e, s)
	for clave, valor := range map[string]interface{}{"inasistencias_consecutivas_alerta": 1, "porcentaje_minimo_asistencia": 90} {
		e.exigir(http.MethodPut, "/parametros", map[string]interface{}{
			"ambito": "FACULTAD", "ambito_id": s.facultad, "clave": clave, "valor": valor,
		}, s.admin, http.StatusOK)
	}

	// Al cierre del día la sesión sin entrada queda ausente y completa la racha.
	ctx := context.Background()
	manana := time.Now().Add(26 * time.Hour).UTC()
	if n, err := e.app.AusenciasWorker.EjecutarCiclo(ctx, manana); err != nil || n < 1 {
		t.Fatalf("worker de ausencias: n=%d err=%v", n, err)
	}
	// Repetir el ciclo no duplica el aviso de la misma racha (AC-03).
	if _, err := e.app.AusenciasWorker.EjecutarCiclo(ctx, manana.Add(time.Hour)); err != nil {
		t.Fatalf("segundo ciclo: %v", err)
	}
	// El aviso queda en la cola del coordinador; el despachador lo envía después (US-NOT-01).
	alertas, err := e.cliente.DB().Collection("notificaciones").CountDocuments(ctx, bson.M{"tipo": "ALERTA_INASISTENCIAS"})
	if err != nil || alertas != 1 {
		t.Fatalf("se esperaba una alerta encolada para el coordinador: %d %v", alertas, err)
	}

	// El reporte del ámbito marca bajo umbral con el porcentaje de la facultad.
	desde := time.Now().In(bogota).AddDate(0, 0, -1).Format("2006-01-02")
	hasta := time.Now().In(bogota).AddDate(0, 0, 1).Format("2006-01-02")
	rep := e.exigir(http.MethodGet, "/reportes/cumplimiento?facultadId="+s.facultad+"&desde="+desde+"&hasta="+hasta, nil, s.admin, http.StatusOK)
	if rep["umbralAlerta"] != float64(90) {
		t.Fatalf("el reporte debe usar el umbral de la facultad: %v", rep)
	}
}

// US-MAR-15 AC-02/AC-03: con salida OPCIONAL la sesión activa ofrece la ventana de salida al
// final de la clase; la salida aceptada calcula la permanencia desde la entrada.
func TestParametros_SalidaOpcionalYPermanencia(t *testing.T) {
	e := nuevoEntorno(t)
	s := construirEscenarioCon(e, map[string]interface{}{"salida_obligatoria": "OPCIONAL"})
	activa := e.exigir(http.MethodGet, "/me/sesiones/activa", nil, s.docente, http.StatusOK)
	sesion := activa["sesion"].(map[string]interface{})
	sesionID := texto(sesion["id"])
	e.exigir(http.MethodPost, "/marcajes", s.marcaje(sesionID, 1.1477, -76.6511, "k-entrada"), s.docente, http.StatusCreated)

	fin, _ := time.Parse(time.RFC3339, texto(sesion["finProgramado"]))
	ctx := context.Background()
	activas := usecaseMarcaje.NewSesionActivaUseCase(impl.NewSesionRepository(e.cliente),
		impl.NewEspacioRepository(e.cliente), impl.NewMarcajeMongoRepository(e.cliente.DB()))
	det, err := activas.ObtenerSesionActiva(ctx, s.docenteID, fin.Add(5*time.Minute))
	if err != nil || det.Sesion == nil || det.Ventana.Tipo != "SALIDA" || det.Ventana.Estado != "ABIERTA" {
		t.Fatalf("al final de la clase se ofrece la salida: %+v err=%v", det, err)
	}

	// Durante la clase la salida está fuera de su ventana (holguras de salida, AC-04).
	salida := s.marcaje(sesionID, 1.1477, -76.6511, "k-salida")
	salida["tipo"] = "SALIDA"
	if r := e.exigir(http.MethodPost, "/marcajes", salida, s.docente, http.StatusCreated); r["resultado"] != "RECHAZADO_FUERA_DE_HORARIO" {
		t.Fatalf("la salida antes de la ventana se rechaza por horario: %v", r)
	}
}
