package integration

import (
	"encoding/json"
	"net/http"
	"strings"
	"testing"
)

// US-LEG-02 AC-01 y AC-04: el canal se publica con sus plazos y el titular descarga una copia
// estructurada de sus datos, marcajes, justificaciones y consentimientos.
func TestDerechos_CanalYCopiaDeDatos(t *testing.T) {
	e := nuevoEntorno(t)
	s := construirEscenario(e)
	canal := e.exigir(http.MethodGet, "/privacidad/derechos", nil, "", http.StatusOK)
	if plazos := elementos(map[string]interface{}{"items": canal["plazos"]}); len(plazos) != 3 || plazos[1]["diasHabiles"] != float64(15) {
		t.Fatalf("el canal debe publicar los plazos legales: %v", canal)
	}

	activa := e.exigir(http.MethodGet, "/me/sesiones/activa", nil, s.docente, http.StatusOK)
	sesionID := texto(activa["sesion"].(map[string]interface{})["id"])
	e.exigir(http.MethodPost, "/marcajes", s.marcaje(sesionID, 1.1477, -76.6511, "k-derechos"), s.docente, http.StatusCreated)

	rec := e.descargar("/me/datos", s.docente, http.StatusOK)
	if !strings.Contains(rec.Header().Get("Content-Disposition"), "mis-datos-siaa.json") {
		t.Fatalf("la copia debe entregarse como archivo: %v", rec.Header())
	}
	var copia map[string]interface{}
	if err := json.Unmarshal(rec.Body.Bytes(), &copia); err != nil {
		t.Fatalf("copia no es JSON: %v", err)
	}
	titular := copia["titular"].(map[string]interface{})
	if titular["correo"] != correoDocente || titular["passwordHash"] != nil {
		t.Fatalf("datos personales sin credenciales: %v", titular)
	}
	for _, clave := range []string{"marcajes", "consentimientos", "dispositivos"} {
		if l, _ := copia[clave].([]interface{}); len(l) == 0 {
			t.Fatalf("la copia debe incluir %s: %v", clave, copia[clave])
		}
	}
	if _, ok := copia["justificaciones"].([]interface{}); !ok {
		t.Fatalf("la copia debe incluir las justificaciones: %v", copia["justificaciones"])
	}
	if e.auditorias("DATOS_PERSONALES_EXPORTADOS", s.docenteID) != 1 {
		t.Fatal("la entrega de la copia debe auditarse")
	}
}

