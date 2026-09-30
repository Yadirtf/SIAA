// Package academico — aviso a los docentes cuando cambia una de sus sesiones (RF-NOT-002).
package academico

import (
	"context"

	"github.com/siaa/backend/internal/domain/academico"
)

// NotificadorHorario encola el aviso de cambio de horario para los docentes afectados.
type NotificadorHorario interface {
	CambioSesion(ctx context.Context, s *academico.Sesion, docentes []string, titulo, detalle string)
}

// WithNotificador habilita los avisos de cancelación, cambio de aula y reemplazo.
func (s *Service) WithNotificador(n NotificadorHorario) *Service {
	s.notificador = n
	return s
}

func (s *Service) avisarCambio(ctx context.Context, sesion *academico.Sesion, docentes []string, titulo, detalle string) {
	if s.notificador != nil && len(docentes) > 0 {
		s.notificador.CambioSesion(ctx, sesion, docentes, titulo, detalle)
	}
}

// retirados devuelve los docentes que estaban antes y ya no están.
func retirados(antes, despues []string) []string {
	siguen := map[string]bool{}
	for _, d := range despues {
		siguen[d] = true
	}
	var fuera []string
	for _, d := range antes {
		if !siguen[d] {
			fuera = append(fuera, d)
		}
	}
	return fuera
}
