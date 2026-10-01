package integration

import (
	"net/http"
	"strings"
	"testing"
)

// La consola lista las asignaciones sin elegir periodo y cada choque de horario se explica con
// nombres (docente, asignatura, grupo, aula, día y hora en 12 h), nunca con identificadores.
func TestAsignacion_ListaYSolapamientoLegible(t *testing.T) {
	e := nuevoEntorno(t)
	s := construirEscenario(e)

	_, crudo := e.llamar(http.MethodGet, "/asignaciones", nil, s.admin)
	lista := elementos(crudo)
	if len(lista) != 1 || lista[0]["id"] != s.asignacion {
		t.Fatalf("sin periodoId deben listarse todas las asignaciones: %v", crudo)
	}
	existente := lista[0]
	if existente["asignaturaNombre"] != "Cálculo" || existente["grupoNumero"] != "01" {
		t.Fatalf("la lista debe traer asignatura y grupo legibles: %v", existente)
	}
	franja, _ := existente["franja"].(map[string]interface{})

	grupo2 := texto(e.exigir(http.MethodPost, "/grupos", map[string]interface{}{
		"numero": "02", "asignaturaId": s.asignatura, "periodoId": s.periodo, "cupo": 25,
	}, s.admin, http.StatusCreated)["id"])
	formulario := func(docente, espacio string) map[string]interface{} {
		return map[string]interface{}{
			"periodoId": s.periodo, "grupoId": grupo2, "docenteIds": []string{docente}, "espacioId": espacio,
			"modalidad": "PRESENCIAL", "franja": franja,
		}
	}

	// Mismo docente a la misma hora en otra aula: choque de docente.
	estado, cuerpo := e.llamar(http.MethodPost, "/asignaciones", formulario(s.docenteID, s.espacio2), s.admin)
	choque := exigirChoque(t, estado, cuerpo, "COLISION_DOCENTE")
	for _, debe := range []string{"Cálculo", "grupo 01", "A-301"} {
		if !strings.Contains(texto(choque["mensaje"]), debe) {
			t.Fatalf("el mensaje debe nombrar %q: %v", debe, choque["mensaje"])
		}
	}

	// Otro docente en la misma aula y hora: choque de aula.
	e.exigir(http.MethodPost, "/usuarios", map[string]interface{}{
		"correo": "otro.docente@siaa.edu.co", "nombre": "Luis", "apellido": "Mora", "password": "OtroDocente2026*",
		"roles": []map[string]interface{}{{"nombre": "DOCENTE"}},
	}, s.admin, http.StatusCreated)
	var otroDocente string
	_, usuarios := e.llamar(http.MethodGet, "/usuarios", nil, s.admin)
	for _, u := range elementos(usuarios) {
		if u["correo"] == "otro.docente@siaa.edu.co" {
			otroDocente = texto(u["id"])
		}
	}
	estado, cuerpo = e.llamar(http.MethodPost, "/asignaciones", formulario(otroDocente, s.espacio), s.admin)
	choque = exigirChoque(t, estado, cuerpo, "COLISION_AULA")
	if !strings.Contains(texto(choque["mensaje"]), "El aula A-301 · Aula 301 ya está ocupada") {
		t.Fatalf("el mensaje debe nombrar el aula: %v", choque["mensaje"])
	}
}

func exigirChoque(t *testing.T, estado int, cuerpo interface{}, tipo string) map[string]interface{} {
	t.Helper()
	choque, _ := cuerpo.(map[string]interface{})
	if estado != http.StatusConflict || choque["codigo"] != "CONFLICTO_HORARIO" {
		t.Fatalf("se esperaba 409 CONFLICTO_HORARIO: %d %v", estado, cuerpo)
	}
	contexto, _ := choque["contexto"].(map[string]interface{})
	if contexto["tipo"] != tipo || texto(contexto["docente"]) == "" || texto(contexto["dia"]) == "" {
		t.Fatalf("el contexto debe traer tipo %s y nombres: %v", tipo, contexto)
	}
	mensaje := texto(choque["mensaje"])
	if !strings.Contains(mensaje, " m.") || strings.Contains(mensaje, "US-ACA") {
		t.Fatalf("el mensaje debe usar a. m./p. m. y no citar historias: %v", mensaje)
	}
	return choque
}
