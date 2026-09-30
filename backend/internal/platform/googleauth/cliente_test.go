package googleauth

import (
	"context"
	"crypto/rand"
	"crypto/rsa"
	"crypto/x509"
	"encoding/json"
	"encoding/pem"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestCliente_FirmaLasPeticiones(t *testing.T) {
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

	contenido, _ := json.Marshal(CuentaServicio{ClientEmail: "siaa@proyecto.iam", PrivateKey: string(pemLlave), TokenURI: srv.URL + "/token"})
	cliente, err := Cliente(context.Background(), contenido, "https://www.googleapis.com/auth/test", srv.Client())
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
	if _, err := Cliente(context.Background(), []byte(`{}`), "x", srv.Client()); err == nil {
		t.Fatal("una cuenta de servicio incompleta debe rechazarse")
	}
}
