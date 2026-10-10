// Package integration — pruebas de punta a punta del API contra MongoDB real.
// Levantan la aplicación con el mismo cableado de cmd/api (internal/app), sobre una base
// de datos efímera por prueba, y la ejercitan por HTTP como lo hacen web y mobile.
package integration

import (
	"bytes"
	"context"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/siaa/backend/internal/app"
	"github.com/siaa/backend/internal/platform/config"
	applog "github.com/siaa/backend/internal/platform/log"
	mongoRepo "github.com/siaa/backend/internal/repository/mongo"
	"github.com/siaa/backend/internal/repository/mongo/migrations"
	"github.com/siaa/backend/internal/repository/mongo/seed"
	"github.com/siaa/backend/internal/usecase/auth/crypto"
)

// Credenciales de los usuarios semilla de desarrollo (seed/users.go).
const (
	correoAdmin     = "admin@siaa.edu.co"
	claveAdmin      = "Admin12345678*"
	correoDocente   = "docente@siaa.edu.co"
	claveDocente    = "Docente123456*"
	correoCoord     = "coordinador@siaa.edu.co"
	claveCoord      = "Coord12345678*"
	correoRaiz      = "raiz@siaa.edu.co"
	claveRaiz       = "RaizInicial12345*"
	contratoOpenAPI = "../../contracts/openapi.json"
)

// entorno es una instancia completa del API sobre una base de datos propia de la prueba.
type entorno struct {
	t       *testing.T
	app     *app.App
	cliente *mongoRepo.Client
	// secretosTOTP guarda el secreto de segundo factor enrolado por cada correo administrativo.
	secretosTOTP map[string]string
}

