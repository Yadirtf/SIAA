// Package mailer provee implementaciones del contrato de envío de correo.
package mailer

import (
	"context"

	applog "github.com/siaa/backend/internal/platform/log"
)

// Mailer es el contrato de envío de correo.
// Las implementaciones concretas (SMTP, SendGrid, etc.) lo satisfacen.
type Mailer interface {
	SendRecovery(ctx context.Context, to, token string) error
}

// NoopMailer es un mailer de no-operación para entornos de desarrollo.
// Solo registra el intento en el log. Se reemplaza por la implementación
// SMTP real en producción inyectando la dependencia en main.go.
type NoopMailer struct {
	log *applog.Logger
}

// NewNoopMailer crea un mailer de desarrollo que solo loguea.
func NewNoopMailer(log *applog.Logger) *NoopMailer {
	return &NoopMailer{log: log}
}

// SendRecovery simula el envío de un correo de recuperación.
func (m *NoopMailer) SendRecovery(_ context.Context, to, token string) error {
	preview := token
	if len(token) > 8 {
		preview = token[:8] + "..."
	}
	m.log.Info("NOOP: correo de recuperación",
		applog.Extra(map[string]string{"to": to, "token_preview": preview}),
	)
	return nil
}
