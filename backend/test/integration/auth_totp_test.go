package integration

import (
	"net/http"
	"testing"
)

// US-AUT-05: el segundo factor es obligatorio para roles administrativos y no se puede saltar.
func TestAuth_SegundoFactorObligatorio(t *testing.T) {
	e := nuevoEntorno(t)
	login := map[string]interface{}{"correo": correoAdmin, "password": claveAdmin}

	// AC-01: un administrador sin TOTP recibe un desafío de configuración, no tokens.
	res := e.exigir(http.MethodPost, "/auth/login", login, "", http.StatusOK)
	desafio := texto(res["desafioToken"])
	if desafio == "" || res["accessToken"] != nil || res["requiereConfigurarTOTP"] != true {
		t.Fatalf("login administrativo sin TOTP debe exigir configurarlo: %v", res)
	}
	// El desafío no sirve como token de acceso ni para verificar en lugar de configurar.
	e.exigir(http.MethodGet, "/usuarios", nil, desafio, http.StatusUnauthorized)
	e.exigir(http.MethodPost, "/auth/totp/verificar", map[string]interface{}{"desafioToken": desafio, "codigo": "123456"}, "", http.StatusUnauthorized)
	// El flujo anterior (solo usuarioId + código, sin contraseña) ya no existe.
	e.exigir(http.MethodPost, "/auth/totp/verificar", map[string]interface{}{"usuarioId": "x", "codigo": "123456"}, "", http.StatusUnprocessableEntity)

	// AC-01/AC-03: enrolamiento con 8 códigos de respaldo y activación con el primer código.
	enrol := e.exigir(http.MethodPost, "/auth/totp/enrolar", map[string]interface{}{"desafioToken": desafio}, "", http.StatusOK)
	respaldos, _ := enrol["backupCodes"].([]interface{})
	if texto(enrol["secretKey"]) == "" || len(respaldos) != 8 {
		t.Fatalf("enrolamiento incompleto: %v", enrol)
	}
	e.secretosTOTP[correoAdmin] = texto(enrol["secretKey"])
	e.exigir(http.MethodPost, "/auth/totp/enrolar/confirmar", map[string]interface{}{"desafioToken": desafio, "codigo": "000000"}, "", http.StatusUnprocessableEntity)
	par := e.exigir(http.MethodPost, "/auth/totp/enrolar/confirmar", map[string]interface{}{"desafioToken": desafio, "codigo": e.codigoTOTP(correoAdmin)}, "", http.StatusOK)
	acceso := texto(par["accessToken"])
	if acceso == "" {
		t.Fatalf("confirmar enrolamiento sin tokens: %v", par)
	}
	// Un access token robado no puede reiniciar un segundo factor activo.
	e.exigir(http.MethodPost, "/auth/totp/setup", nil, acceso, http.StatusConflict)

	// AC-02: con TOTP activo se exige el código; un código de respaldo sirve una sola vez.
	res = e.exigir(http.MethodPost, "/auth/login", login, "", http.StatusOK)
	if res["requiereTOTP"] != true || res["accessToken"] != nil {
		t.Fatalf("login con TOTP activo debe pedir el código: %v", res)
	}
	respaldo := texto(respaldos[0])
	e.exigir(http.MethodPost, "/auth/totp/verificar", map[string]interface{}{"desafioToken": texto(res["desafioToken"]), "codigo": respaldo}, "", http.StatusOK)
	res = e.exigir(http.MethodPost, "/auth/login", login, "", http.StatusOK)
	e.exigir(http.MethodPost, "/auth/totp/verificar", map[string]interface{}{"desafioToken": texto(res["desafioToken"]), "codigo": respaldo}, "", http.StatusUnauthorized)

	// AC-05: un rol operativo entra sin segundo factor.
	if texto(e.iniciarSesion(correoDocente, claveDocente, "")["accessToken"]) == "" {
		t.Fatal("el docente debe recibir tokens sin TOTP")
	}

	// AC-04: cinco códigos incorrectos consecutivos bloquean la cuenta (US-AUT-02).
	res = e.exigir(http.MethodPost, "/auth/login", login, "", http.StatusOK)
	reto := texto(res["desafioToken"])
	var estado int
	for i := 0; i < 5; i++ {
		estado, _ = e.llamar(http.MethodPost, "/auth/totp/verificar", map[string]interface{}{"desafioToken": reto, "codigo": "000000"}, "")
	}
	if estado != 423 {
		t.Fatalf("quinto código incorrecto: estado %d, esperado 423", estado)
	}
	e.exigir(http.MethodPost, "/auth/login", login, "", 423)
	e.exigir(http.MethodPost, "/auth/totp/verificar", map[string]interface{}{"desafioToken": reto, "codigo": e.codigoTOTP(correoAdmin)}, "", 423)
}