// nuevoEntorno crea la base efímera, ejecuta migraciones y semillas y construye la app.
// Requiere MONGO_URI (en CI lo provee el servicio mongo del workflow).
func nuevoEntorno(t *testing.T) *entorno {
	t.Helper()
	uri := os.Getenv("MONGO_URI")
	if uri == "" {
		t.Skip("prueba de integración: define MONGO_URI con un MongoDB real")
	}
	sufijo := make([]byte, 4)
	_, _ = rand.Read(sufijo)
	t.Setenv("MONGO_DB", "siaa_it_"+hex.EncodeToString(sufijo))
	t.Setenv("APP_ENV", "test")
	t.Setenv("RATE_LIMIT_PER_MINUTE", "100000")
	t.Setenv("AUTH_RATE_LIMIT_PER_MINUTE", "60")
	if os.Getenv("JWT_SECRET") == "" {
		t.Setenv("JWT_SECRET", "secreto-de-pruebas-de-integracion-32+")
	}

	cfg, err := config.Load()
	if err != nil {
		t.Fatalf("cargar configuración: %v", err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	cliente, err := mongoRepo.Connect(ctx, cfg.MongoURI, cfg.MongoDB)
	if err != nil {
		t.Fatalf("conectar MongoDB: %v", err)
	}
	t.Cleanup(func() {
		_ = cliente.DB().Drop(context.Background())
		_ = cliente.Disconnect(context.Background())
	})
	if err := migrations.Run(ctx, cliente.DB(), true, seed.AdminInicial{Correo: correoRaiz, Password: claveRaiz}); err != nil {
		t.Fatalf("migraciones: %v", err)
	}
	// Segunda ejecución: las migraciones deben ser idempotentes en cada arranque.
	if err := migrations.Run(ctx, cliente.DB(), true, seed.AdminInicial{Correo: correoRaiz, Password: claveRaiz}); err != nil {
		t.Fatalf("migraciones (repetidas): %v", err)
	}
	a, err := app.Construir(cfg, applog.New(applog.LevelError, io.Discard), cliente, contratoOpenAPI)
	if err != nil {
		t.Fatalf("construir app: %v", err)
	}
	return &entorno{t: t, app: a, cliente: cliente, secretosTOTP: map[string]string{}}
}

// llamar ejecuta una petición HTTP contra el router y decodifica la respuesta JSON.
func (e *entorno) llamar(metodo, ruta string, cuerpo interface{}, token string) (int, interface{}) {
	e.t.Helper()
	var lector io.Reader
	if cuerpo != nil {
		b, err := json.Marshal(cuerpo)
		if err != nil {
			e.t.Fatalf("serializar cuerpo: %v", err)
		}
		lector = bytes.NewReader(b)
	}
	req := httptest.NewRequest(metodo, "/api/v1"+ruta, lector)
	req.Header.Set("Content-Type", "application/json")
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}
	rec := httptest.NewRecorder()
	e.app.Router.ServeHTTP(rec, req)
	var datos interface{}
	if rec.Body.Len() > 0 {
		_ = json.Unmarshal(rec.Body.Bytes(), &datos)
	}
	return rec.Code, datos
}

// enviarTexto envía un cuerpo sin serializar (p. ej. un CSV) y exige una respuesta sin 5xx.
func (e *entorno) enviarTexto(metodo, ruta, tipo, cuerpo, token string) (int, interface{}) {
	e.t.Helper()
	req := httptest.NewRequest(metodo, "/api/v1"+ruta, strings.NewReader(cuerpo))
	req.Header.Set("Content-Type", tipo)
	req.Header.Set("Authorization", "Bearer "+token)
	rec := httptest.NewRecorder()
	e.app.Router.ServeHTTP(rec, req)
	var datos interface{}
	_ = json.Unmarshal(rec.Body.Bytes(), &datos)
	if rec.Code >= http.StatusInternalServerError {
		e.t.Fatalf("%s %s: error interno %d: %s", metodo, ruta, rec.Code, rec.Body.String())
	}
	return rec.Code, datos
}

// exigir falla la prueba si el estado no es el esperado.
func (e *entorno) exigir(metodo, ruta string, cuerpo interface{}, token string, esperado int) map[string]interface{} {
	e.t.Helper()
	estado, datos := e.llamar(metodo, ruta, cuerpo, token)
	if estado != esperado {
		e.t.Fatalf("%s %s: estado %d, esperado %d: %v", metodo, ruta, estado, esperado, datos)
	}
	m, _ := datos.(map[string]interface{})
	return m
}

// sinErrorInterno verifica que el API responda sin 5xx (la ruta puede rechazar la petición).
func (e *entorno) sinErrorInterno(metodo, ruta string, cuerpo interface{}, token string) (int, interface{}) {
	e.t.Helper()
	estado, datos := e.llamar(metodo, ruta, cuerpo, token)
	if estado >= http.StatusInternalServerError {
		e.t.Fatalf("%s %s: error interno %d: %v", metodo, ruta, estado, datos)
	}
	return estado, datos
}

// iniciarSesion devuelve los tokens del usuario. Los roles administrativos completan el
// segundo factor obligatorio (US-AUT-05): lo enrolan la primera vez y luego presentan el código.
func (e *entorno) iniciarSesion(correo, clave, dispositivo string) map[string]interface{} {
	e.t.Helper()
	res := e.exigir(http.MethodPost, "/auth/login", map[string]interface{}{
		"correo": correo, "password": clave, "dispositivoId": dispositivo,
	}, "", http.StatusOK)
	desafio := texto(res["desafioToken"])
	if desafio == "" {
		return res
	}
	ruta := "/auth/totp/verificar"
	if res["requiereConfigurarTOTP"] == true {
		enrol := e.exigir(http.MethodPost, "/auth/totp/enrolar", map[string]interface{}{"desafioToken": desafio}, "", http.StatusOK)
		e.secretosTOTP[correo] = texto(enrol["secretKey"])
		ruta = "/auth/totp/enrolar/confirmar"
	}
	return e.exigir(http.MethodPost, ruta, map[string]interface{}{
		"desafioToken": desafio, "codigo": e.codigoTOTP(correo), "dispositivoId": dispositivo,
	}, "", http.StatusOK)
}

// codigoTOTP genera el código vigente del secreto enrolado para el correo.
func (e *entorno) codigoTOTP(correo string) string {
	e.t.Helper()
	codigo, err := crypto.GenerateTOTPCode(e.secretosTOTP[correo], time.Now())
	if err != nil {
		e.t.Fatalf("generar código TOTP: %v", err)
	}
	return codigo
}

func (e *entorno) token(correo, clave string) string {
	e.t.Helper()
	return texto(e.iniciarSesion(correo, clave, "")["accessToken"])
}

// elementos extrae la lista de una respuesta que puede ser un arreglo o {items|data: [...]}.
func elementos(datos interface{}) []map[string]interface{} {
	var lista []interface{}
	switch v := datos.(type) {
	case []interface{}:
		lista = v
	case map[string]interface{}:
		for _, clave := range []string{"items", "data", "sesiones", "usuarios", "roles"} {
			if l, ok := v[clave].([]interface{}); ok {
				lista = l
				break
			}
		}
	}
	var res []map[string]interface{}
	for _, x := range lista {
		if m, ok := x.(map[string]interface{}); ok {
			res = append(res, m)
		}
	}
	return res
}

func texto(v interface{}) string {
	s, _ := v.(string)
	return s
}
