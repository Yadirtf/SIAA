package middleware

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/usecase/auth"
)

// ejecutarConsentimiento corre el middleware sobre un handler que registra si fue invocado.
func ejecutarConsentimiento(v VerificadorConsentimiento, conClaims bool) (bool, string, error) {
	e := echo.New()
	c := e.NewContext(httptest.NewRequest(http.MethodPost, "/marcajes", nil), httptest.NewRecorder())
	if conClaims {
		c.Set(CtxClaims, &auth.JWTClaims{UsuarioID: "u1"})
	}
	llamado := false
	var consultado string
	verificador := v
	if v != nil {
		verificador = func(ctx context.Context, id string) (bool, error) {
			consultado = id
			return v(ctx, id)
		}
	}
	err := ExigirConsentimiento(verificador)(func(echo.Context) error {
		llamado = true
		return nil
	})(c)
	return llamado, consultado, err
}

func TestExigirConsentimiento_SinVerificadorPasa(t *testing.T) {
	if llamado, _, err := ejecutarConsentimiento(nil, true); err != nil || !llamado {
		t.Fatalf("con verificador nil debe pasar: llamado=%v err=%v", llamado, err)
	}
}

func TestExigirConsentimiento_SinClaimsPasa(t *testing.T) {
	v := func(context.Context, string) (bool, error) { return false, nil }
	if llamado, consultado, err := ejecutarConsentimiento(v, false); err != nil || !llamado || consultado != "" {
		t.Fatalf("sin claims no se verifica: llamado=%v consultado=%q err=%v", llamado, consultado, err)
	}
}

func TestExigirConsentimiento_AceptadoPasa(t *testing.T) {
	v := func(context.Context, string) (bool, error) { return true, nil }
	if llamado, consultado, err := ejecutarConsentimiento(v, true); err != nil || !llamado || consultado != "u1" {
		t.Fatalf("llamado=%v consultado=%q err=%v", llamado, consultado, err)
	}
}

// US-LEG-01 AC-05: sin aceptar la política vigente no se registra ubicación.
func TestExigirConsentimiento_NoAceptadoBloquea(t *testing.T) {
	v := func(context.Context, string) (bool, error) { return false, nil }
	llamado, _, err := ejecutarConsentimiento(v, true)
	var de *shared.DomainError
	if !errors.As(err, &de) || de.Code != shared.ErrConsentimientoRequerido {
		t.Fatalf("se esperaba CONSENTIMIENTO_REQUERIDO, got %v", err)
	}
	if llamado {
		t.Fatal("el handler no debe ejecutarse")
	}
}

func TestExigirConsentimiento_ErrorDelVerificadorSePropaga(t *testing.T) {
	causa := errors.New("mongo caído")
	v := func(context.Context, string) (bool, error) { return false, causa }
	llamado, _, err := ejecutarConsentimiento(v, true)
	if !errors.Is(err, causa) || llamado {
		t.Fatalf("se esperaba propagar el error sin ejecutar el handler: llamado=%v err=%v", llamado, err)
	}
}
