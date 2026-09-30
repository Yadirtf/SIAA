package fcm

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/siaa/backend/internal/domain/notificacion"
)

func TestEnviar(t *testing.T) {
	var recibido map[string]map[string]interface{}
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/proyecto-siaa/messages:send" {
			http.NotFound(w, r)
			return
		}
		_ = json.NewDecoder(r.Body).Decode(&recibido)
		switch recibido["message"]["token"] {
		case "caducado":
			w.WriteHeader(http.StatusNotFound)
			_, _ = w.Write([]byte(`{"error":{"status":"NOT_FOUND","details":[{"errorCode":"UNREGISTERED"}]}}`))
		case "caido":
			w.WriteHeader(http.StatusServiceUnavailable)
		default:
			_, _ = w.Write([]byte(`{"name":"projects/proyecto-siaa/messages/1"}`))
		}
	}))
	defer srv.Close()

	e := NuevoConCliente("proyecto-siaa", srv.Client(), srv.URL+"/")
	n := &notificacion.Notificacion{ID: "n1", Tipo: notificacion.TipoCierreVentana, Titulo: "T", Cuerpo: "C",
		Datos: map[string]string{"ruta": "/marcaje", "sesionId": "s1"}}
	if err := e.Enviar(context.Background(), "tok", n); err != nil {
		t.Fatalf("envío válido: %v", err)
	}
	datos := recibido["message"]["data"].(map[string]interface{})
	if datos["ruta"] != "/marcaje" || datos["sesionId"] != "s1" || datos["tipo"] != "CIERRE_VENTANA" || datos["notificacionId"] != "n1" {
		t.Fatalf("la app necesita ruta, tipo e ids para navegar: %v", datos)
	}
	if err := e.Enviar(context.Background(), "caducado", n); !errors.Is(err, notificacion.ErrTokenInvalido) {
		t.Fatalf("un token caducado debe purgarse: %v", err)
	}
	if err := e.Enviar(context.Background(), "caido", n); err == nil || errors.Is(err, notificacion.ErrTokenInvalido) {
		t.Fatalf("un error del servicio debe reintentarse, no purgar el token: %v", err)
	}
	if _, err := Nuevo(context.Background(), "", ""); !errors.Is(err, ErrNoConfigurado) {
		t.Fatalf("sin configuración: %v", err)
	}
	if _, err := Nuevo(context.Background(), "p", "/no/existe.json"); err == nil {
		t.Fatal("credenciales inexistentes")
	}
}
