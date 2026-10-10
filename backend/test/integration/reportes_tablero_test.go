package integration

import (
	"context"
	"net/http"
	"testing"
	"time"

	"github.com/siaa/backend/internal/domain/marcaje"
	"github.com/siaa/backend/internal/repository/mongo/impl"
)

// coordinadorCon crea un coordinador con ámbito en la facultad dada y devuelve su token.
func coordinadorCon(e *entorno, s *escenario, correo, facultadID string) string {
	e.t.Helper()
	e.exigir(http.MethodPost, "/usuarios", map[string]interface{}{
		"correo": correo, "nombre": "Coordinación", "apellido": "Prueba", "password": "Coordinadora2026*",
		"roles": []map[string]interface{}{{"nombre": "COORDINADOR"}}, "ambitos": []map[string]interface{}{{"tipo": "FACULTAD", "id": facultadID}},
	}, s.admin, http.StatusCreated)
	return e.token(correo, "Coordinadora2026*")
}

// coordinadorDeOtraFacultad crea la facultad de Medicina y un coordinador con ámbito solo en ella.
func coordinadorDeOtraFacultad(e *entorno, s *escenario) string {
	e.t.Helper()
	med := texto(e.exigir(http.MethodPost, "/facultades", map[string]interface{}{"codigo": "MED", "nombre": "Medicina", "sedeId": s.sede}, s.admin, http.StatusCreated)["id"])
	return coordinadorCon(e, s, "coord.med@siaa.edu.co", med)
}

// entradaConsolidada registra una entrada válida vigente (datos de prueba para sesiones ya
// terminadas, donde el motor de marcaje no admite marcar).
func entradaConsolidada(e *entorno, sesionID, usuarioID string, rol marcaje.RolMarcaje) {
	e.t.Helper()
	ahora := time.Now().UTC()
	m := &marcaje.Marcaje{
		SesionID: sesionID, UsuarioID: usuarioID, RolMarcaje: rol, Tipo: marcaje.TipoEntrada,
		Resultado: marcaje.ResultadoPresente, Origen: marcaje.OrigenAppMovil,
		TimestampServidor: ahora, TimestampDispositivo: ahora,
	}
	if err := impl.NewMarcajeMongoRepository(e.cliente.DB()).Crear(context.Background(), m); err != nil || !m.Consolidado {
		e.t.Fatalf("registrar entrada de prueba: %v (consolidado=%v)", err, m.Consolidado)
	}
}

// US-REP-03 AC-01/AC-03: sesiones del día, en curso sin marcaje con su detalle, marcajes
// efectuados y ámbito del usuario.
func TestReportes_TableroEnVivo(t *testing.T) {
	e := nuevoEntorno(t)
	s := construirEscenario(e)
	coord := coordinadorDeFacultad(e, s)
	otro := coordinadorDeOtraFacultad(e, s)

	e.exigir(http.MethodGet, "/reportes/tablero", nil, s.docente, http.StatusForbidden)
	tab := e.exigir(http.MethodGet, "/reportes/tablero", nil, coord, http.StatusOK)
	if tab["sesionesDelDia"] != float64(1) || tab["sesionesEnCurso"] != float64(1) || tab["refrescoSugeridoSegundos"].(float64) <= 0 {
		t.Fatalf("el tablero debe mostrar la sesión en curso de hoy: %v", tab)
	}
	sin := elementos(tab["sesionesEnCursoSinMarcaje"])
	if len(sin) != 1 || sin[0]["docenteId"] != s.docenteID || sin[0]["aula"] != "A-301 · Aula 301" ||
		sin[0]["asignatura"] != "Cálculo" || sin[0]["docente"] == s.docenteID || texto(sin[0]["horaInicio"]) == "" {
		t.Fatalf("detalle de la sesión sin marcaje inesperado: %v", sin)
	}
	if fuera := e.exigir(http.MethodGet, "/reportes/tablero", nil, otro, http.StatusOK); fuera["sesionesDelDia"] != float64(0) ||
		len(elementos(fuera["sesionesEnCursoSinMarcaje"])) != 0 {
		t.Fatalf("un coordinador de otra facultad no ve las sesiones: %v", fuera)
	}

	// Con la entrada del docente la sesión deja de aparecer y se cuenta el marcaje.
	sesionID := texto(sin[0]["sesionId"])
	if r := e.exigir(http.MethodPost, "/marcajes", s.marcaje(sesionID, 1.1477, -76.6511, "k-tablero"), s.docente, http.StatusCreated); r["resultado"] != "PRESENTE" {
		t.Fatalf("marcaje: %v", r)
	}
	tab = e.exigir(http.MethodGet, "/reportes/tablero", nil, coord, http.StatusOK)
	marcajes := tab["marcajes"].(map[string]interface{})
	if marcajes["entradasDocentes"] != float64(1) || marcajes["total"] != float64(1) || len(elementos(tab["sesionesEnCursoSinMarcaje"])) != 0 {
		t.Fatalf("el tablero debe reflejar la entrada del docente: %v", tab)
	}
}

// US-REP-03 AC-01: las alertas activas son las rachas de inasistencias notificadas, una por
// racha aunque haya varios coordinadores, dentro del ámbito y mientras no haya entrada posterior.
func TestReportes_TableroAlertasActivas(t *testing.T) {
	e := nuevoEntorno(t)
	s := construirEscenario(e)
	coord := coordinadorDeFacultad(e, s)
	coordinadorCon(e, s, "coord2.ing@siaa.edu.co", s.facultad)
	otro := coordinadorDeOtraFacultad(e, s)
	e.exigir(http.MethodPut, "/parametros", map[string]interface{}{
		"ambito": "FACULTAD", "ambito_id": s.facultad, "clave": "inasistencias_consecutivas_alerta", "valor": 1,
	}, s.admin, http.StatusOK)
	if n, err := e.app.AusenciasWorker.EjecutarCiclo(context.Background(), time.Now().Add(26*time.Hour).UTC()); err != nil || n < 1 {
		t.Fatalf("worker de ausencias: n=%d err=%v", n, err)
	}

	for _, token := range []string{coord, s.admin} {
		alertas := elementos(e.exigir(http.MethodGet, "/reportes/tablero", nil, token, http.StatusOK)["alertasActivas"])
		if len(alertas) != 1 || alertas[0]["docenteId"] != s.docenteID || texto(alertas[0]["mensaje"]) == "" {
			t.Fatalf("se esperaba una alerta activa por la racha: %v", alertas)
		}
	}
	if alertas := elementos(e.exigir(http.MethodGet, "/reportes/tablero", nil, otro, http.StatusOK)["alertasActivas"]); len(alertas) != 0 {
		t.Fatalf("la alerta de Ingeniería no es del ámbito de Medicina: %v", alertas)
	}

	// Una entrada válida posterior cierra la racha y la alerta deja de estar activa.
	_, futura := sesionesDePrueba(e, s)
	entradaConsolidada(e, futura, s.docenteID, marcaje.RolDocente)
	if alertas := elementos(e.exigir(http.MethodGet, "/reportes/tablero", nil, coord, http.StatusOK)["alertasActivas"]); len(alertas) != 0 {
		t.Fatalf("la racha cerrada no es una alerta activa: %v", alertas)
	}
}
