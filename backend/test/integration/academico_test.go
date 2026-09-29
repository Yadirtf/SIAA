package integration

import (
	"net/http"
	"testing"
	"time"
)

// EP-04: consultas de la estructura académica, excepciones de calendario y novedades de sesión.
func TestAcademico_EstructuraYSesiones(t *testing.T) {
	e := nuevoEntorno(t)
	s := construirEscenario(e)
	a := s.admin

	for _, r := range []string{
		"/facultades", "/programas?facultadId=" + s.facultad, "/asignaturas?programaId=" + s.programa,
		"/grupos?periodoId=" + s.periodo, "/periodos", "/asignaciones?periodoId=" + s.periodo,
		"/sesiones?periodoId=" + s.periodo, "/calendario-excepciones",
	} {
		e.exigir(http.MethodGet, r, nil, a, http.StatusOK)
	}
	e.exigir(http.MethodGet, "/periodos/"+s.periodo, nil, a, http.StatusOK)
	if estado, _ := e.llamar(http.MethodGet, "/periodos/000000000000000000000000", nil, a); estado != http.StatusNotFound {
		t.Fatalf("periodo inexistente: estado %d, esperado 404", estado)
	}
	e.sinErrorInterno(http.MethodPut, "/periodos/"+s.periodo, map[string]interface{}{
		"codigo": "2026-2", "nombre": "Periodo renombrado", "estado": "ACTIVO", "sedeId": s.sede,
		"fechaInicio": time.Now().AddDate(0, 0, -30).Format("2006-01-02"),
		"fechaFin":    time.Now().AddDate(0, 0, 60).Format("2006-01-02"),
	}, a)
	// Periodo con fechas invertidas.
	if estado, _ := e.llamar(http.MethodPost, "/periodos", map[string]interface{}{
		"codigo": "MAL", "nombre": "Mal", "estado": "ACTIVO", "fechaInicio": "2026-12-01", "fechaFin": "2026-01-01",
	}, a); estado < 400 || estado >= 500 {
		t.Fatalf("periodo inválido: estado %d", estado)
	}

	// Excepción de calendario (festivo) y su eliminación.
	exc := e.exigir(http.MethodPost, "/calendario-excepciones", map[string]interface{}{
		"nombre": "Festivo de prueba", "tipo": "FESTIVO", "ambito": "GLOBAL",
		"fechaInicio": time.Now().AddDate(0, 0, 20).Format("2006-01-02"),
		"fechaFin":    time.Now().AddDate(0, 0, 20).Format("2006-01-02"),
	}, a, http.StatusCreated)
	e.sinErrorInterno(http.MethodDelete, "/calendario-excepciones/"+texto(exc["id"]), nil, a)

	// Novedades sobre una sesión futura: aula, docente de reemplazo y cancelación.
	_, sesiones := e.llamar(http.MethodGet, "/sesiones?periodoId="+s.periodo, nil, a)
	lista := elementos(sesiones)
	if len(lista) < 2 {
		t.Fatalf("se esperaban varias sesiones del periodo: %v", sesiones)
	}
	futura := texto(lista[len(lista)-1]["id"])
	e.exigir(http.MethodGet, "/sesiones/"+futura, nil, a, http.StatusOK)
	e.sinErrorInterno(http.MethodPut, "/sesiones/"+futura+"/aula", map[string]interface{}{"nuevoEspacioId": s.espacio2, "motivo": "Mantenimiento"}, a)
	e.sinErrorInterno(http.MethodPatch, "/sesiones/"+futura+"/docente-reemplazo", map[string]interface{}{"docenteId": s.docenteID, "motivo": "Incapacidad"}, a)
	e.sinErrorInterno(http.MethodPost, "/sesiones/"+futura+"/cancelar", map[string]interface{}{"motivo": "Paro"}, a)
	e.sinErrorInterno(http.MethodPost, "/sesiones/000000000000000000000000/cancelar", map[string]interface{}{"motivo": "No existe"}, a)

	// Importación masiva (US-ACA-07): vista previa CSV y confirmación.
	csv := "periodoCodigo,facultadCodigo,programaCodigo,asignaturaCodigo,asignaturaNombre,grupoCodigo,docenteDocumento,aulaCodigo,diaSemana,horaInicio,horaFin,modalidad\n" +
		"2026-2,ING,SIS,FIS1,Física,02,123,A-302,2,07:00,09:00,PRESENCIAL\n" +
		"2026-2,ING,SIS,,Sin código,03,123,A-302,9,25:00,09:00,OTRA\n"
	e.enviarTexto(http.MethodPost, "/academico/importar/preview", "text/csv", csv, a)
	e.sinErrorInterno(http.MethodPost, "/academico/importar", map[string]interface{}{
		"filas": []map[string]interface{}{{
			"numeroFila": 1, "periodoCodigo": "2026-2", "facultadCodigo": "ING", "programaCodigo": "SIS",
			"asignaturaCodigo": "FIS1", "asignaturaNombre": "Física", "grupoCodigo": "02", "docenteDocumento": "123",
			"aulaCodigo": "A-302", "diaSemana": 2, "horaInicio": "07:00", "horaFin": "09:00", "modalidad": "PRESENCIAL", "valida": true,
		}},
	}, a)
	e.sinErrorInterno(http.MethodPost, "/academico/importar", map[string]interface{}{"filas": []interface{}{}}, a)

	// Eliminaciones: asignación y entidades sin dependencias.
	e.sinErrorInterno(http.MethodDelete, "/asignaciones/"+s.asignacion, nil, a)
	e.sinErrorInterno(http.MethodDelete, "/grupos/"+s.grupo, nil, a)
	e.sinErrorInterno(http.MethodDelete, "/asignaturas/"+s.asignatura, nil, a)
	e.sinErrorInterno(http.MethodDelete, "/programas/"+s.programa, nil, a)
	e.sinErrorInterno(http.MethodDelete, "/facultades/"+s.facultad, nil, a)
}

