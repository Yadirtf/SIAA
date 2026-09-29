package integration

import (
	"context"
	"net/http"
	"strings"
	"testing"

	"go.mongodb.org/mongo-driver/bson"
)

// US-ROL-01..05: alta, edición, roles, ámbitos, estado e importación CSV de usuarios.
func TestUsuarios_GestionCompleta(t *testing.T) {
	e := nuevoEntorno(t)
	a := e.token(correoAdmin, claveAdmin)

	nuevo := map[string]interface{}{
		"correo": "Coord2@siaa.edu.co", "nombre": "Ana", "apellido": "Rojas", "documento": "900",
		"password": "Coordinadora2026*", "roles": []map[string]interface{}{{"nombre": "COORDINADOR"}},
		"ambitos": []map[string]interface{}{{"tipo": "FACULTAD", "id": "fac-x"}},
	}
	creado := e.exigir(http.MethodPost, "/usuarios", nuevo, a, http.StatusCreated)
	u, _ := creado["usuario"].(map[string]interface{})
	id := texto(u["id"])
	if u["correo"] != "coord2@siaa.edu.co" || id == "" {
		t.Fatalf("alta de usuario: %v", creado)
	}
	// Unicidad de correo y documento, rol inexistente y datos inválidos.
	e.exigir(http.MethodPost, "/usuarios", nuevo, a, http.StatusConflict)
	nuevo["correo"], nuevo["documento"], nuevo["roles"] = "otro@siaa.edu.co", "", []map[string]interface{}{{"nombre": "NO_EXISTE"}}
	e.exigir(http.MethodPost, "/usuarios", nuevo, a, http.StatusUnprocessableEntity)
	e.exigir(http.MethodPost, "/usuarios", map[string]interface{}{"correo": "mal", "nombre": "x", "apellido": "y"}, a, http.StatusUnprocessableEntity)
	// Sin contraseña: se invita por correo a definirla.
	inv := e.exigir(http.MethodPost, "/usuarios", map[string]interface{}{
		"correo": "invitado@siaa.edu.co", "nombre": "Luis", "apellido": "Paz", "roles": []map[string]interface{}{{"nombre": "DOCENTE"}},
	}, a, http.StatusCreated)
	if inv["invitacionEnviada"] != true {
		t.Fatalf("se esperaba invitación por correo: %v", inv)
	}

	e.exigir(http.MethodGet, "/usuarios/"+id, nil, a, http.StatusOK)
	if estado, _ := e.llamar(http.MethodGet, "/usuarios/000000000000000000000000", nil, a); estado != http.StatusNotFound {
		t.Fatalf("usuario inexistente: estado %d", estado)
	}
	_, lista := e.llamar(http.MethodGet, "/usuarios?q=rojas&activo=true&pagina=1&limite=10", nil, a)
	if l := elementos(lista); len(l) != 1 || l[0]["id"] != id {
		t.Fatalf("búsqueda por texto: %v", lista)
	}
	e.exigir(http.MethodPut, "/usuarios/"+id, map[string]interface{}{"correo": "coord2@siaa.edu.co", "nombre": "Ana María", "apellido": "Rojas", "documento": "900"}, a, http.StatusOK)
	e.exigir(http.MethodPut, "/usuarios/"+id, map[string]interface{}{"correo": correoDocente, "nombre": "Ana", "apellido": "Rojas"}, a, http.StatusConflict)
	roles := e.exigir(http.MethodPut, "/usuarios/"+id+"/roles", map[string]interface{}{"roles": []map[string]interface{}{{"nombre": "COORDINADOR"}, {"nombre": "DOCENTE"}}}, a, http.StatusOK)
	if len(roles["roles"].([]interface{})) != 2 {
		t.Fatalf("asignación de roles: %v", roles)
	}
	e.exigir(http.MethodPut, "/usuarios/"+id+"/roles", map[string]interface{}{"roles": []interface{}{}}, a, http.StatusUnprocessableEntity)
	e.exigir(http.MethodPut, "/usuarios/"+id+"/ambitos", map[string]interface{}{"ambitos": []map[string]interface{}{{"tipo": "PAIS", "id": "co"}}}, a, http.StatusUnprocessableEntity)

	// Desactivar exige motivo, bloquea el acceso y se puede revertir.
	e.exigir(http.MethodPost, "/usuarios/"+id+"/desactivar", map[string]interface{}{}, a, http.StatusUnprocessableEntity)
	e.exigir(http.MethodPost, "/usuarios/"+id+"/desactivar", map[string]interface{}{"motivo": "Retiro"}, a, http.StatusOK)
	if estado, _ := e.llamar(http.MethodPost, "/auth/login", map[string]interface{}{"correo": "coord2@siaa.edu.co", "password": "Coordinadora2026*"}, ""); estado < 400 {
		t.Fatalf("un usuario inactivo no debe iniciar sesión: estado %d", estado)
	}
	e.exigir(http.MethodPost, "/usuarios/"+id+"/activar", map[string]interface{}{}, a, http.StatusOK)
	e.token("coord2@siaa.edu.co", "Coordinadora2026*")

	// Cada cambio queda auditado con valor anterior y nuevo (RF-ROL-005).
	for _, accion := range []string{"USUARIO_CREADO", "USUARIO_EDITADO", "ROLES_ASIGNADOS", "USUARIO_DESACTIVADO", "USUARIO_ACTIVADO"} {
		if n := e.auditorias(accion, id); n == 0 {
			t.Fatalf("falta la auditoría %s", accion)
		}
	}

	// Importación CSV: vista previa sin cambios y confirmación de las filas válidas.
	csv := "correo,nombre,apellido,documento,roles\n" +
		"doc1@siaa.edu.co,Pedro,Gil,1001,\n" +
		"doc2@siaa.edu.co,Laura,Mesa,1002,DOCENTE|MONITOR\n" +
		"no-es-correo,Mal,Dato,1003,\n" +
		"doc1@siaa.edu.co,Pedro,Gil,1004,\n"
	_, previa := e.enviarTexto(http.MethodPost, "/usuarios/importar", "text/csv", csv, a)
	if p, _ := previa.(map[string]interface{}); p["validas"] != float64(2) || p["creados"] != float64(0) {
		t.Fatalf("vista previa CSV: %v", previa)
	}
	_, conf := e.enviarTexto(http.MethodPost, "/usuarios/importar?confirmar=true", "text/csv", csv, a)
	if c, _ := conf.(map[string]interface{}); c["creados"] != float64(2) {
		t.Fatalf("confirmación CSV: %v", conf)
	}
	if estado, _ := e.enviarTexto(http.MethodPost, "/usuarios/importar", "text/csv", "nombre\nx\n", a); estado != http.StatusUnprocessableEntity {
		t.Fatalf("CSV sin columnas obligatorias: estado %d", estado)
	}

	// El coordinador no crea usuarios y no ve cuentas fuera de su ámbito (el superadministrador).
	coord := e.token(correoCoord, claveCoord)
	e.exigir(http.MethodPost, "/usuarios", nuevo, coord, http.StatusForbidden)
	_, vistos := e.llamar(http.MethodGet, "/usuarios?limite=200", nil, coord)
	for _, v := range elementos(vistos) {
		if v["correo"] == correoAdmin {
			t.Fatalf("el coordinador no debe ver al superadministrador: %v", v)
		}
	}
}