// US-LEG-02 AC-02 y AC-03: rectificación y supresión generan un caso con responsable y plazo;
// la resolución se aplica y queda auditada; la supresión explica qué se conserva y por qué.
func TestDerechos_RectificacionYSupresion(t *testing.T) {
	e := nuevoEntorno(t)
	s := construirEscenario(e)
	coord := e.token(correoCoord, claveCoord)

	e.exigir(http.MethodPost, "/me/derechos/solicitudes", map[string]interface{}{"tipo": "RECTIFICACION", "descripcion": "corto"}, s.docente, http.StatusUnprocessableEntity)
	rect := e.exigir(http.MethodPost, "/me/derechos/solicitudes", map[string]interface{}{
		"tipo": "RECTIFICACION", "descripcion": "Mi apellido está mal escrito en el sistema",
		"cambios": map[string]string{"apellido": "Pérez Rojas", "correo": "no@se.cambia"},
	}, s.docente, http.StatusCreated)
	if rect["estado"] != "RADICADA" || rect["responsableId"] == nil || rect["venceEn"] == nil {
		t.Fatalf("el caso debe tener responsable y plazo: %v", rect)
	}
	if c := rect["cambios"].(map[string]interface{}); len(c) != 1 {
		t.Fatalf("solo se aceptan campos rectificables: %v", c)
	}
	e.exigir(http.MethodPost, "/me/derechos/solicitudes", map[string]interface{}{
		"tipo": "RECTIFICACION", "descripcion": "Otra rectificación pendiente", "cambios": map[string]string{"nombre": "X"},
	}, s.docente, http.StatusConflict)

	// La bandeja exige usuario:editar; el coordinador no la ve.
	e.exigir(http.MethodGet, "/privacidad/solicitudes", nil, coord, http.StatusForbidden)
	bandeja := e.exigirLista("/privacidad/solicitudes?abiertas=true", s.admin)
	if len(bandeja) != 1 || bandeja[0]["titularCorreo"] != correoDocente || bandeja[0]["vencida"] != false {
		t.Fatalf("bandeja de atención: %v", bandeja)
	}
	id := texto(rect["id"])
	if r := e.exigir(http.MethodPost, "/privacidad/solicitudes/"+id+"/asumir", nil, s.admin, http.StatusOK); r["estado"] != "EN_TRAMITE" {
		t.Fatalf("asumir: %v", r)
	}
	e.exigir(http.MethodPost, "/privacidad/solicitudes/"+id+"/resolver", map[string]interface{}{"atendida": true, "respuesta": "x"}, s.admin, http.StatusUnprocessableEntity)
	res := e.exigir(http.MethodPost, "/privacidad/solicitudes/"+id+"/resolver", map[string]interface{}{
		"atendida": true, "respuesta": "Se corrigió el apellido según el documento de identidad.",
	}, s.admin, http.StatusOK)
	if res["estado"] != "ATENDIDA" || res["resueltaEn"] == nil {
		t.Fatalf("resolución: %v", res)
	}
	if perfil := e.exigir(http.MethodGet, "/me/perfil", nil, s.docente, http.StatusOK); !strings.Contains(texto(perfil["apellido"])+texto(perfil["nombre"]), "Pérez Rojas") {
		t.Fatalf("la rectificación debe aplicarse a la cuenta: %v", perfil)
	}
	e.exigir(http.MethodPost, "/privacidad/solicitudes/"+id+"/resolver", map[string]interface{}{"atendida": false, "respuesta": "Respuesta repetida"}, s.admin, http.StatusConflict)
	if e.auditorias("SOLICITUD_DERECHOS_ATENDIDA", id) != 1 || e.auditorias("DATOS_RECTIFICADOS", s.docenteID) != 1 {
		t.Fatal("la resolución y la rectificación deben auditarse")
	}

	// Supresión: evaluación con fundamento y aplicación de lo eliminable.
	activa := e.exigir(http.MethodGet, "/me/sesiones/activa", nil, s.docente, http.StatusOK)
	creado := e.exigir(http.MethodPost, "/marcajes", s.marcaje(texto(activa["sesion"].(map[string]interface{})["id"]), 1.1477, -76.6511, "k-supresion"), s.docente, http.StatusCreated)
	eval := e.exigir(http.MethodGet, "/me/derechos/supresion", nil, s.docente, http.StatusOK)
	decisiones := map[string]string{}
	for _, el := range elementos(map[string]interface{}{"items": eval["elementos"]}) {
		if texto(el["fundamento"]) == "" {
			t.Fatalf("cada categoría debe traer su fundamento: %v", el)
		}
		decisiones[texto(el["categoria"])] = texto(el["decision"])
	}
	if decisiones["UBICACIONES_MARCAJE"] != "ELIMINABLE" || decisiones["REGISTROS_ASISTENCIA"] != "CONSERVAR" || decisiones["CONSENTIMIENTOS"] != "CONSERVAR" {
		t.Fatalf("evaluación de supresión: %v", decisiones)
	}
	sup := e.exigir(http.MethodPost, "/me/derechos/solicitudes", map[string]interface{}{
		"tipo": "SUPRESION", "descripcion": "Solicito suprimir mis datos de ubicación",
	}, s.docente, http.StatusCreated)
	if ev, _ := sup["evaluacion"].([]interface{}); len(ev) == 0 {
		t.Fatalf("la solicitud de supresión debe traer la evaluación: %v", sup)
	}
	e.exigir(http.MethodPost, "/privacidad/solicitudes/"+texto(sup["id"])+"/resolver", map[string]interface{}{
		"atendida": true, "respuesta": "Se anonimizaron sus ubicaciones; la asistencia se conserva por obligación legal.",
	}, s.admin, http.StatusOK)
	if c := coordenadas(e, texto(creado["marcajeId"])); c != nil {
		t.Fatalf("la supresión debe anonimizar las ubicaciones: %v", c)
	}
	mias := e.exigirLista("/me/derechos/solicitudes", s.docente)
	if len(mias) != 2 {
		t.Fatalf("el titular ve sus solicitudes con su estado: %v", mias)
	}
	if e.auditorias("DATOS_SUPRIMIDOS", s.docenteID) != 1 {
		t.Fatal("la supresión debe auditarse")
	}
}
