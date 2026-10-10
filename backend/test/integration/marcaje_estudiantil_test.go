package integration

import (
	"net/http"
	"testing"
)

const (
	correoEstudiante  = "estudiante@siaa.edu.co"
	correoEstudiante2 = "estudiante2@siaa.edu.co"
	claveEstudiante   = "Estudiante1234*"
)

// estudianteListo inicia sesión como estudiante, acepta el aviso y vincula su dispositivo.
func estudianteListo(e *entorno, correo, dispositivo string) string {
	e.t.Helper()
	token := texto(e.iniciarSesion(correo, claveEstudiante, dispositivo)["accessToken"])
	version := e.exigir(http.MethodGet, "/me/consentimiento", nil, token, http.StatusOK)["versionVigente"]
	e.exigir(http.MethodPost, "/me/consentimiento", map[string]interface{}{
		"version": version, "acepta": true, "dispositivoId": dispositivo,
	}, token, http.StatusOK)
	e.exigir(http.MethodPost, "/auth/devices", map[string]interface{}{
		"instalacionId": dispositivo, "modelo": "Pixel", "so": "Android 14", "versionApp": "1.0.0",
	}, token, http.StatusCreated)
	return token
}

func marcajeDe(s *escenario, dispositivo, sesionID, clave string) map[string]interface{} {
	m := s.marcaje(sesionID, 1.1477, -76.6511, clave)
	m["dispositivoId"] = dispositivo
	return m
}

