// US-PLT-01 AC-04: la línea de log de cada petición registra el estado HTTP real, también
// cuando el handler devuelve un error que resuelve después el ErrorHandler.
package unit_test

import (
	"bytes"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/domain/shared"
	applog "github.com/siaa/backend/internal/platform/log"
	mw "github.com/siaa/backend/internal/transport/http/middleware"
)

func TestRequestLogger_RegistraEstadoReal(t *testing.T) {
	casos := []struct {
		nombre string
		err    error
		estado int
	}{
		{"ok", nil, http.StatusOK},
		{"token expirado", shared.NewAuthError(shared.ErrTokenExpirado, "x"), http.StatusUnauthorized},
		{"sin permiso", shared.NewPermissionError(), http.StatusForbidden},
		{"cuenta bloqueada", shared.NewAuthError(shared.ErrCuentaBloqueada, "x"), 423},
		{"límite de tasa", &shared.DomainError{Code: shared.ErrLimiteTasa, Message: "x"}, http.StatusTooManyRequests},
		{"error de echo", echo.NewHTTPError(http.StatusNotFound, "x"), http.StatusNotFound},
		{"error interno", errors.New("fallo"), http.StatusInternalServerError},
	}
	for _, c := range casos {
		t.Run(c.nombre, func(t *testing.T) {
			var salida bytes.Buffer
			log := applog.New(applog.LevelInfo, &salida)
			e := echo.New()
			e.HTTPErrorHandler = mw.ErrorHandler(applog.New(applog.LevelError, &bytes.Buffer{}))
			e.Use(mw.CorrelationID(), mw.RequestLogger(log))
			e.GET("/x", func(ctx echo.Context) error {
				if c.err != nil {
					return c.err
				}
				return ctx.NoContent(http.StatusOK)
			})
			rec := httptest.NewRecorder()
			e.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/x", nil))
			if rec.Code != c.estado {
				t.Fatalf("respuesta %d, esperada %d", rec.Code, c.estado)
			}
			var linea map[string]interface{}
			for _, l := range strings.Split(strings.TrimSpace(salida.String()), "\n") {
				if strings.Contains(l, `"request"`) {
					_ = json.Unmarshal([]byte(l), &linea)
				}
			}
			if linea == nil {
				t.Fatalf("no se emitió la línea de log: %q", salida.String())
			}
			if got, _ := linea["status"].(float64); int(got) != c.estado {
				t.Fatalf("log con status %v, esperado %d: %v", linea["status"], c.estado, linea)
			}
		})
	}
}
