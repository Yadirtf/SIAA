// Pruebas unitarias del limitador de tasa (rate limiting).
// US-AUT-02, AC-03, AC-04, T-AUT-02.5.
package unit_test

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/transport/http/middleware"
	"github.com/siaa/backend/internal/usecase/auth"
)

func TestRateLimiterByIP_Limite20PorMinuto(t *testing.T) {
	e := echo.New()
	handler := func(c echo.Context) error {
		return c.String(http.StatusOK, "ok")
	}

	limitMiddleware := middleware.RateLimiterByIP(20)
	wrapped := limitMiddleware(handler)

	// Las primeras 20 peticiones desde la misma IP deben permitirse
	for i := 1; i <= 20; i++ {
		req := httptest.NewRequest(http.MethodPost, "/auth/login", nil)
		req.Header.Set("X-Real-IP", "10.0.0.1")
		rec := httptest.NewRecorder()
		c := e.NewContext(req, rec)

		err := wrapped(c)
		if err != nil {
			t.Fatalf("petición %d falló inesperadamente: %v", i, err)
		}
		if rec.Code != http.StatusOK {
			t.Fatalf("petición %d: status esperado 200, obtuvo %d", i, rec.Code)
		}
	}

	// La petición 21 debe ser rechazada con 429 y cabecera Retry-After (AC-03)
	req := httptest.NewRequest(http.MethodPost, "/auth/login", nil)
	req.Header.Set("X-Real-IP", "10.0.0.1")
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)

	err := wrapped(c)
	if err == nil {
		t.Fatal("la petición 21 debió ser rechazada por límite de tasa")
	}

	retryAfter := rec.Header().Get("Retry-After")
	if retryAfter == "" {
		t.Error("se esperaba cabecera Retry-After en la respuesta 429")
	}

	// Otra IP debe seguir funcionando normalmente
	reqOther := httptest.NewRequest(http.MethodPost, "/auth/login", nil)
	reqOther.Header.Set("X-Real-IP", "10.0.0.2")
	recOther := httptest.NewRecorder()
	cOther := e.NewContext(reqOther, recOther)

	errOther := wrapped(cOther)
	if errOther != nil {
		t.Fatalf("otra IP no debe verse afectada por el bloqueo: %v", errOther)
	}
	if recOther.Code != http.StatusOK {
		t.Errorf("otra IP: status esperado 200, obtuvo %d", recOther.Code)
	}
}

func TestRateLimiterByUser_Limite120PorMinuto(t *testing.T) {
	e := echo.New()
	handler := func(c echo.Context) error {
		return c.String(http.StatusOK, "ok")
	}

	limitMiddleware := middleware.RateLimiterByUser(120)
	wrapped := limitMiddleware(handler)

	// Simular contexto con claims de usuario 1
	claimsUser1 := &auth.JWTClaims{UsuarioID: "user-alpha"}
	claimsUser2 := &auth.JWTClaims{UsuarioID: "user-beta"}

	// 120 peticiones de user 1 deben permitirse
	for i := 1; i <= 120; i++ {
		req := httptest.NewRequest(http.MethodGet, "/marcajes", nil)
		rec := httptest.NewRecorder()
		c := e.NewContext(req, rec)
		c.Set(middleware.CtxClaims, claimsUser1)

		err := wrapped(c)
		if err != nil {
			t.Fatalf("petición %d de user1 falló inesperadamente: %v", i, err)
		}
	}

	// Petición 121 de user 1 debe ser rechazada con 429 (AC-04)
	req := httptest.NewRequest(http.MethodGet, "/marcajes", nil)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)
	c.Set(middleware.CtxClaims, claimsUser1)

	err := wrapped(c)
	if err == nil {
		t.Fatal("petición 121 de user1 debió ser rechazada por límite de tasa")
	}
	if rec.Header().Get("Retry-After") == "" {
		t.Error("se esperaba cabecera Retry-After en respuesta 429")
	}

	// User 2 no debe verse afectado por el límite alcanzado por User 1 (AC-04)
	req2 := httptest.NewRequest(http.MethodGet, "/marcajes", nil)
	rec2 := httptest.NewRecorder()
	c2 := e.NewContext(req2, rec2)
	c2.Set(middleware.CtxClaims, claimsUser2)

	err2 := wrapped(c2)
	if err2 != nil {
		t.Fatalf("user2 no debe ser afectado por límite de user1: %v", err2)
	}
	if rec2.Code != http.StatusOK {
		t.Errorf("user2: status esperado 200, obtuvo %d", rec2.Code)
	}
}
