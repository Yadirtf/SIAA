// Prueba de cobertura del contrato OpenAPI frente al enrutador real.
// US-PLT-01 AC-06, RNF-MAN-002: toda ruta registrada en el router debe estar documentada
// en contracts/openapi.json; si alguien agrega una ruta sin documentarla, esta prueba falla.
package unit_test

import (
	"encoding/json"
	"net/http"
	"os"
	"regexp"
	"sort"
	"strings"
	"testing"

	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/platform/config"
	applog "github.com/siaa/backend/internal/platform/log"
	apphttp "github.com/siaa/backend/internal/transport/http"
	"github.com/siaa/backend/internal/transport/http/handler"
)

// parametroEcho convierte ":id" (Echo) en "{id}" (OpenAPI).
var parametroEcho = regexp.MustCompile(`:([A-Za-z0-9_]+)`)

// routerCompleto arma el router con todos los grupos de rutas habilitados. Los handlers
// no se ejecutan: solo interesa el inventario de rutas que registra NewRouter.
func routerCompleto(t *testing.T) []string {
	t.Helper()
	cfg := &config.Config{Env: "development", JWTSecret: "test-secret-min-32chars-for-testing-only!"}
	router, err := apphttp.NewRouter(cfg, applog.New(applog.LevelError, nil),
		handler.NewHealthHandler(nil, "test", "test"), &handler.AuthHandler{}, &handler.OpenAPIHandler{},
		&handler.RolesHandler{}, &handler.GeoHandler{}, &handler.AcademicoHandler{}, &handler.ParametroHandler{},
		&handler.MarcajeHandler{}, &handler.MarcajeAdminHandler{}, &handler.MarcajeSyncHandler{}, &handler.UsuariosHandler{},
		&apphttp.HandlersSeguimiento{
			Justificaciones: &handler.JustificacionesHandler{},
			Reportes:        &handler.ReportesHandler{},
			Auditoria:       &handler.AuditoriaHandler{},
			Investigaciones: &handler.InvestigacionesHandler{},
		},
		&apphttp.HandlersPersonales{
			Privacidad:     &handler.PrivacidadHandler{},
			Notificaciones: &handler.NotificacionesHandler{},
			Perfil:         &handler.PerfilHandler{},
		}, nil, nil, nil)
	if err != nil {
		t.Fatalf("NewRouter: %v", err)
	}
	var rutas []string
	for _, r := range router.Routes() {
		if !strings.HasPrefix(r.Path, "/api/v1/") || r.Method == http.MethodOptions || r.Method == echo.RouteNotFound || strings.HasSuffix(r.Path, "*") {
			continue
		}
		ruta := parametroEcho.ReplaceAllString(strings.TrimPrefix(r.Path, "/api/v1"), "{$1}")
		rutas = append(rutas, strings.ToLower(r.Method)+" "+ruta)
	}
	sort.Strings(rutas)
	return rutas
}

func TestOpenAPI_DocumentaTodasLasRutasDelRouter(t *testing.T) {
	data, err := os.ReadFile("../../contracts/openapi.json")
	if err != nil {
		t.Fatalf("leyendo openapi.json: %v", err)
	}
	var spec struct {
		Paths map[string]map[string]json.RawMessage `json:"paths"`
	}
	if err := json.Unmarshal(data, &spec); err != nil {
		t.Fatalf("openapi.json inválido: %v", err)
	}

	var faltantes []string
	for _, ruta := range routerCompleto(t) {
		partes := strings.SplitN(ruta, " ", 2)
		if _, ok := spec.Paths[partes[1]][partes[0]]; !ok {
			faltantes = append(faltantes, ruta)
		}
	}
	if len(faltantes) > 0 {
		t.Fatalf("rutas registradas sin documentar en contracts/openapi.yaml (%d); agréguelas y regenere con go run ./cmd/openapi-gen:\n  %s",
			len(faltantes), strings.Join(faltantes, "\n  "))
	}
}
