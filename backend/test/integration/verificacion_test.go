package integration

import (
	"net/http"
	"testing"
)

// Verificación complementaria por aula (RF-GEO-016): con el parámetro activo, el marcaje debe
// traer un BSSID, baliza o QR configurado en el espacio; los valores se comparan normalizados.
func TestMarcaje_VerificacionComplementariaPorEspacio(t *testing.T) {
	e := nuevoEntorno(t)
	s := construirEscenarioCon(e, map[string]interface{}{"verificacion_complementaria": true})

	e.exigir(http.MethodPut, "/espacios/"+s.espacio+"/verificacion", map[string]interface{}{
		"wifiBssids": []string{"no-es-mac"},
	}, s.admin, http.StatusUnprocessableEntity)
	esp := e.exigir(http.MethodPut, "/espacios/"+s.espacio+"/verificacion", map[string]interface{}{
		"wifiBssids": []string{"A4-2B-8C-11-02-9F", "a4:2b:8c:11:02:9f"}, "qrCodigo": "siaa-a301-7x2k",
	}, s.admin, http.StatusOK)
	v := esp["verificacionComplementaria"].(map[string]interface{})
	if bssids := v["wifiBssids"].([]interface{}); len(bssids) != 1 || bssids[0] != "a4:2b:8c:11:02:9f" || v["qrCodigo"] != "SIAA-A301-7X2K" {
		t.Fatalf("los valores deben guardarse normalizados y sin duplicados: %v", v)
	}
	if n := e.auditorias("VERIFICACION_COMPLEMENTARIA_ACTUALIZADA", s.espacio); n != 1 {
		t.Fatalf("el cambio debe auditarse, hay %d", n)
	}

	activa := e.exigir(http.MethodGet, "/me/sesiones/activa", nil, s.docente, http.StatusOK)
	sesionID := texto(activa["sesion"].(map[string]interface{})["id"])
	metodos, _ := activa["metodosVerificacion"].([]interface{})
	if activa["verificacionComplementariaExigida"] != true || len(metodos) != 2 {
		t.Fatalf("la app debe saber que se exige verificación y con qué métodos: %v", activa)
	}
	if _, filtra := activa["wifiBssids"]; filtra {
		t.Fatalf("la sesión activa no debe revelar los valores del aula: %v", activa)
	}

	sin := e.exigir(http.MethodPost, "/marcajes", s.marcaje(sesionID, 1.1477, -76.6511, "k-sin-verif"), s.docente, http.StatusCreated)
	if sin["resultado"] != "RECHAZADO_VERIFICACION" {
		t.Fatalf("sin verificación el marcaje debe rechazarse: %v", sin)
	}
	otraRed := s.marcaje(sesionID, 1.1477, -76.6511, "k-otra-red")
	otraRed["verificacionComplementaria"] = map[string]interface{}{"metodo": "WIFI", "valor": "00:11:22:33:44:55"}
	if r := e.exigir(http.MethodPost, "/marcajes", otraRed, s.docente, http.StatusCreated); r["resultado"] != "RECHAZADO_VERIFICACION" {
		t.Fatalf("un BSSID ajeno al aula debe rechazarse: %v", r)
	}
	// El QR no sirve como BSSID aunque el valor coincida.
	cruzado := s.marcaje(sesionID, 1.1477, -76.6511, "k-cruzado")
	cruzado["verificacionComplementaria"] = map[string]interface{}{"metodo": "WIFI", "valor": "SIAA-A301-7X2K"}
	if r := e.exigir(http.MethodPost, "/marcajes", cruzado, s.docente, http.StatusCreated); r["resultado"] != "RECHAZADO_VERIFICACION" {
		t.Fatalf("un valor de otro método no debe aceptarse: %v", r)
	}
	wifi := s.marcaje(sesionID, 1.1477, -76.6511, "k-wifi")
	wifi["verificacionComplementaria"] = map[string]interface{}{"metodo": "WIFI", "valor": "A4:2B:8C:11:02:9F"}
	if r := e.exigir(http.MethodPost, "/marcajes", wifi, s.docente, http.StatusCreated); r["resultado"] != "PRESENTE" {
		t.Fatalf("el BSSID del aula debe aceptarse sin importar mayúsculas: %v", r)
	}
}

// Attestation (§ seguridad): con exigir_attestation, la bandera attestationOk del cliente no
// basta; sin un token verificado por el servidor el marcaje se rechaza y queda auditado.
func TestMarcaje_AttestationSeVerificaEnElServidor(t *testing.T) {
	e := nuevoEntorno(t)
	s := construirEscenarioCon(e, map[string]interface{}{"exigir_attestation": true})
	activa := e.exigir(http.MethodGet, "/me/sesiones/activa", nil, s.docente, http.StatusOK)
	sesionID := texto(activa["sesion"].(map[string]interface{})["id"])
	if activa["parametros"].(map[string]interface{})["exigirAttestation"] != true {
		t.Fatalf("la app debe saber que se exige attestation: %v", activa["parametros"])
	}

	solicitud := s.marcaje(sesionID, 1.1477, -76.6511, "k-attest")
	solicitud["integridad"] = map[string]interface{}{"attestationOk": true, "attestationToken": "token-falso"}
	r := e.exigir(http.MethodPost, "/marcajes", solicitud, s.docente, http.StatusCreated)
	if r["resultado"] != "RECHAZADO_INTEGRIDAD" {
		t.Fatalf("una attestation no verificada debe rechazarse: %v", r)
	}
	if n := e.auditorias("MARCAJE_ANOMALIA_SEGURIDAD", ""); n < 1 {
		t.Fatalf("el rechazo por attestation debe auditarse, hay %d", n)
	}
}
