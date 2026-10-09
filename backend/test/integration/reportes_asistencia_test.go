package integration

import (
	"net/http"
	"testing"

	"github.com/siaa/backend/internal/domain/marcaje"
)

// US-REP-05 AC-01..AC-03: porcentaje por estudiante, promedio del grupo, bajo umbral y el
// mismo número que ve el estudiante en la app; acceso del docente del grupo y del coordinador.
func TestReportes_AsistenciaEstudiantil(t *testing.T) {
	e := nuevoEntorno(t)
	s := construirEscenario(e)
	est := estudianteListo(e, correoEstudiante, "disp-est-1")
	estudianteListo(e, correoEstudiante2, "disp-est-2")
	res := e.exigir(http.MethodPut, "/grupos/"+s.grupo+"/estudiantes", map[string]interface{}{
		"estudiantes": []string{correoEstudiante, correoEstudiante2},
	}, s.admin, http.StatusOK)
	ids := map[string]string{}
	for _, u := range elementos(res["estudiantes"]) {
		ids[texto(u["correo"])] = texto(u["id"])
	}
	if len(ids) != 2 {
		t.Fatalf("integrantes: %v", res)
	}
	terminadas := sesionesTerminadas(e, s)
	for _, id := range terminadas {
		entradaConsolidada(e, id, ids[correoEstudiante], marcaje.RolEstudiante)
	}

	rep := e.exigir(http.MethodGet, "/reportes/asistencia-estudiantil?grupoId="+s.grupo, nil, s.docente, http.StatusOK)
	filas := map[string]map[string]interface{}{}
	for _, f := range elementos(rep["estudiantes"]) {
		filas[texto(f["estudianteId"])] = f
	}
	uno, dos := filas[ids[correoEstudiante]], filas[ids[correoEstudiante2]]
	if uno == nil || dos == nil || uno["porcentaje"] != float64(100) || dos["porcentaje"] != float64(0) {
		t.Fatalf("porcentajes inesperados: %v", rep)
	}
	if uno["bajoUmbral"] != false || dos["bajoUmbral"] != true || rep["estudiantesBajoUmbral"] != float64(1) {
		t.Fatalf("debe destacarse el estudiante bajo el umbral: %v", rep)
	}
	if rep["promedioGrupo"] != float64(50) || rep["asignatura"] != "Cálculo" || rep["sesionesDictadas"] != float64(len(terminadas)) {
		t.Fatalf("promedio o encabezado inesperado: %v", rep)
	}
	if texto(uno["nombre"]) == ids[correoEstudiante] {
		t.Fatalf("el reporte debe mostrar el nombre del estudiante: %v", uno)
	}

	// AC-03: el estudiante ve exactamente el mismo porcentaje en la app.
	_, propia := e.llamar(http.MethodGet, "/me/asistencia", nil, est)
	app := elementos(propia)
	if len(app) != 1 || app[0]["porcentaje"] != uno["porcentaje"] || app[0]["sesionesAsistidas"] != uno["sesionesAsistidas"] ||
		app[0]["sesionesDictadas"] != uno["sesionesDictadas"] {
		t.Fatalf("la app (%v) y el reporte (%v) deben coincidir", app, uno)
	}

	// Acceso: coordinador del ámbito sí; otra facultad y estudiantes no; grupo inexistente 404.
	coord := coordinadorDeFacultad(e, s)
	e.exigir(http.MethodGet, "/reportes/asistencia-estudiantil?grupoId="+s.grupo, nil, coord, http.StatusOK)
	otro := coordinadorDeOtraFacultad(e, s)
	e.exigir(http.MethodGet, "/reportes/asistencia-estudiantil?grupoId="+s.grupo, nil, otro, http.StatusForbidden)
	e.exigir(http.MethodGet, "/reportes/asistencia-estudiantil?grupoId="+s.grupo, nil, est, http.StatusForbidden)
	e.exigir(http.MethodGet, "/reportes/asistencia-estudiantil?grupoId=000000000000000000000000", nil, s.admin, http.StatusNotFound)
	e.exigir(http.MethodGet, "/reportes/asistencia-estudiantil", nil, s.admin, http.StatusUnprocessableEntity)

	// El selector del docente lista sus grupos del periodo; el de otra facultad, ninguno.
	if grupos := e.exigirLista("/reportes/asistencia-estudiantil/grupos?periodoId="+s.periodo, s.docente); len(grupos) != 1 || grupos[0]["grupoId"] != s.grupo || grupos[0]["grupo"] != "01" {
		t.Fatalf("grupos del docente: %v", grupos)
	}
	if grupos := e.exigirLista("/reportes/asistencia-estudiantil/grupos?periodoId="+s.periodo, otro); len(grupos) != 0 {
		t.Fatalf("grupos fuera del ámbito: %v", grupos)
	}
}
