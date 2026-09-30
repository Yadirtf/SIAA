// Package googleauth firma peticiones a las APIs de Google con una cuenta de servicio (flujo
// JWT bearer), sin depender del SDK de Google Cloud. Lo usan Play Integrity y FCM.
package googleauth

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"

	"golang.org/x/oauth2"
	"golang.org/x/oauth2/jwt"
)

// CuentaServicio son los campos del JSON de una cuenta de servicio de Google Cloud.
type CuentaServicio struct {
	ClientEmail  string `json:"client_email"`
	PrivateKey   string `json:"private_key"`
	PrivateKeyID string `json:"private_key_id"`
	TokenURI     string `json:"token_uri"`
}

// Cliente devuelve un cliente HTTP que firma cada petición con un token de acceso de la
// cuenta de servicio (flujo JWT bearer), renovándolo cuando vence.
func Cliente(ctx context.Context, contenido []byte, alcance string, base *http.Client) (*http.Client, error) {
	var cs CuentaServicio
	if err := json.Unmarshal(contenido, &cs); err != nil {
		return nil, err
	}
	if cs.ClientEmail == "" || cs.PrivateKey == "" {
		return nil, errors.New("faltan client_email o private_key")
	}
	if cs.TokenURI == "" {
		cs.TokenURI = "https://oauth2.googleapis.com/token"
	}
	conf := &jwt.Config{
		Email:        cs.ClientEmail,
		PrivateKey:   []byte(cs.PrivateKey),
		PrivateKeyID: cs.PrivateKeyID,
		TokenURL:     cs.TokenURI,
		Scopes:       []string{alcance},
	}
	ctx = context.WithValue(ctx, oauth2.HTTPClient, base)
	cliente := &http.Client{
		Timeout:   base.Timeout,
		Transport: &oauth2.Transport{Source: oauth2.ReuseTokenSource(nil, conf.TokenSource(ctx)), Base: transporteDe(base)},
	}
	return cliente, nil
}

func transporteDe(c *http.Client) http.RoundTripper {
	if c != nil && c.Transport != nil {
		return c.Transport
	}
	return http.DefaultTransport
}
