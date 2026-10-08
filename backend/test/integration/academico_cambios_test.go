package integration

import (
	"net/http"
	"testing"
	"time"
)

// US-ACA-06 AC-01/AC-04 y US-ACA-05 AC-04: reprogramación con motivo, confirmación para
// sesiones iniciadas, choques y generación asíncrona sin duplicar la sesión movida.
func TestAcademico_ReprogramarYGeneracionAsincrona(t *testing.T) {
	e := nuevoEntorno(t)
	s := construirEscenario(e)
	a := s.admin
	_, crudo := e.llamar(http.MethodGet, "/sesiones?periodoId="+s.periodo, nil, a)
	lista := elementos(crudo)
	hoy := time.Now().In(bogota).Format("2006-01-02")
	var actual, futura, siguiente map[string]interface{}
	for _, ses := range lista {
		switch {
		case ses["fecha"] == hoy:
			actual = ses
		case texto(ses["fecha"]) > hoy && futura == nil:
			futura = ses
		case texto(ses["fecha"]) > hoy && siguiente == nil:
			siguiente = ses
		}
	}
	if actual == nil || futura == nil || siguiente == nil {
		t.Fatalf("faltan sesiones de prueba: %v", crudo)
	}
	ruta := "/sesiones/" + texto(futura["id"]) + "/reprogramar"
	dia, _ := time.Parse("2006-01-02", texto(futura["fecha"]))
	nueva := map[string]interface{}{"fecha": dia.AddDate(0, 0, 1).Format("2006-01-02"), "horaInicio": "07:00", "horaFin": "08:30"}

	// Sin motivo no se reprograma.
	e.exigir(http.MethodPatch, ruta, nueva, a, http.StatusUnprocessableEntity)
	nueva["motivo"] = "Salida académica del grupo"
	movida := e.exigir(http.MethodPatch, ruta, nueva, a, http.StatusOK)
	if movida["fecha"] != nueva["fecha"] || movida["horaInicio"] != "07:00" {
		t.Fatalf("la sesión no quedó reprogramada: %v", movida)
	}

	// Choque: el docente ya tiene la clase de la semana siguiente en ese horario.
	choque := map[string]interface{}{"fecha": siguiente["fecha"], "horaInicio": siguiente["horaInicio"],
		"horaFin": siguiente["horaFin"], "motivo": "Mover encima de otra clase"}
	if r := e.exigir(http.MethodPatch, ruta, choque, a, http.StatusConflict); r["codigo"] != "CONFLICTO_HORARIO" {
		t.Fatalf("se esperaba choque de horario: %v", r)
	}

	// La sesión en curso exige confirmación explícita (AC-04).
	enCurso := map[string]interface{}{"fecha": nueva["fecha"], "horaInicio": "20:00", "horaFin": "21:00", "motivo": "Corte de energía"}
	if r := e.exigir(http.MethodPatch, "/sesiones/"+texto(actual["id"])+"/reprogramar", enCurso, a, http.StatusConflict); r["codigo"] != "CONFIRMACION_REQUERIDA" {
		t.Fatalf("se esperaba pedir confirmación: %v", r)
	}

	// Generación asíncrona: no duplica la sesión movida y deja de generar fechas pasadas.
	trabajo := e.exigir(http.MethodPost, "/periodos/"+s.periodo+"/generar-sesiones", map[string]interface{}{"asincrono": true}, a, http.StatusAccepted)
	var estado map[string]interface{}
	for i := 0; i < 50; i++ {
		estado = e.exigir(http.MethodGet, "/trabajos/"+texto(trabajo["id"]), nil, a, http.StatusOK)
		if estado["estado"] != "EN_PROCESO" {
			break
		}
		time.Sleep(100 * time.Millisecond)
	}
	informe, _ := estado["resultado"].(map[string]interface{})
	if estado["estado"] != "COMPLETADO" || informe["sesionesGeneradas"] != float64(0) {
		t.Fatalf("la generación asíncrona no debe duplicar sesiones: %v", estado)
	}
	if informe["sesionesPasadasOmitidas"].(float64) < 1 {
		t.Fatalf("las fechas pasadas deben omitirse por defecto: %v", informe)
	}
	e.exigir(http.MethodGet, "/trabajos/000000000000000000000000", nil, a, http.StatusNotFound)
}

// US-ACA-02 AC-04 y US-ACA-03 AC-04: una franja de 10 minutos en un aula sin geocerca se
// guarda, pero la respuesta lo advierte.
func TestAcademico_AdvertenciasDeAsignacion(t *testing.T) {
	e := nuevoEntorno(t)
	s := construirEscenario(e)
	aula := texto(e.exigir(http.MethodPost, "/espacios", map[string]interface{}{"sedeId": s.sede, "bloqueId": s.bloque,
		"piso": 2, "codigo": "A-201", "nombre": "Aula 201", "capacidad": 20, "tipo": "AULA"}, s.admin, http.StatusCreated)["id"])
	grupo := texto(e.exigir(http.MethodPost, "/grupos", map[string]interface{}{"numero": "02", "asignaturaId": s.asignatura,
		"periodoId": s.periodo, "cupo": 20}, s.admin, http.StatusCreated)["id"])
	res := e.exigir(http.MethodPost, "/asignaciones", map[string]interface{}{
		"periodoId": s.periodo, "docenteIds": []string{s.docenteID}, "grupoId": grupo, "asignaturaId": s.asignatura,
		"facultadId": s.facultad, "espacioId": aula, "modalidad": "PRESENCIAL",
		"franja": map[string]interface{}{"diaSemana": 7, "horaInicio": "06:00", "horaFin": "06:10"},
	}, s.admin, http.StatusCreated)
	adv, _ := res["advertencias"].([]interface{})
	if len(adv) != 2 {
		t.Fatalf("se esperaban advertencias de duración y de aula sin geocerca: %v", res)
	}
}
