package integration

import (
	"encoding/base64"
	"encoding/json"
	"net/http"
	"strings"
	"testing"
)

// RF-ROL-004: el contexto de rol elegido conserva el dispositivo y sobrevive al refresco.
func TestContextoRol_SeConservaAlRefrescar(t *testing.T) {
	e := nuevoEntorno(t)
	a := e.token(correoAdmin, claveAdmin)
	e.exigir(http.MethodPost, "/usuarios", map[string]interface{}{
		"correo": "multi@siaa.edu.co", "nombre": "Mara", "apellido": "Díaz", "password": "MultiRol2026*x",
		"roles": []map[string]interface{}{{"nombre": "DOCENTE"}, {"nombre": "COORDINADOR"}},
	}, a, http.StatusCreated)

	par := e.iniciarSesion("multi@siaa.edu.co", "MultiRol2026*x", "tel-multi")
	if c := claimsDe(t, texto(par["accessToken"])); c["rol"] != "DOCENTE" {
		t.Fatalf("el login activa el primer rol: %v", c)
	}
	cambio := e.exigir(http.MethodPost, "/auth/contexto", map[string]interface{}{"rol": "COORDINADOR"}, texto(par["accessToken"]), http.StatusOK)
	if c := claimsDe(t, texto(cambio["accessToken"])); c["rol"] != "COORDINADOR" || c["did"] != "tel-multi" {
		t.Fatalf("el cambio de contexto debe activar el rol y conservar el dispositivo: %v", c)
	}
	refrescado := e.exigir(http.MethodPost, "/auth/refresh", map[string]interface{}{"refreshToken": cambio["refreshToken"], "dispositivoId": "tel-multi"}, "", http.StatusOK)
	if c := claimsDe(t, texto(refrescado["accessToken"])); c["rol"] != "COORDINADOR" {
		t.Fatalf("el refresco debe conservar el rol elegido: %v", c)
	}
}

// claimsDe decodifica el cuerpo de un JWT sin verificar la firma (solo para inspección).
func claimsDe(t *testing.T, token string) map[string]interface{} {
	t.Helper()
	partes := strings.Split(token, ".")
	if len(partes) != 3 {
		t.Fatalf("token inválido: %q", token)
	}
	crudo, err := base64.RawURLEncoding.DecodeString(partes[1])
	if err != nil {
		t.Fatalf("decodificar token: %v", err)
	}
	var claims map[string]interface{}
	if err := json.Unmarshal(crudo, &claims); err != nil {
		t.Fatalf("leer claims: %v", err)
	}
	return claims
}
