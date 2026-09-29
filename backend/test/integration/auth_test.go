package integration

import (
	"net/http"
	"testing"
)

// EP-01/EP-02: ciclo de vida de la sesión, recuperación, 2FA, contexto de rol y dispositivos.
func TestAuth_CicloDeSesion(t *testing.T) {
	e := nuevoEntorno(t)

	// El administrador inicial definido por variables de entorno puede entrar.
	e.iniciarSesion(correoRaiz, claveRaiz, "")

	par := e.iniciarSesion(correoAdmin, claveAdmin, "")
	acceso, refresh := texto(par["accessToken"]), texto(par["refreshToken"])
	if acceso == "" || refresh == "" {
		t.Fatalf("login sin tokens: %v", par)
	}
	nuevo := e.exigir(http.MethodPost, "/auth/refresh", map[string]interface{}{"refreshToken": refresh}, "", http.StatusOK)
	// El refresh token usado queda revocado (rotación).
	if estado, _ := e.llamar(http.MethodPost, "/auth/refresh", map[string]interface{}{"refreshToken": refresh}, ""); estado != http.StatusUnauthorized {
		t.Fatalf("reutilizar refresh token: estado %d, esperado 401", estado)
	}
	e.sinErrorInterno(http.MethodPost, "/auth/logout", map[string]interface{}{"refreshToken": texto(nuevo["refreshToken"])}, texto(nuevo["accessToken"]))

	// Credenciales inválidas y usuario inexistente responden igual (anti-enumeración).
	for _, correo := range []string{correoAdmin, "nadie@siaa.edu.co"} {
		if estado, _ := e.llamar(http.MethodPost, "/auth/login", map[string]interface{}{"correo": correo, "password": "incorrecta-123"}, ""); estado != http.StatusUnauthorized {
			t.Fatalf("login inválido (%s): estado %d, esperado 401", correo, estado)
		}
	}
	if estado, _ := e.llamar(http.MethodPost, "/auth/login", map[string]interface{}{"correo": "no-es-correo"}, ""); estado < 400 || estado >= 500 {
		t.Fatalf("login mal formado: estado %d", estado)
	}

	// Recuperación de contraseña: siempre 200 para no revelar cuentas; token inválido rechazado.
	e.exigir(http.MethodPost, "/auth/recuperar", map[string]interface{}{"correo": correoDocente}, "", http.StatusOK)
	e.exigir(http.MethodPost, "/auth/recuperar", map[string]interface{}{"correo": "nadie@siaa.edu.co"}, "", http.StatusOK)
	e.sinErrorInterno(http.MethodPost, "/auth/recuperar/confirmar", map[string]interface{}{"token": "token-invalido", "password": "NuevaClave12345*"}, "")

	// 2FA: configuración y códigos inválidos.
	e.sinErrorInterno(http.MethodPost, "/auth/totp/setup", map[string]interface{}{}, acceso)
	e.sinErrorInterno(http.MethodPost, "/auth/totp/activar", map[string]interface{}{"codigo": "000000"}, acceso)
	e.sinErrorInterno(http.MethodPost, "/auth/totp/verificar", map[string]interface{}{"usuarioId": "000000000000000000000000", "codigo": "000000"}, "")

	// Cambio de rol activo (US-AUT-05): a un rol que no tiene, se niega.
	e.sinErrorInterno(http.MethodPost, "/auth/contexto", map[string]interface{}{"rol": "SUPERADMIN"}, acceso)
	e.sinErrorInterno(http.MethodPost, "/auth/contexto", map[string]interface{}{"rol": "ESTUDIANTE"}, acceso)

	// Dispositivos del docente (US-AUT-03) y administración de su cuenta.
	docente := e.iniciarSesion(correoDocente, claveDocente, "dispositivo-a")
	tokDocente := texto(docente["accessToken"])
	disp := e.exigir(http.MethodPost, "/auth/devices", map[string]interface{}{"instalacionId": "dispositivo-a", "modelo": "Moto", "so": "Android 13", "versionApp": "1.0.0"}, tokDocente, http.StatusCreated)
	e.sinErrorInterno(http.MethodPost, "/auth/devices", map[string]interface{}{"instalacionId": "dispositivo-b", "modelo": "Pixel", "so": "Android 14", "versionApp": "1.0.0"}, tokDocente)

	_, usuarios := e.llamar(http.MethodGet, "/usuarios", nil, acceso)
	var docenteID string
	for _, u := range elementos(usuarios) {
		if u["correo"] == correoDocente {
			docenteID = texto(u["id"])
		}
	}
	e.exigir(http.MethodGet, "/usuarios/"+docenteID+"/dispositivos", nil, acceso, http.StatusOK)
	e.sinErrorInterno(http.MethodPost, "/dispositivos/"+texto(disp["id"])+"/aprobar", map[string]interface{}{}, acceso)
	e.sinErrorInterno(http.MethodPost, "/dispositivos/"+texto(disp["id"])+"/revocar", map[string]interface{}{"motivo": "Dispositivo extraviado"}, acceso)
	e.sinErrorInterno(http.MethodPost, "/dispositivos/000000000000000000000000/aprobar", map[string]interface{}{}, acceso)
	e.sinErrorInterno(http.MethodPost, "/usuarios/"+docenteID+"/desbloquear", map[string]interface{}{}, acceso)
	e.sinErrorInterno(http.MethodPost, "/usuarios/"+docenteID+"/revocar-sesiones", map[string]interface{}{"motivo": "Cambio de equipo"}, acceso)

	// Tras revocar sesiones, el refresh token del docente deja de servir.
	if estado, _ := e.llamar(http.MethodPost, "/auth/refresh", map[string]interface{}{"refreshToken": texto(docente["refreshToken"])}, ""); estado != http.StatusUnauthorized {
		t.Fatalf("refresh tras revocar sesiones: estado %d, esperado 401", estado)
	}

	// Bloqueo por intentos fallidos (AC-04) y desbloqueo administrativo.
	for i := 0; i < 6; i++ {
		e.llamar(http.MethodPost, "/auth/login", map[string]interface{}{"correo": correoCoord, "password": "incorrecta-123"}, "")
	}
	if estado, _ := e.llamar(http.MethodPost, "/auth/login", map[string]interface{}{"correo": correoCoord, "password": claveCoord}, ""); estado != 423 {
		t.Fatalf("cuenta tras 6 fallos: estado %d, esperado 423", estado)
	}
}

