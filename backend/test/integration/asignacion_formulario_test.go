package integration

import (
	"net/http"
	"testing"
)

// US-ACA-03: el formulario solo elige periodo, grupo, docentes y aula; el servidor deriva
// asignatura, facultad y nombres, y rechaza docentes o aulas que no correspondan.
func TestAsignacion_DatosDerivadosEnElServidor(t *testing.T) {
	e := nuevoEntorno(t)
	s := construirEscenario(e)
	grupo := texto(e.exigir(http.MethodPost, "/grupos", map[string]interface{}{
		"numero": "02", "asignaturaId": s.asignatura, "periodoId": s.periodo, "cupo": 25,
	}, s.admin, http.StatusCreated)["id"])

	var adminID string
	_, usuarios := e.llamar(http.MethodGet, "/usuarios", nil, s.admin)
	for _, u := range elementos(usuarios) {
		if u["correo"] == correoAdmin {
			adminID = texto(u["id"])
		}
	}
	formulario := func(docentes []string, espacio string) map[string]interface{} {
		return map[string]interface{}{
			"periodoId": s.periodo, "grupoId": grupo, "docenteIds": docentes, "espacioId": espacio,
			"modalidad": "PRESENCIAL",
			"franja":    map[string]interface{}{"diaSemana": 6, "horaInicio": "07:00", "horaFin": "09:00"},
		}
	}

	// Un usuario sin rol DOCENTE no puede dictar la clase.
	e.exigir(http.MethodPost, "/asignaciones", formulario([]string{adminID}, s.espacio), s.admin, http.StatusUnprocessableEntity)
	e.exigir(http.MethodPost, "/asignaciones", formulario([]string{"000000000000000000000000"}, s.espacio), s.admin, http.StatusUnprocessableEntity)

	// Un aula de otra sede no sirve para el periodo.
	otraSede := texto(e.exigir(http.MethodPost, "/sedes", map[string]interface{}{"codigo": "SN", "nombre": "Sede Norte", "direccion": "Calle 2"}, s.admin, http.StatusCreated)["id"])
	otroBloque := texto(e.exigir(http.MethodPost, "/bloques", map[string]interface{}{"sedeId": otraSede, "codigo": "N1", "nombre": "Norte 1", "pisos": []int{1}}, s.admin, http.StatusCreated)["id"])
	aulaAjena := texto(e.exigir(http.MethodPost, "/espacios", map[string]interface{}{
		"sedeId": otraSede, "bloqueId": otroBloque, "piso": 1, "codigo": "N-101", "nombre": "Aula Norte", "capacidad": 20, "tipo": "AULA",
	}, s.admin, http.StatusCreated)["id"])
	e.exigir(http.MethodPost, "/asignaciones", formulario([]string{s.docenteID}, aulaAjena), s.admin, http.StatusUnprocessableEntity)

	// Con docente y aula válidos, lo demás lo completa el servidor.
	creada := e.exigir(http.MethodPost, "/asignaciones", formulario([]string{s.docenteID, s.docenteID}, s.espacio2), s.admin, http.StatusCreated)
	asignacion, _ := creada["asignacion"].(map[string]interface{})
	if asignacion == nil {
		asignacion = creada
	}
	if asignacion["asignaturaId"] != s.asignatura || asignacion["facultadId"] != s.facultad {
		t.Fatalf("asignatura y facultad deben derivarse del grupo: %v", asignacion)
	}
	if nombre := texto(asignacion["docenteNombre"]); nombre == "" || nombre == s.docenteID {
		t.Fatalf("el nombre del docente debe salir de su cuenta: %v", asignacion)
	}
	if docentes, _ := asignacion["docenteIds"].([]interface{}); len(docentes) != 1 {
		t.Fatalf("los docentes repetidos se unifican: %v", asignacion)
	}
	if texto(asignacion["espacioNombre"]) != "A-302 · Aula 302" {
		t.Fatalf("el nombre del aula debe salir del espacio: %v", asignacion)
	}

	// El suplente de una sesión también debe ser un docente.
	_, sesiones := e.llamar(http.MethodGet, "/sesiones?periodoId="+s.periodo, nil, s.admin)
	lista := elementos(sesiones)
	futura := texto(lista[len(lista)-1]["id"])
	e.exigir(http.MethodPatch, "/sesiones/"+futura+"/docente-reemplazo", map[string]interface{}{"docenteId": adminID, "motivo": "Incapacidad"}, s.admin, http.StatusUnprocessableEntity)
}
