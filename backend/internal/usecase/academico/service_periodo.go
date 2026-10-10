package academico

import (
	"context"
	"fmt"
	"time"

	domainAca "github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/domain/shared"
	applog "github.com/siaa/backend/internal/platform/log"
)

// ─────────────────────────────────────────────────────────────
// 1. GESTIÓN DE PERIODOS ACADÉMICOS (US-ACA-01)
// ─────────────────────────────────────────────────────────────

type CrearPeriodoCmd struct {
	Codigo        string
	Nombre        string
	FechaInicio   time.Time
	FechaFin      time.Time
	Estado        domainAca.EstadoPeriodo
	SedeID        string
	CodigoExterno *string
	// ConfirmarSolapamiento acepta activar un periodo que se cruza con otro activo (AC-03).
	ConfirmarSolapamiento bool
}

type ResultadoPeriodo struct {
	Periodo      *domainAca.Periodo
	Advertencias []string
}

func (s *Service) CrearPeriodo(ctx context.Context, actor ContextoActor, cmd CrearPeriodoCmd) (*ResultadoPeriodo, error) {
	ahora := s.clk.Now()
	p, err := domainAca.NuevoPeriodo(
		shared.NewID(),
		cmd.Codigo,
		cmd.Nombre,
		cmd.FechaInicio,
		cmd.FechaFin,
		cmd.Estado,
		cmd.SedeID,
		cmd.CodigoExterno,
		ahora,
	)
	if err != nil {
		return nil, err
	}

	var advertencias []string

	// US-ACA-01 AC-03: Advertencia si se activa un segundo periodo con fechas solapadas en la misma sede
	if p.Estado() == domainAca.EstadoActivo && p.SedeID() != "" {
		solapado, err := s.periodoRepo.FindActivoSolapado(ctx, p.SedeID(), p.FechaInicio(), p.FechaFin(), "")
		if err == nil && solapado != nil {
			if !cmd.ConfirmarSolapamiento {
				return nil, errorPeriodoSolapado(solapado)
			}
			advertencias = append(advertencias, fmt.Sprintf("Advertencia: ya existe un periodo ACTIVO (%s) con fechas solapadas para la misma sede (US-ACA-01 AC-03)", solapado.Codigo()))
		}
	}

	if err := s.periodoRepo.Create(ctx, p); err != nil {
		return nil, fmt.Errorf("error al persistir periodo: %w", err)
	}

	s.log.Info("periodo creado", applog.UsuarioID(actor.UsuarioID), applog.Extra(map[string]interface{}{"id": p.ID(), "codigo": p.Codigo()}))
	return &ResultadoPeriodo{Periodo: p, Advertencias: advertencias}, nil
}

func (s *Service) ActualizarPeriodo(ctx context.Context, actor ContextoActor, id string, cmd CrearPeriodoCmd) (*ResultadoPeriodo, error) {
	p, err := s.periodoRepo.GetByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if p == nil {
		return nil, ErrPeriodoNoEncontrado
	}

	// US-ACA-01 AC-02: Periodo en estado cerrado no puede modificarse
	if err := p.PuedeModificar(); err != nil {
		return nil, err
	}

	// Lo que el formulario de edición no envía se conserva.
	if cmd.SedeID == "" {
		cmd.SedeID = p.SedeID()
	}
	if cmd.CodigoExterno == nil {
		cmd.CodigoExterno = p.CodigoExterno()
	}

	ahora := s.clk.Now()
	nuevo, err := domainAca.NuevoPeriodo(
		id,
		cmd.Codigo,
		cmd.Nombre,
		cmd.FechaInicio,
		cmd.FechaFin,
		cmd.Estado,
		cmd.SedeID,
		cmd.CodigoExterno,
		ahora,
	)
	if err != nil {
		return nil, err
	}

	var advertencias []string
	if nuevo.Estado() == domainAca.EstadoActivo && nuevo.SedeID() != "" {
		solapado, err := s.periodoRepo.FindActivoSolapado(ctx, nuevo.SedeID(), nuevo.FechaInicio(), nuevo.FechaFin(), id)
		if err == nil && solapado != nil {
			if !cmd.ConfirmarSolapamiento {
				return nil, errorPeriodoSolapado(solapado)
			}
			advertencias = append(advertencias, fmt.Sprintf("Advertencia: ya existe un periodo ACTIVO (%s) con fechas solapadas para la misma sede (US-ACA-01 AC-03)", solapado.Codigo()))
		}
	}

	if err := s.periodoRepo.Update(ctx, nuevo); err != nil {
		return nil, err
	}

	s.log.Info("periodo actualizado", applog.UsuarioID(actor.UsuarioID), applog.Extra(map[string]interface{}{"id": id, "codigo": nuevo.Codigo()}))
	return &ResultadoPeriodo{Periodo: nuevo, Advertencias: advertencias}, nil
}

func (s *Service) ObtenerPeriodo(ctx context.Context, id string) (*domainAca.Periodo, error) {
	p, err := s.periodoRepo.GetByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if p == nil {
		return nil, ErrPeriodoNoEncontrado
	}
	return p, nil
}

func (s *Service) ListarPeriodos(ctx context.Context, sedeID string) ([]*domainAca.Periodo, error) {
	if sedeID != "" {
		return s.periodoRepo.ListBySedeID(ctx, sedeID)
	}
	return s.periodoRepo.ListAll(ctx)
}

// errorPeriodoSolapado pide confirmar la activación de un periodo que se cruza con otro activo
// de la misma sede (US-ACA-01 AC-03).
func errorPeriodoSolapado(otro *domainAca.Periodo) error {
	return &shared.DomainError{Code: shared.ErrConfirmacionRequerida, Message: fmt.Sprintf(
		"Ya hay un periodo activo (%s) con fechas que se cruzan en esta sede. Confirma para activarlo de todos modos.", otro.Codigo())}
}