// US-MAR-13 y US-MAR-14: integrantes del grupo, ventana estudiantil y lista manual.
func TestMarcaje_Estudiantil(t *testing.T) {
	e := nuevoEntorno(t)
	s := construirEscenario(e)
	est := estudianteListo(e, correoEstudiante, "disp-est-1")
	est2 := estudianteListo(e, correoEstudiante2, "disp-est-2")
	sesionID := texto(e.exigir(http.MethodGet, "/me/sesiones/activa", nil, s.docente, http.StatusOK)["sesion"].(map[string]interface{})["id"])

	// Sin pertenecer al grupo no hay sesión ni marcaje (AC-03).
	if activa := e.exigir(http.MethodGet, "/me/sesiones/activa", nil, est, http.StatusOK); activa["sesion"] != nil {
		t.Fatalf("un estudiante sin grupo no debe ver sesiones: %v", activa)
	}
	if r := e.exigir(http.MethodPost, "/marcajes", marcajeDe(s, "disp-est-1", sesionID, "e1-a"), est, http.StatusCreated); r["resultado"] != "RECHAZADO_SIN_ASIGNACION" {
		t.Fatalf("estudiante fuera del grupo: %v", r)
	}

	// El administrador arma el grupo por correo; lo que no es un estudiante se informa.
	res := e.exigir(http.MethodPut, "/grupos/"+s.grupo+"/estudiantes", map[string]interface{}{
		"estudiantes": []string{correoEstudiante, "nadie@siaa.edu.co", correoDocente},
	}, s.admin, http.StatusOK)
	if len(elementos(res["estudiantes"])) != 1 || len(res["noEncontrados"].([]interface{})) != 1 ||
		len(res["noEstudiantes"].([]interface{})) != 1 {
		t.Fatalf("resultado de integrantes inesperado: %v", res)
	}
	estID := texto(elementos(res["estudiantes"])[0]["id"])
	if _, lista := e.llamar(http.MethodGet, "/grupos/"+s.grupo+"/estudiantes", nil, s.admin); len(elementos(lista)) != 1 {
		t.Fatalf("GET de integrantes inesperado: %v", lista)
	}

	// Integrante, pero con la ventana cerrada: ve la sesión y se rechaza por horario (AC-04).
	activa := e.exigir(http.MethodGet, "/me/sesiones/activa", nil, est, http.StatusOK)
	if activa["sesion"] == nil || activa["ventana"].(map[string]interface{})["estado"] != "NO_ABIERTA" {
		t.Fatalf("el estudiante debe ver la sesión pendiente de abrir: %v", activa)
	}
	if r := e.exigir(http.MethodPost, "/marcajes", marcajeDe(s, "disp-est-1", sesionID, "e1-b"), est, http.StatusCreated); r["resultado"] != "RECHAZADO_FUERA_DE_HORARIO" {
		t.Fatalf("con la ventana cerrada se rechaza por horario: %v", r)
	}

	// Solo el docente de la sesión abre la ventana; el estudiante marca con las mismas reglas (AC-01, AC-02).
	e.exigir(http.MethodPost, "/sesiones/"+sesionID+"/ventana-estudiantil", map[string]interface{}{"duracionMinutos": 10}, est, http.StatusForbidden)
	e.exigir(http.MethodPost, "/sesiones/"+sesionID+"/ventana-estudiantil", map[string]interface{}{"duracionMinutos": 10}, s.docente, http.StatusOK)
	if v := e.exigir(http.MethodGet, "/me/sesiones/activa", nil, s.docente, http.StatusOK)["ventanaEstudiantil"].(map[string]interface{}); v["abierta"] != true {
		t.Fatalf("el docente debe ver la ventana estudiantil abierta: %v", v)
	}
	if v := e.exigir(http.MethodGet, "/me/sesiones/activa", nil, est, http.StatusOK)["ventana"].(map[string]interface{}); v["estado"] != "ABIERTA" {
		t.Fatalf("la ventana estudiantil debe verse abierta: %v", v)
	}
	if r := e.exigir(http.MethodPost, "/marcajes", marcajeDe(s, "disp-est-1", sesionID, "e1-c"), est, http.StatusCreated); r["resultado"] != "PRESENTE" {
		t.Fatalf("el estudiante dentro del aula y de la ventana marca presente: %v", r)
	}
	if r := e.exigir(http.MethodPost, "/marcajes", marcajeDe(s, "disp-est-2", sesionID, "e2-a"), est2, http.StatusCreated); r["resultado"] != "RECHAZADO_SIN_ASIGNACION" {
		t.Fatalf("quien no integra el grupo se rechaza aun con la ventana abierta: %v", r)
	}

	// Lista manual: muestra el grupo; el marcaje geolocalizado prevalece y los ajenos se informan (US-MAR-14).
	lista := e.exigir(http.MethodGet, "/sesiones/"+sesionID+"/lista-manual", nil, s.docente, http.StatusOK)
	filas := elementos(lista["estudiantes"])
	if len(filas) != 1 || filas[0]["id"] != estID || filas[0]["bloqueado"] != true {
		t.Fatalf("lista del grupo inesperada: %v", lista)
	}
	reg := e.exigir(http.MethodPost, "/sesiones/"+sesionID+"/lista-manual", map[string]interface{}{
		"motivo": "Caída de la red del bloque",
		"estudiantes": []map[string]interface{}{
			{"estudianteId": estID, "presente": false}, {"estudianteId": "000000000000000000000000", "presente": true},
		},
	}, s.docente, http.StatusOK)
	if reg["registrados"] != float64(0) || reg["conservados"] != float64(1) || len(reg["noPertenecen"].([]interface{})) != 1 {
		t.Fatalf("resultado de lista manual inesperado: %v", reg)
	}

	// Al cerrar la ventana, un nuevo integrante ya no puede marcar (AC-04).
	e.exigir(http.MethodPut, "/grupos/"+s.grupo+"/estudiantes", map[string]interface{}{
		"estudiantes": []string{correoEstudiante, correoEstudiante2},
	}, s.admin, http.StatusOK)
	e.exigir(http.MethodDelete, "/sesiones/"+sesionID+"/ventana-estudiantil", nil, s.docente, http.StatusOK)
	if r := e.exigir(http.MethodPost, "/marcajes", marcajeDe(s, "disp-est-2", sesionID, "e2-b"), est2, http.StatusCreated); r["resultado"] != "RECHAZADO_FUERA_DE_HORARIO" {
		t.Fatalf("con la ventana cerrada por el docente se rechaza: %v", r)
	}

	// AC-05: el estudiante consulta su acumulado por asignatura.
	_, asistencia := e.llamar(http.MethodGet, "/me/asistencia", nil, est)
	filasAsis := elementos(asistencia)
	if len(filasAsis) != 1 || filasAsis[0]["asignatura"] != "Cálculo" {
		t.Fatalf("asistencia del estudiante inesperada: %v", asistencia)
	}
}
