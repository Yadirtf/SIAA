// Package fcm envía avisos con Firebase Cloud Messaging HTTP v1 (RF-NOT-001). FCM entrega en
// Android y, con la clave APNs cargada en Firebase, también en iOS.
package fcm

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/siaa/backend/internal/domain/notificacion"
	"github.com/siaa/backend/internal/platform/googleauth"
)

const (
	endpointFCM = "https://fcm.googleapis.com/v1/projects/"
	alcanceFCM  = "https://www.googleapis.com/auth/firebase.messaging"
)

// ErrNoConfigurado indica que faltan el proyecto o las credenciales de Firebase.
var ErrNoConfigurado = errors.New("fcm: falta FCM_PROJECT_ID o FCM_CREDENTIALS")

// Enviador publica mensajes en un proyecto de Firebase.
type Enviador struct {
	proyecto string
	cliente  *http.Client
	endpoint string
}

// Nuevo crea el enviador con el JSON de una cuenta de servicio con rol de envío de FCM.
func Nuevo(ctx context.Context, proyecto, rutaCredenciales string) (*Enviador, error) {
	if proyecto == "" || rutaCredenciales == "" {
		return nil, ErrNoConfigurado
	}
	contenido, err := os.ReadFile(rutaCredenciales)
	if err != nil {
		return nil, fmt.Errorf("leer credenciales de FCM: %w", err)
	}
	cliente, err := googleauth.Cliente(context.WithoutCancel(ctx), contenido, alcanceFCM, &http.Client{Timeout: 10 * time.Second})
	if err != nil {
		return nil, fmt.Errorf("credenciales de FCM inválidas: %w", err)
	}
	return NuevoConCliente(proyecto, cliente, endpointFCM), nil
}

// NuevoConCliente permite inyectar cliente y endpoint (pruebas).
func NuevoConCliente(proyecto string, cliente *http.Client, endpoint string) *Enviador {
	return &Enviador{proyecto: proyecto, cliente: cliente, endpoint: endpoint}
}

// Enviar entrega el aviso al token. Un token caducado devuelve notificacion.ErrTokenInvalido.
func (e *Enviador) Enviar(ctx context.Context, token string, n *notificacion.Notificacion) error {
	datos := map[string]string{"tipo": string(n.Tipo), "notificacionId": n.ID}
	for k, v := range n.Datos {
		datos[k] = v
	}
	cuerpo, _ := json.Marshal(map[string]interface{}{"message": map[string]interface{}{
		"token":        token,
		"notification": map[string]string{"title": n.Titulo, "body": n.Cuerpo},
		"data":         datos,
		"android":      map[string]string{"priority": "HIGH"},
		"apns":         map[string]interface{}{"payload": map[string]interface{}{"aps": map[string]string{"sound": "default"}}},
	}})
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, e.endpoint+e.proyecto+"/messages:send", bytes.NewReader(cuerpo))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")
	resp, err := e.cliente.Do(req)
	if err != nil {
		return fmt.Errorf("fcm: %w", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode == http.StatusOK {
		return nil
	}
	detalle, _ := io.ReadAll(io.LimitReader(resp.Body, 4096))
	if tokenInvalido(resp.StatusCode, string(detalle)) {
		return notificacion.ErrTokenInvalido
	}
	return fmt.Errorf("fcm: HTTP %d: %s", resp.StatusCode, strings.TrimSpace(string(detalle)))
}

// tokenInvalido reconoce UNREGISTERED (app desinstalada o token rotado) e INVALID_ARGUMENT
// (token mal formado); el mensaje en sí es siempre el mismo y válido.
func tokenInvalido(estado int, detalle string) bool {
	return estado == http.StatusNotFound || strings.Contains(detalle, "UNREGISTERED") ||
		(estado == http.StatusBadRequest && strings.Contains(detalle, "INVALID_ARGUMENT"))
}
