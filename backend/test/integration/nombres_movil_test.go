package integration

import (
	"net/http"
	"testing"
)

// App móvil (§9.1): el perfil muestra la cuenta y el dispositivo vinculado, y los listados de
// marcajes traen asignatura, grupo, aula y persona por nombre en lugar de identificadores.
func TestMovil_PerfilYMarcajesConNombres(t *testing.T) {
	e := nuevoEntorno(t)
	s := construirEscenario(e)

	perfil := e.exigir(http.MethodGet, "/me/perfil", nil, s.docente, http.StatusOK)
	roles, _ := perfil["roles"].([]interface{})
	dispositivos, _ := perfil["dispositivos"].([]interface{})
	if perfil["correo"] != correoDocente || len(roles) == 0 || roles[0] != "DOCENTE" {
		t.Fatalf("el perfil debe traer la cuenta y sus roles: %v", perfil)
	}
	if len(dispositivos) != 1 || dispositivos[0].(map[string]interface{})["instalacionId"] != s.dispositivo {
		t.Fatalf("el perfil debe mostrar el dispositivo vinculado: %v", perfil)
	}
	if _, conHash := perfil["passwordHash"]; conHash {
		t.Fatalf("el perfil no debe exponer credenciales: %v", perfil)
	}

	activa := e.exigir(http.MethodGet, "/me/sesiones/activa", nil, s.docente, http.StatusOK)
	sesionID := texto(activa["sesion"].(map[string]interface{})["id"])
	e.exigir(http.MethodPost, "/marcajes", s.marcaje(sesionID, 1.1477, -76.6511, "k-nombres"), s.docente, http.StatusCreated)

	for _, consulta := range []struct{ ruta, token string }{
		{"/me/historial", s.docente},
		{"/marcajes?sesionId=" + sesionID, s.admin},
	} {
		items := elementos(e.exigir(http.MethodGet, consulta.ruta, nil, consulta.token, http.StatusOK))
		if len(items) == 0 {
			t.Fatalf("%s: se esperaba el marcaje", consulta.ruta)
		}
		m := items[0]
		if m["asignaturaNombre"] != "Cálculo" || m["grupoNumero"] != "01" || m["espacioCodigo"] != "A-301" {
			t.Fatalf("%s: el marcaje debe traer asignatura, grupo y aula por nombre: %v", consulta.ruta, m)
		}
		if nombre := texto(m["usuarioNombre"]); nombre == "" || nombre == s.docenteID {
			t.Fatalf("%s: el marcaje debe traer el nombre de la persona: %v", consulta.ruta, m)
		}
		if m["id"] == "" || m["resultado"] == nil {
			t.Fatalf("%s: se conservan los campos del marcaje: %v", consulta.ruta, m)
		}
	}
}