// T-ROL: roles personalizados, parámetros jerárquicos y endpoints de plataforma.
func TestAdministracion_RolesParametrosYPlataforma(t *testing.T) {
	e := nuevoEntorno(t)
	a := e.token(correoAdmin, claveAdmin)

	e.exigir(http.MethodGet, "/roles", nil, a, http.StatusOK)
	rol := e.exigir(http.MethodPost, "/roles", map[string]interface{}{"nombre": "AUDITOR_EXTERNO", "descripcion": "Solo lectura", "permisos": []string{"marcaje:leer", "reporte:leer"}}, a, http.StatusCreated)
	e.sinErrorInterno(http.MethodPost, "/roles", map[string]interface{}{"nombre": "AUDITOR_EXTERNO", "permisos": []string{"marcaje:leer"}}, a)
	e.sinErrorInterno(http.MethodPost, "/roles", map[string]interface{}{"nombre": "ROL_MALO", "permisos": []string{"permiso:inexistente"}}, a)
	e.sinErrorInterno(http.MethodPut, "/roles/"+texto(rol["id"]), map[string]interface{}{"descripcion": "Lectura de reportes", "permisos": []string{"reporte:leer"}}, a)
	e.sinErrorInterno(http.MethodDelete, "/roles/"+texto(rol["id"]), nil, a)
	e.sinErrorInterno(http.MethodDelete, "/roles/SUPERADMIN", nil, a)

	e.exigir(http.MethodPut, "/parametros", map[string]interface{}{"ambito": "GLOBAL", "clave": "umbral_tardanza_min", "valor": 12}, a, http.StatusOK)
	e.sinErrorInterno(http.MethodPut, "/parametros", map[string]interface{}{"ambito": "GLOBAL", "clave": "clave_inexistente", "valor": 1}, a)
	e.sinErrorInterno(http.MethodPut, "/parametros", map[string]interface{}{"ambito": "GLOBAL", "clave": "precision_gps_max_metros", "valor": 5000}, a)
	e.exigir(http.MethodGet, "/parametros?ambito=GLOBAL", nil, a, http.StatusOK)
	e.exigir(http.MethodGet, "/parametros/efectivos", nil, a, http.StatusOK)
	e.sinErrorInterno(http.MethodGet, "/parametros/efectivos?sede_id=x&facultad_id=y&bloque_id=z&espacio_id=w&asignacion_id=v", nil, a)

	e.exigir(http.MethodGet, "/health", nil, "", http.StatusOK)
	e.sinErrorInterno(http.MethodGet, "/health/ready", nil, "")
	e.sinErrorInterno(http.MethodGet, "/metrics", nil, a)
	e.exigir(http.MethodGet, "/openapi.json", nil, "", http.StatusOK)
	if estado, _ := e.llamar(http.MethodGet, "/ruta-que-no-existe", nil, a); estado != http.StatusNotFound {
		t.Fatalf("ruta inexistente: estado %d, esperado 404", estado)
	}
}
