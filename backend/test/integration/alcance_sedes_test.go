package integration

import (
	"net/http"
	"testing"
)

// US-ROL-02 AC-04/AC-06: sin ámbitos un rol no institucional no ve nada; el coordinador ve solo
// las sedes de sus facultades y el administrador institucional ve todo, sin ámbitos.
func TestAlcance_SedesYEspaciosPorAmbito(t *testing.T) {
	e := nuevoEntorno(t)
	s := construirEscenario(e)

	// El coordinador semilla trae la facultad de demostración: no ve la sede del escenario.
	semilla := e.token(correoCoord, claveCoord)
	sedes := e.exigirLista("/sedes", semilla)
	if len(sedes) != 1 || sedes[0]["codigo"] != "DEMO" {
		t.Fatalf("el coordinador semilla solo debe ver la sede de demostración: %v", sedes)
	}
	if l := e.exigirLista("/espacios", semilla); len(l) != 0 {
		t.Fatalf("el coordinador semilla no debe ver espacios de otra sede: %v", l)
	}
	antes := e.auditorias("AMBITO_DENEGADO", "")
	e.exigir(http.MethodGet, "/sedes/"+s.sede, nil, semilla, http.StatusForbidden)
	e.exigir(http.MethodGet, "/espacios?sedeId="+s.sede, nil, semilla, http.StatusForbidden)
	e.exigir(http.MethodGet, "/espacios/"+s.espacio, nil, semilla, http.StatusForbidden)
	e.exigir(http.MethodGet, "/bloques/"+s.bloque, nil, semilla, http.StatusForbidden)
	if d := e.auditorias("AMBITO_DENEGADO", "") - antes; d != 4 {
		t.Fatalf("cada 403 por ámbito debe auditarse: %d", d)
	}

	// Un coordinador sin ámbitos no ve nada.
	crear := func(correo, rol string, ambitos []map[string]interface{}) string {
		e.exigir(http.MethodPost, "/usuarios", map[string]interface{}{
			"correo": correo, "nombre": "Prueba", "apellido": "Alcance", "password": "AlcancePrueba2026*",
			"roles": []map[string]interface{}{{"nombre": rol}}, "ambitos": ambitos,
		}, s.admin, http.StatusCreated)
		return e.token(correo, "AlcancePrueba2026*")
	}
	sinAmbito := crear("coord.sin@siaa.edu.co", "COORDINADOR", []map[string]interface{}{})
	for _, ruta := range []string{"/sedes", "/espacios", "/bloques"} {
		if l := e.exigirLista(ruta, sinAmbito); len(l) != 0 {
			t.Fatalf("sin ámbitos GET %s debe venir vacío: %v", ruta, l)
		}
	}
	e.exigir(http.MethodGet, "/espacios/"+s.espacio, nil, sinAmbito, http.StatusForbidden)

	// Con la facultad del escenario ve su sede, sus bloques y sus espacios.
	conFacultad := crear("coord.fac@siaa.edu.co", "COORDINADOR", []map[string]interface{}{{"tipo": "FACULTAD", "id": s.facultad}})
	if l := e.exigirLista("/sedes", conFacultad); len(l) != 1 || l[0]["id"] != s.sede {
		t.Fatalf("la sede de su facultad: %v", l)
	}
	if l := e.exigirLista("/espacios", conFacultad); len(l) != 2 {
		t.Fatalf("los espacios de su sede: %v", l)
	}
	if l := e.exigirLista("/bloques", conFacultad); len(l) != 1 {
		t.Fatalf("los bloques de su sede: %v", l)
	}
	e.exigir(http.MethodGet, "/espacios/"+s.espacio, nil, conFacultad, http.StatusOK)

	// El administrador institucional opera toda la institución sin ámbitos (rol global).
	adminInst := crear("admin.inst@siaa.edu.co", "ADMIN_INSTITUCIONAL", []map[string]interface{}{})
	if l := e.exigirLista("/sedes", adminInst); len(l) < 2 {
		t.Fatalf("el administrador institucional ve todas las sedes: %v", l)
	}
	e.exigir(http.MethodGet, "/espacios/"+s.espacio, nil, adminInst, http.StatusOK)
}