// Una asignación virtual no exige geocerca: el docente marca desde cualquier lugar (RF-MAR, modalidad).
func TestAcademico_SesionVirtualSinGeocerca(t *testing.T) {
	e := nuevoEntorno(t)
	s := construirEscenario(e)
	e.exigir(http.MethodDelete, "/asignaciones/"+s.asignacion, nil, s.admin, http.StatusNoContent)

	ahora := time.Now().In(bogota)
	inicio := ahora.Truncate(time.Minute).Add(-2 * time.Minute)
	fin := inicio.Add(90 * time.Minute)
	if fin.Day() != inicio.Day() {
		t.Skip("la franja virtual cruzaría la medianoche")
	}
	grupo := e.exigir(http.MethodPost, "/grupos", map[string]interface{}{"numero": "V1", "asignaturaId": s.asignatura, "periodoId": s.periodo, "cupo": 40}, s.admin, http.StatusCreated)
	e.exigir(http.MethodPost, "/asignaciones", map[string]interface{}{
		"periodoId": s.periodo, "docenteIds": []string{s.docenteID}, "grupoId": texto(grupo["id"]),
		"asignaturaId": s.asignatura, "facultadId": s.facultad,
		"franja":    map[string]interface{}{"diaSemana": int(ahora.Weekday()+6)%7 + 1, "horaInicio": inicio.Format("15:04"), "horaFin": fin.Format("15:04")},
		"modalidad": "VIRTUAL",
	}, s.admin, http.StatusCreated)
	e.exigir(http.MethodPost, "/periodos/"+s.periodo+"/generar-sesiones", map[string]interface{}{}, s.admin, http.StatusOK)

	activa := e.exigir(http.MethodGet, "/me/sesiones/activa", nil, s.docente, http.StatusOK)
	sesion, _ := activa["sesion"].(map[string]interface{})
	if sesion["modalidad"] != "VIRTUAL" {
		t.Fatalf("se esperaba la sesión virtual activa: %v", activa)
	}
	// Coordenadas a kilómetros del campus.
	r := e.exigir(http.MethodPost, "/marcajes", s.marcaje(texto(sesion["id"]), 4.6097, -74.0817, "k-virtual"), s.docente, http.StatusCreated)
	if r["resultado"] != "PRESENTE" {
		t.Fatalf("la sesión virtual no debe validar geocerca: %v", r)
	}
}
