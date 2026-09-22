package unit_test

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/siaa/backend/internal/platform/config"
	applog "github.com/siaa/backend/internal/platform/log"
	apphttp "github.com/siaa/backend/internal/transport/http"
	"github.com/siaa/backend/internal/transport/http/handler"
)

func TestCORS_Preflight_LocalhostDevelopment(t *testing.T) {
	cfg := &config.Config{
		Env:                "development",
		CORSAllowedOrigins: []string{"*"},
		JWTSecret:          "test-secret-min-32chars-for-testing-only!",
	}
	logger := applog.New(applog.LevelDebug, nil)
	healthH := handler.NewHealthHandler(nil, "0.1.0-test", "test")

	router, err := apphttp.NewRouter(cfg, logger, healthH, nil, nil, nil, nil, nil, nil)
	if err != nil {
		t.Fatalf("error al crear router: %v", err)
	}

	req := httptest.NewRequest(http.MethodOptions, "/api/v1/auth/login", nil)
	req.Header.Set("Origin", "http://localhost:54321")
	req.Header.Set("Access-Control-Request-Method", "POST")
	req.Header.Set("Access-Control-Request-Headers", "content-type,accept,x-correlation-id")

	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusNoContent && rec.Code != http.StatusOK {
		t.Fatalf("status esperado 204 o 200, obtenido %d", rec.Code)
	}

	allowOrigin := rec.Header().Get("Access-Control-Allow-Origin")
	if allowOrigin != "*" && allowOrigin != "http://localhost:54321" {
		t.Fatalf("esperado Access-Control-Allow-Origin permisivo (* o http://localhost:54321), obtenido %q", allowOrigin)
	}

	allowHeaders := strings.ToLower(rec.Header().Get("Access-Control-Allow-Headers"))
	if !strings.Contains(allowHeaders, "accept") {
		t.Fatalf("esperado que Access-Control-Allow-Headers contenga 'accept', obtenido %q", allowHeaders)
	}
	if !strings.Contains(allowHeaders, "content-type") {
		t.Fatalf("esperado que Access-Control-Allow-Headers contenga 'content-type', obtenido %q", allowHeaders)
	}
	if !strings.Contains(allowHeaders, "x-correlation-id") {
		t.Fatalf("esperado que Access-Control-Allow-Headers contenga 'x-correlation-id', obtenido %q", allowHeaders)
	}
}

func TestCORS_Preflight_ProductionRejection(t *testing.T) {
	cfg := &config.Config{
		Env:                "production",
		CORSAllowedOrigins: []string{"https://*.siaa.edu.co"},
		JWTSecret:          "test-secret-min-32chars-for-testing-only!",
	}
	logger := applog.New(applog.LevelDebug, nil)
	healthH := handler.NewHealthHandler(nil, "0.1.0-test", "test")

	router, err := apphttp.NewRouter(cfg, logger, healthH, nil, nil, nil, nil, nil, nil)
	if err != nil {
		t.Fatalf("error al crear router: %v", err)
	}

	// Origen no autorizado en producción
	req := httptest.NewRequest(http.MethodOptions, "/api/v1/auth/login", nil)
	req.Header.Set("Origin", "http://evil.com")
	req.Header.Set("Access-Control-Request-Method", "POST")

	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)

	allowOrigin := rec.Header().Get("Access-Control-Allow-Origin")
	if allowOrigin != "" {
		t.Fatalf("en producción para origen no autorizado no debe incluirse Access-Control-Allow-Origin, obtenido %q", allowOrigin)
	}

	// Origen autorizado en producción
	reqAuth := httptest.NewRequest(http.MethodOptions, "/api/v1/auth/login", nil)
	reqAuth.Header.Set("Origin", "https://app.siaa.edu.co")
	reqAuth.Header.Set("Access-Control-Request-Method", "POST")

	recAuth := httptest.NewRecorder()
	router.ServeHTTP(recAuth, reqAuth)

	allowOriginAuth := recAuth.Header().Get("Access-Control-Allow-Origin")
	if allowOriginAuth != "https://app.siaa.edu.co" {
		t.Fatalf("en producción para subdominio siaa.edu.co se esperaba https://app.siaa.edu.co, obtenido %q", allowOriginAuth)
	}
}
