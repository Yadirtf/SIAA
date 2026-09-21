// Pruebas unitarias del endpoint OpenAPI 3.1.
// US-PLT-01, AC-06, T-PLT-01.9.
package unit_test

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/transport/http/handler"
)

func TestOpenAPI_SpecReturnsValidJSON(t *testing.T) {
	e := echo.New()
	openapiH := handler.NewOpenAPIHandler("../../contracts/openapi.json")

	req := httptest.NewRequest(http.MethodGet, "/api/v1/openapi.json", nil)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)

	err := openapiH.Spec(c)
	if err != nil {
		t.Fatalf("OpenAPI Spec retornó error: %v", err)
	}

	if rec.Code != http.StatusOK {
		t.Fatalf("status esperado 200, obtuvo %d", rec.Code)
	}

	var spec map[string]interface{}
	if err := json.Unmarshal(rec.Body.Bytes(), &spec); err != nil {
		t.Fatalf("el cuerpo no es JSON válido: %v", err)
	}

	version, ok := spec["openapi"].(string)
	if !ok || version != "3.1.0" {
		t.Errorf("versión de openapi esperada '3.1.0', obtuvo '%v'", spec["openapi"])
	}

	if _, ok := spec["paths"]; !ok {
		t.Error("se esperaba campo 'paths' en openapi spec")
	}
}
