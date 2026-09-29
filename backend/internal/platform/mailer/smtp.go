package mailer

import (
	"context"
	"fmt"
	"net"
	"net/smtp"
	"net/url"
	"strconv"
	"strings"
	"time"
)

// SMTPConfig agrupa los datos de conexión del servidor de correo.
type SMTPConfig struct {
	Host     string
	Port     int
	User     string
	Pass     string
	From     string
	LinkBase string // URL de la pantalla de recuperación; el token se agrega como ?token=
	Minutos  int    // vigencia del enlace, solo informativa en el cuerpo del correo
}

// SMTPMailer envía los correos de recuperación de contraseña (US-AUT-04) por SMTP.
// En desarrollo apunta a MailHog (localhost:1025, sin autenticación).
type SMTPMailer struct {
	cfg SMTPConfig
}

// NewSMTPMailer crea el mailer SMTP.
func NewSMTPMailer(cfg SMTPConfig) *SMTPMailer {
	return &SMTPMailer{cfg: cfg}
}

// SendRecovery envía el enlace de un solo uso al correo del usuario.
func (m *SMTPMailer) SendRecovery(ctx context.Context, to, token string) error {
	enlace := token
	if m.cfg.LinkBase != "" {
		sep := "?"
		if strings.Contains(m.cfg.LinkBase, "?") {
			sep = "&"
		}
		enlace = m.cfg.LinkBase + sep + "token=" + url.QueryEscape(token)
	}
	cuerpo := fmt.Sprintf(
		"Hola,\r\n\r\nRecibimos una solicitud para restablecer tu contraseña de SIAA.\r\n\r\n"+
			"Abre este enlace para crear una nueva contraseña (vence en %d minutos y solo puede usarse una vez):\r\n%s\r\n\r\n"+
			"Si no solicitaste el cambio, ignora este mensaje; tu contraseña actual sigue siendo válida.\r\n",
		m.cfg.Minutos, enlace)
	msg := strings.Join([]string{
		"From: " + m.cfg.From,
		"To: " + to,
		"Subject: SIAA - Recuperación de contraseña",
		"MIME-Version: 1.0",
		"Content-Type: text/plain; charset=UTF-8",
		"Date: " + time.Now().UTC().Format(time.RFC1123Z),
		"",
		cuerpo,
	}, "\r\n")

	addr := net.JoinHostPort(m.cfg.Host, strconv.Itoa(m.cfg.Port))
	var auth smtp.Auth
	if m.cfg.User != "" {
		auth = smtp.PlainAuth("", m.cfg.User, m.cfg.Pass, m.cfg.Host)
	}

	done := make(chan error, 1)
	go func() { done <- smtp.SendMail(addr, auth, m.cfg.From, []string{to}, []byte(msg)) }()
	select {
	case err := <-done:
		if err != nil {
			return fmt.Errorf("enviar correo de recuperación: %w", err)
		}
		return nil
	case <-ctx.Done():
		return ctx.Err()
	}
}
