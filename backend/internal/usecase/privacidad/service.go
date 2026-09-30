// Package privacidad — aviso de privacidad y consentimiento informado (US-LEG-01, CA-011).
package privacidad

import (
	"context"
	"fmt"
	"time"

	domain "github.com/siaa/backend/internal/domain/privacidad"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/repository"
)

// Service publica la política vigente y registra las decisiones de los titulares.
type Service struct {
	politica  domain.Politica
	repo      repository.ConsentimientoRepository
	auditoria repository.AuditoriaRepository
	ahora     func() time.Time
}

// NewService crea el servicio con la política ya construida (platform/politica).
func NewService(politica domain.Politica, repo repository.ConsentimientoRepository, auditoria repository.AuditoriaRepository) *Service {
	return &Service{politica: politica, repo: repo, auditoria: auditoria, ahora: func() time.Time { return time.Now().UTC() }}
}

// SolicitudDecision es la respuesta del titular a una versión de la política.
type SolicitudDecision struct {
	UsuarioID     string
	Version       string
	Acepta        bool
	DispositivoID string
	IPOrigen      string
}

// Politica devuelve el aviso vigente (RNF-LEG-003).
func (s *Service) Politica() domain.Politica { return s.politica }

// Estado calcula si el titular debe aceptar la versión vigente.
func (s *Service) Estado(ctx context.Context, usuarioID string) (domain.Estado, error) {
	ultimo, err := s.repo.Ultimo(ctx, usuarioID)
	if err != nil {
		return domain.Estado{}, err
	}
	return domain.CalcularEstado(s.politica.Version, ultimo), nil
}

// PuedeMarcar indica si el titular aceptó la política vigente (US-LEG-01 AC-05).
func (s *Service) PuedeMarcar(ctx context.Context, usuarioID string) (bool, error) {
	e, err := s.Estado(ctx, usuarioID)
	if err != nil {
		return false, err
	}
	return e.PermiteMarcar(), nil
}

// Decidir registra la aceptación o el rechazo con fecha y versión (US-LEG-01 AC-02). Solo se
// admite decidir sobre la versión vigente: una app con el texto viejo debe recargarlo.
func (s *Service) Decidir(ctx context.Context, req SolicitudDecision) (domain.Estado, error) {
	if req.Version != s.politica.Version {
		return domain.Estado{}, &shared.DomainError{
			Code:    shared.ErrConflictoUnicidad,
			Message: fmt.Sprintf("La política vigente es la versión %s; vuelva a cargarla antes de decidir", s.politica.Version),
		}
	}
	decision := domain.DecisionRechazado
	if req.Acepta {
		decision = domain.DecisionAceptado
	}
	c := &domain.Consentimiento{
		UsuarioID: req.UsuarioID, Version: req.Version, Decision: decision,
		DispositivoID: req.DispositivoID, IPOrigen: req.IPOrigen, DecididoEn: s.ahora(),
	}
	if err := s.repo.Registrar(ctx, c); err != nil {
		return domain.Estado{}, err
	}
	if s.auditoria != nil {
		_ = s.auditoria.Create(ctx, &repository.AuditEntry{
			Entidad: "consentimientos", EntidadID: c.ID, Accion: "CONSENTIMIENTO_" + string(decision),
			ActorID: req.UsuarioID, IPOrigen: req.IPOrigen, CreadoEn: c.DecididoEn,
			ValorNuevo: map[string]string{"version": c.Version, "decision": string(decision), "dispositivoId": c.DispositivoID},
		})
	}
	return domain.CalcularEstado(s.politica.Version, c), nil
}
