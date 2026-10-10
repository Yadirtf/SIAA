// Package privacidad — marcado y liberación de investigaciones que suspenden la retención
// (US-AUD-04 AC-03). Cada marca y cada liberación quedan en la bitácora; si la bitácora no
// se puede escribir, la operación no se aplica (US-AUD-01 AC-05).
package privacidad

import (
	"context"
	"fmt"
	"time"

	domain "github.com/siaa/backend/internal/domain/privacidad"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/repository"
)

// Acciones de bitácora de las investigaciones.
const (
	AccionInvestigacionMarcada  = "INVESTIGACION_MARCADA"
	AccionInvestigacionLiberada = "INVESTIGACION_LIBERADA"
)

// Investigaciones gestiona las marcas de investigación en curso.
type Investigaciones struct {
	repo      repository.InvestigacionRepository
	auditoria repository.AuditoriaRepository
	ahora     func() time.Time
}

// NewInvestigaciones crea el servicio de investigaciones.
func NewInvestigaciones(repo repository.InvestigacionRepository, auditoria repository.AuditoriaRepository) *Investigaciones {
	return &Investigaciones{repo: repo, auditoria: auditoria, ahora: func() time.Time { return time.Now().UTC() }}
}

// SolicitudInvestigacion son los datos para marcar un registro.
type SolicitudInvestigacion struct {
	Alcance    domain.AlcanceInvestigacion
	ObjetivoID string
	Motivo     string
}

// Marcar suspende la retención de los registros indicados hasta que se libere.
func (s *Investigaciones) Marcar(ctx context.Context, actorID string, sol SolicitudInvestigacion) (*domain.Investigacion, error) {
	inv, err := domain.NuevaInvestigacion(sol.Alcance, sol.ObjetivoID, sol.Motivo, actorID, s.ahora())
	if err != nil {
		return nil, err
	}
	if err := s.repo.Crear(ctx, inv); err != nil {
		return nil, err
	}
	if err := s.auditar(ctx, AccionInvestigacionMarcada, actorID, inv, nil); err != nil {
		// Sin rastro en la bitácora la marca no puede quedar vigente.
		if errRev := s.repo.Liberar(ctx, liberadaPorFallo(inv, s.ahora())); errRev != nil {
			return nil, fmt.Errorf("auditar investigación: %w (y no se pudo revertir: %v)", err, errRev)
		}
		return nil, fmt.Errorf("auditar investigación: %w", err)
	}
	return inv, nil
}

// Liberar cierra la investigación: sus registros vuelven a la retención normal.
func (s *Investigaciones) Liberar(ctx context.Context, actorID, id string) (*domain.Investigacion, error) {
	inv, err := s.repo.Obtener(ctx, id)
	if err != nil {
		return nil, err
	}
	if inv == nil {
		return nil, shared.NewNotFoundError("Investigación", id)
	}
	anterior := *inv
	if err := inv.Liberar(actorID, s.ahora()); err != nil {
		return nil, err
	}
	// Se audita antes de liberar: si la bitácora falla, la investigación sigue activa.
	if err := s.auditar(ctx, AccionInvestigacionLiberada, actorID, inv, &anterior); err != nil {
		return nil, fmt.Errorf("auditar liberación: %w", err)
	}
	if err := s.repo.Liberar(ctx, inv); err != nil {
		return nil, &shared.DomainError{Code: shared.ErrEstadoInvalido, Message: "La investigación ya fue liberada", Cause: err}
	}
	return inv, nil
}

// Activas lista las investigaciones en curso.
func (s *Investigaciones) Activas(ctx context.Context) ([]*domain.Investigacion, error) {
	return s.repo.Activas(ctx)
}

func (s *Investigaciones) auditar(ctx context.Context, accion, actorID string, inv, anterior *domain.Investigacion) error {
	if s.auditoria == nil {
		return nil
	}
	entrada := &repository.AuditEntry{
		Entidad: "investigaciones_retencion", EntidadID: inv.ID, Accion: accion, ActorID: actorID,
		CreadoEn: s.ahora(), ValorNuevo: resumen(inv),
	}
	if anterior != nil {
		entrada.ValorAnterior = resumen(anterior)
	}
	return s.auditoria.Create(ctx, entrada)
}

func resumen(i *domain.Investigacion) map[string]interface{} {
	r := map[string]interface{}{
		"alcance": string(i.Alcance), "objetivoId": i.ObjetivoID, "motivo": i.Motivo,
		"creadaPor": i.CreadaPor, "activa": i.Activa(),
	}
	if i.LiberadaEn != nil {
		r["liberadaEn"], r["liberadaPor"] = *i.LiberadaEn, i.LiberadaPor
	}
	return r
}

// liberadaPorFallo marca como liberada una investigación cuya creación no pudo auditarse.
func liberadaPorFallo(inv *domain.Investigacion, ahora time.Time) *domain.Investigacion {
	c := *inv
	t := ahora
	c.LiberadaEn, c.LiberadaPor = &t, "sistema:auditoria-fallida"
	return &c
}
