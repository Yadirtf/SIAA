package integridad

import (
	"context"
	"crypto/rand"
	"crypto/rsa"
	"crypto/x509"
	"encoding/json"
	"encoding/pem"
	"errors"
	"net/http"
	"net/http/httptest"
	"strconv"
	"testing"
	"time"
)

func veredictoValido(ahora time.Time) payload {
	var p payload
	p.RequestDetails.RequestPackageName = "co.edu.siaa"
	p.RequestDetails.RequestHash = "hash-1"
	p.RequestDetails.TimestampMillis = strconv.FormatInt(ahora.Add(-time.Minute).UnixMilli(), 10)
	p.AppIntegrity.AppRecognitionVerdict = "PLAY_RECOGNIZED"
	p.DeviceIntegrity.DeviceRecognitionVerdict = []string{"MEETS_BASIC_INTEGRITY", "MEETS_DEVICE_INTEGRITY"}
	return p
}

func TestEvaluarVeredicto(t *testing.T) {
	ahora := time.Date(2026, 9, 30, 12, 0, 0, 0, time.UTC)
	casos := []struct {
		nombre   string
		mutar    func(*payload)
		esperado error
	}{
		{"válido", func(*payload) {}, nil},
		{"otro paquete", func(p *payload) { p.RequestDetails.RequestPackageName = "otra.app" }, ErrPaqueteDistinto},
		{"otra solicitud", func(p *payload) { p.RequestDetails.RequestHash = "hash-2" }, ErrHashDistinto},
		{"timestamp ilegible", func(p *payload) { p.RequestDetails.TimestampMillis = "x" }, ErrRespuestaInvalida},
		{"vencido", func(p *payload) {
			p.RequestDetails.TimestampMillis = strconv.FormatInt(ahora.Add(-11*time.Minute).UnixMilli(), 10)
		}, ErrTokenVencido},
		{"del futuro", func(p *payload) {
			p.RequestDetails.TimestampMillis = strconv.FormatInt(ahora.Add(5*time.Minute).UnixMilli(), 10)
		}, ErrTokenVencido},
		{"app no reconocida", func(p *payload) { p.AppIntegrity.AppRecognitionVerdict = "UNRECOGNIZED_VERSION" }, ErrAppNoReconocida},
		{"solo integridad básica", func(p *payload) {
			p.DeviceIntegrity.DeviceRecognitionVerdict = []string{"MEETS_BASIC_INTEGRITY"}
		}, ErrDispositivoDudoso},
	}
	for _, c := range casos {
		p := veredictoValido(ahora)
		c.mutar(&p)
		if err := evaluarVeredicto(p, "co.edu.siaa", "hash-1", ahora, VigenciaPorDefecto); !errors.Is(err, c.esperado) {
			t.Errorf("%s: esperado %v, obtuvo %v", c.nombre, c.esperado, err)
		}
	}
}

func TestPlayIntegrity_VerificarContraLaAPI(t *testing.T) {
	ahora := time.Now()
	var cuerpoRecibido map[string]string
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/co.edu.siaa:decodeIntegrityToken" {
			http.NotFound(w, r)
			return
		}
		_ = json.NewDecoder(r.Body).Decode(&cuerpoRecibido)
		if cuerpoRecibido["integrity_token"] == "roto" {
			w.WriteHeader(http.StatusBadRequest)
			return
		}
		_ = json.NewEncoder(w).Encode(map[string]interface{}{"tokenPayloadExternal": veredictoValido(ahora)})
	}))
	defer srv.Close()

	v := NuevoPlayIntegrityConCliente("co.edu.siaa", srv.Client(), srv.URL+"/")
	if err := v.Verificar(context.Background(), "tok", "hash-1"); err != nil {
		t.Fatalf("un veredicto válido debe aceptarse: %v", err)
	}
	if cuerpoRecibido["integrity_token"] != "tok" {
		t.Fatalf("el token debe enviarse a Google: %v", cuerpoRecibido)
	}
	if err := v.Verificar(context.Background(), "tok", "hash-otro"); !errors.Is(err, ErrHashDistinto) {
		t.Fatalf("un token de otra solicitud debe rechazarse: %v", err)
	}
	if err := v.Verificar(context.Background(), "roto", "hash-1"); !errors.Is(err, ErrRespuestaInvalida) {
		t.Fatalf("un error de la API debe rechazarse: %v", err)
	}
	if err := v.Verificar(context.Background(), "", "hash-1"); !errors.Is(err, ErrTokenVacio) {
		t.Fatalf("un token vacío debe rechazarse: %v", err)
	}
}

func TestClienteOAuth_FirmaLasPeticiones(t *testing.T) {
	llave, _ := rsa.GenerateKey(rand.Reader, 2048)
	pemLlave := pem.EncodeToMemory(&pem.Block{Type: "RSA PRIVATE KEY", Bytes: x509.MarshalPKCS1PrivateKey(llave)})
	var autorizacion string
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/token" {
			w.Header().Set("Content-Type", "application/json")
			_, _ = w.Write([]byte(`{"access_token":"acceso-1","token_type":"Bearer","expires_in":3600}`))
			return
		}
		autorizacion = r.Header.Get("Authorization")
	}))
	defer srv.Close()

	contenido, _ := json.Marshal(cuentaServicio{ClientEmail: "siaa@proyecto.iam", PrivateKey: string(pemLlave), TokenURI: srv.URL + "/token"})
	cliente, err := clienteOAuth(context.Background(), contenido, srv.Client())
	if err != nil {
		t.Fatal(err)
	}
	resp, err := cliente.Get(srv.URL + "/api")
	if err != nil {
		t.Fatal(err)
	}
	resp.Body.Close()
	if autorizacion != "Bearer acceso-1" {
		t.Fatalf("la petición debe llevar el token de acceso: %q", autorizacion)
	}
	if _, err := clienteOAuth(context.Background(), []byte(`{}`), srv.Client()); err == nil {
		t.Fatal("una cuenta de servicio incompleta debe rechazarse")
	}
	if _, err := NuevoPlayIntegrity(context.Background(), "", ""); !errors.Is(err, ErrNoConfigurado) {
		t.Fatalf("sin configuración debe informarlo: %v", err)
	}
}
