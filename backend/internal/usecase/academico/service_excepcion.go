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
// 4. CALENDARIO DE EXCEPCIONES (US-ACA-04)
// ─────────────────────────────────────────────────────────────

type CrearExcepcionCmd struct {
	Nombre      string
	Tipo        domainAca.TipoExcepcion
	Ambito      domainAca.AmbitoExcepcion
	AmbitoID    string
	FechaInicio time.Time
	FechaFin    time.Time
}

func (s *Service) CrearExcepcion(ctx context.Context, actor ContextoActor, cmd CrearExcepcionCmd) (*domainAca.CalendarioExcepcion, error) {
	exc, err := domainAca.NuevaCalendarioExcepcion(
		shared.NewID(),
		cmd.Nombre,
		cmd.Tipo,
		cmd.Ambito,
		cmd.AmbitoID,
		cmd.FechaInicio,
		cmd.FechaFin,
		s.clk.Now(),
	)
	if err != nil {
		return nil, err
	}

	if err := s.excepcionRepo.Create(ctx, exc); err != nil {
		return nil, fmt.Errorf("error al persistir excepción: %w", err)
	}

	s.log.Info("excepción de calendario creada", applog.UsuarioID(actor.UsuarioID), applog.Extra(map[string]interface{}{"id": exc.ID(), "tipo": exc.Tipo(), "ambito": exc.Ambito()}))
	return exc, nil
}

func (s *Service) ListarExcepciones(ctx context.Context) ([]*domainAca.CalendarioExcepcion, error) {
	return s.excepcionRepo.ListAll(ctx)
}

func (s *Service) EliminarExcepcion(ctx context.Context, actor ContextoActor, id string) error {
	return s.excepcionRepo.DeleteLogico(ctx, id)
}
