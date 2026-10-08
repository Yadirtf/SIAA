package academico

import (
	"context"
	"fmt"
	"time"

	domainAca "github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/domain/shared"
	applog "github.com/siaa/backend/internal/platform/log"
	"github.com/siaa/backend/internal/repository"
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

// ResultadoExcepcion acompaña la excepción con las sesiones que canceló (AC-03).
type ResultadoExcepcion struct {
	Excepcion          *domainAca.CalendarioExcepcion
	SesionesCanceladas int
}

// FechasLiberadas describe lo que se puede regenerar al eliminar una excepción (AC-04):
// el sistema no regenera solo; ofrece los periodos donde hay sesiones por reactivar.
type FechasLiberadas struct {
	FechaInicio          string   `json:"fechaInicio"`
	FechaFin             string   `json:"fechaFin"`
	SesionesReactivables int      `json:"sesionesReactivables"`
	PeriodoIDs           []string `json:"periodoIds"`
	Mensaje              string   `json:"mensaje"`
}

func (s *Service) CrearExcepcion(ctx context.Context, actor ContextoActor, cmd CrearExcepcionCmd) (*ResultadoExcepcion, error) {
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

	canceladas := s.cancelarPorExcepcion(ctx, exc)
	s.auditar(ctx, "calendario_excepcion", exc.ID(), "EXCEPCION_CREADA", actor, nil, map[string]interface{}{
		"nombre": exc.Nombre(), "tipo": exc.Tipo(), "ambito": exc.Ambito(), "ambitoId": exc.AmbitoID(),
		"fechaInicio": exc.FechaInicio().Format("2006-01-02"), "fechaFin": exc.FechaFin().Format("2006-01-02"),
		"sesionesCanceladas": canceladas,
	})
	s.log.Info("excepción de calendario creada", applog.UsuarioID(actor.UsuarioID), applog.Extra(map[string]interface{}{"id": exc.ID(), "tipo": exc.Tipo(), "ambito": exc.Ambito(), "canceladas": canceladas}))
	return &ResultadoExcepcion{Excepcion: exc, SesionesCanceladas: canceladas}, nil
}

// cancelarPorExcepcion cancela, con motivo, las sesiones ya generadas que caen en la
// excepción y su ámbito; los marcajes existentes no se tocan (AC-03, AC-05).
func (s *Service) cancelarPorExcepcion(ctx context.Context, exc *domainAca.CalendarioExcepcion) int {
	if s.sesionRepo == nil {
		return 0
	}
	motivo := domainAca.MotivoExcepcionPrefijo + exc.Nombre() + " (" + string(exc.Tipo()) + ")"
	canceladas := 0
	for _, ses := range s.sesionesEnExcepcion(ctx, exc) {
		if ses.Estado() != domainAca.EstadoSesionProgramada && ses.Estado() != domainAca.EstadoSesionEnCurso {
			continue
		}
		if ses.Cancelar(motivo, s.clk.Now()) == nil && s.sesionRepo.Update(ctx, ses) == nil {
			canceladas++
		}
	}
	return canceladas
}

// sesionesEnExcepcion lista las sesiones del rango de fechas que caen en el ámbito.
func (s *Service) sesionesEnExcepcion(ctx context.Context, exc *domainAca.CalendarioExcepcion) []*domainAca.Sesion {
	lista, err := s.sesionRepo.List(ctx, repository.SesionFilter{
		FechaDesde: exc.FechaInicio().Format("2006-01-02"),
		FechaHasta: exc.FechaFin().Format("2006-01-02"),
	})
	if err != nil {
		return nil
	}
	sedes := map[string]string{}
	out := make([]*domainAca.Sesion, 0, len(lista))
	for _, ses := range lista {
		fecha, err := time.Parse("2006-01-02", ses.Fecha())
		if err != nil {
			continue
		}
		sede := ses.SedeID()
		if sede == "" {
			if _, ok := sedes[ses.PeriodoID()]; !ok {
				sedes[ses.PeriodoID()] = s.sedeDePeriodo(ctx, ses.PeriodoID())
			}
			sede = sedes[ses.PeriodoID()]
		}
		if exc.AfectaFechaYAmbito(fecha, sede, ses.FacultadID()) {
			out = append(out, ses)
		}
	}
	return out
}

func (s *Service) ListarExcepciones(ctx context.Context) ([]*domainAca.CalendarioExcepcion, error) {
	return s.excepcionRepo.ListAll(ctx)
}

// EliminarExcepcion borra la excepción y ofrece regenerar las fechas liberadas sin
// hacerlo automáticamente (AC-04).
func (s *Service) EliminarExcepcion(ctx context.Context, actor ContextoActor, id string) (*FechasLiberadas, error) {
	exc, err := s.excepcionRepo.GetByID(ctx, id)
	if err != nil || exc == nil {
		return nil, ErrExcepcionNoEncontrada
	}
	liberadas := &FechasLiberadas{FechaInicio: exc.FechaInicio().Format("2006-01-02"), FechaFin: exc.FechaFin().Format("2006-01-02")}
	if s.sesionRepo != nil {
		periodos := map[string]bool{}
		for _, ses := range s.sesionesEnExcepcion(ctx, exc) {
			if ses.CanceladaPorExcepcion() && ses.InicioProgramado().After(s.clk.Now()) {
				liberadas.SesionesReactivables++
				if !periodos[ses.PeriodoID()] {
					periodos[ses.PeriodoID()] = true
					liberadas.PeriodoIDs = append(liberadas.PeriodoIDs, ses.PeriodoID())
				}
			}
		}
	}
	if err := s.excepcionRepo.DeleteLogico(ctx, id); err != nil {
		return nil, err
	}
	s.auditar(ctx, "calendario_excepcion", id, "EXCEPCION_ELIMINADA", actor, map[string]interface{}{
		"nombre": exc.Nombre(), "fechaInicio": liberadas.FechaInicio, "fechaFin": liberadas.FechaFin}, nil)
	liberadas.Mensaje = "Excepción eliminada. No se regeneró nada automáticamente."
	if liberadas.SesionesReactivables > 0 {
		liberadas.Mensaje = fmt.Sprintf("Excepción eliminada. Hay %d sesiones canceladas por ella que puede recuperar regenerando las sesiones del periodo.", liberadas.SesionesReactivables)
	}
	return liberadas, nil
}