// auditorias cuenta las entradas de la bitácora con la acción dada sobre la entidad.
func (e *entorno) auditorias(accion, entidadID string) int64 {
	e.t.Helper()
	filtro := bson.M{"accion": accion}
	if entidadID != "" {
		filtro["entidadId"] = entidadID
	}
	n, err := e.cliente.DB().Collection("auditoria").CountDocuments(context.Background(), filtro)
	if err != nil {
		e.t.Fatalf("contar auditoría: %v", err)
	}
	return n
}

// RF-ROL-003 / CA-010: el coordinador solo ve y opera su facultad; fuera de ella recibe 403 auditado.
func TestUsuarios_AlcancePorFacultad(t *testing.T) {
	e := nuevoEntorno(t)
	s := construirEscenario(e)
	otraSede := texto(e.exigir(http.MethodPost, "/sedes", map[string]interface{}{"codigo": "SN", "nombre": "Sede Norte", "direccion": "Calle 2"}, s.admin, http.StatusCreated)["id"])
	otra := texto(e.exigir(http.MethodPost, "/facultades", map[string]interface{}{"codigo": "MED", "nombre": "Medicina", "sedeId": otraSede}, s.admin, http.StatusCreated)["id"])

	cuerpo := map[string]interface{}{
		"correo": "coord.med@siaa.edu.co", "nombre": "Carla", "apellido": "Díaz", "password": "Coordinadora2026*",
		"roles": []map[string]interface{}{{"nombre": "COORDINADOR"}}, "ambitos": []map[string]interface{}{{"tipo": "FACULTAD", "id": otra}},
	}
	id := texto(e.exigir(http.MethodPost, "/usuarios", cuerpo, s.admin, http.StatusCreated)["usuario"].(map[string]interface{})["id"])
	coord := e.token("coord.med@siaa.edu.co", "Coordinadora2026*")

	_, sesiones := e.llamar(http.MethodGet, "/sesiones?periodoId="+s.periodo, nil, s.admin)
	sesionID := texto(elementos(sesiones)[0]["id"])
	if n := elementos(sesiones)[0]; n["asignaturaNombre"] != "Cálculo" || n["grupoNumero"] != "01" || n["espacioCodigo"] != "A-301" {
		t.Fatalf("la sesión debe traer nombres legibles: %v", n)
	}
	if _, fuera := e.llamar(http.MethodGet, "/sesiones?periodoId="+s.periodo, nil, coord); len(elementos(fuera)) != 0 {
		t.Fatalf("el coordinador de otra facultad no debe ver sesiones ajenas: %v", fuera)
	}
	if _, asig := e.llamar(http.MethodGet, "/asignaciones?periodoId="+s.periodo, nil, coord); len(elementos(asig)) != 0 {
		t.Fatalf("el coordinador de otra facultad no debe ver asignaciones ajenas: %v", asig)
	}
	_, facs := e.llamar(http.MethodGet, "/facultades", nil, coord)
	if f := elementos(facs); len(f) != 1 || f[0]["id"] != otra {
		t.Fatalf("el coordinador solo debe ver su facultad: %v", facs)
	}
	antes := e.auditorias("AMBITO_DENEGADO", "")
	e.exigir(http.MethodGet, "/sesiones/"+sesionID, nil, coord, http.StatusForbidden)
	e.exigir(http.MethodGet, "/programas?facultadId="+s.facultad, nil, coord, http.StatusForbidden)
	e.exigir(http.MethodPost, "/sesiones/"+sesionID+"/cancelar", map[string]interface{}{"motivo": "Paro"}, coord, http.StatusForbidden)
	e.exigir(http.MethodPost, "/programas", map[string]interface{}{"codigo": "X", "nombre": "X", "facultadId": s.facultad}, coord, http.StatusForbidden)
	if despues := e.auditorias("AMBITO_DENEGADO", ""); despues-antes != 4 {
		t.Fatalf("cada 403 por ámbito debe auditarse: %d entradas nuevas", despues-antes)
	}
	// Un coordinador no puede otorgar ámbitos que no tiene (ni usa usuario:editar).
	e.exigir(http.MethodPut, "/usuarios/"+id+"/ambitos", map[string]interface{}{"ambitos": []map[string]interface{}{{"tipo": "FACULTAD", "id": s.facultad}}}, coord, http.StatusForbidden)

	// Con la facultad asignada, el coordinador ve y opera sus sesiones.
	e.exigir(http.MethodPut, "/usuarios/"+id+"/ambitos", map[string]interface{}{"ambitos": []map[string]interface{}{{"tipo": "FACULTAD", "id": s.facultad}}}, s.admin, http.StatusOK)
	coord = e.token("coord.med@siaa.edu.co", "Coordinadora2026*")
	if _, dentro := e.llamar(http.MethodGet, "/sesiones?periodoId="+s.periodo, nil, coord); len(elementos(dentro)) == 0 {
		t.Fatalf("el coordinador debe ver las sesiones de su facultad: %v", dentro)
	}
	e.exigir(http.MethodGet, "/sesiones/"+sesionID, nil, coord, http.StatusOK)
	e.exigir(http.MethodGet, "/programas?facultadId="+s.facultad, nil, coord, http.StatusOK)
	if _, marc := e.llamar(http.MethodGet, "/marcajes", nil, coord); marc == nil {
		t.Fatalf("listado de marcajes del coordinador sin respuesta")
	}

	// El docente ve el nombre de la asignatura y el número de grupo en sus sesiones del día.
	hoy := e.exigir(http.MethodGet, "/me/sesiones/hoy", nil, s.docente, http.StatusOK)
	if l := elementos(hoy); len(l) == 0 || l[0]["asignatura"] != "Cálculo" || l[0]["grupo"] != "01" {
		t.Fatalf("sesiones de hoy sin nombres: %v", hoy)
	}
	if !strings.Contains(texto(elementos(sesiones)[0]["espacioNombre"]), "301") {
		t.Fatalf("nombre de aula ausente: %v", elementos(sesiones)[0])
	}
}
