package integridad

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"os"
	"time"
)

const (
	endpointPlayIntegrity = "https://playintegrity.googleapis.com/v1/"
	alcancePlayIntegrity  = "https://www.googleapis.com/auth/playintegrity"
	// VigenciaPorDefecto tolera la latencia entre pedir el token y que llegue la solicitud.
	VigenciaPorDefecto = 10 * time.Minute
)

// PlayIntegrity descifra el token con la API de Google y evalúa el veredicto.
type PlayIntegrity struct {
	paquete  string
	cliente  *http.Client
	endpoint string
	vigencia time.Duration
	ahora    func() time.Time
}

// NuevoPlayIntegrity crea el verificador con la cuenta de servicio del proyecto de Google Cloud
// vinculado a la app. rutaCredenciales es el JSON de la cuenta de servicio.
func NuevoPlayIntegrity(ctx context.Context, paquete, rutaCredenciales string) (*PlayIntegrity, error) {
	if paquete == "" || rutaCredenciales == "" {
		return nil, ErrNoConfigurado
	}
	contenido, err := os.ReadFile(rutaCredenciales)
	if err != nil {
		return nil, fmt.Errorf("leer credenciales de Play Integrity: %w", err)
	}
	cliente, err := clienteOAuth(context.WithoutCancel(ctx), contenido, &http.Client{Timeout: 10 * time.Second})
	if err != nil {
		return nil, fmt.Errorf("credenciales de Play Integrity inválidas: %w", err)
	}
	return NuevoPlayIntegrityConCliente(paquete, cliente, endpointPlayIntegrity), nil
}

// NuevoPlayIntegrityConCliente permite inyectar el cliente HTTP y el endpoint (pruebas).
func NuevoPlayIntegrityConCliente(paquete string, cliente *http.Client, endpoint string) *PlayIntegrity {
	return &PlayIntegrity{
		paquete:  paquete,
		cliente:  cliente,
		endpoint: endpoint,
		vigencia: VigenciaPorDefecto,
		ahora:    time.Now,
	}
}

// Verificar devuelve nil solo si Google descifra el token y el veredicto cumple la política.
func (p *PlayIntegrity) Verificar(ctx context.Context, token, hashEsperado string) error {
	if token == "" {
		return ErrTokenVacio
	}
	cuerpo, _ := json.Marshal(map[string]string{"integrity_token": token})
	u := p.endpoint + url.PathEscape(p.paquete) + ":decodeIntegrityToken"
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, u, bytes.NewReader(cuerpo))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")
	resp, err := p.cliente.Do(req)
	if err != nil {
		return fmt.Errorf("attestation: consultar Play Integrity: %w", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("%w: HTTP %d", ErrRespuestaInvalida, resp.StatusCode)
	}
	var r struct {
		TokenPayloadExternal payload `json:"tokenPayloadExternal"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&r); err != nil {
		return ErrRespuestaInvalida
	}
	return evaluarVeredicto(r.TokenPayloadExternal, p.paquete, hashEsperado, p.ahora(), p.vigencia)
}
