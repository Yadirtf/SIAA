package academico

import (
	"context"
	"fmt"
	"time"

	domainAca "github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/domain/shared"
	applog "github.com/siaa/backend/internal/platform/log"
)

// ─────────────────────────────────────────────────────────────
// 3. GESTIÓN DE ASIGNACIONES (US-ACA-02, US-ACA-03)
// ─────────────────────────────────────────────────────────────

type CrearAsignacionCmd struct {
	PeriodoID          string
	DocenteIDs         []string
	DocenteNombre      string
	GrupoID            string
	AsignaturaID       string
	FacultadID         string
	EspacioID          string
	EspacioNombre      string
	DiaSemana          int
	HoraInicio         string
	HoraFin            string
	ZonaHoraria        string
	Modalidad          domainAca.ModalidadAsignacion
	ParametrosOverride map[string]interface{}
	FechaInicio        time.Time
	FechaFin           time.Time
	CodigoExterno      *string
}

type ResultadoAsignacion struct {
	Asignacion   *domainAca.Asignacion
	Advertencias []string
}

func (s *Service) CrearAsignacion(ctx context.Context, actor ContextoActor, cmd CrearAsignacionCmd) (*ResultadoAsignacion, error) {
	// 1. Validar alcance ABAC del actor si es coordinador (US-ACA-03 AC-07)
	if cmd.FacultadID != "" && (actor.Rol == string(rbac.RolCoordinador) || len(actor.Scopes) > 0) {
		scopes := actor.Scopes
		if len(scopes) == 0 && s.usuarioRepo != nil && actor.UsuarioID != "" {
			if u, err := s.usuarioRepo.FindByID(ctx, actor.UsuarioID); err == nil && u != nil {
				scopes = u.Ambitos
			}
		}
		if len(scopes) > 0 && !rbac.IsInScope(scopes, rbac.ScopeFacultad, cmd.FacultadID) {
			return nil, ErrFueraDeAmbitoFacultad
		}
	}

	// 2. Validar periodo
	periodo, err := s.periodoRepo.GetByID(ctx, cmd.PeriodoID)
	if err != nil || periodo == nil {
		return nil, ErrPeriodoNoEncontrado
	}
	if err := periodo.PuedeModificar(); err != nil {
		return nil, err
	}

	// 3. Construir y validar franja horaria (US-ACA-02)
	franja, franjaAdv, err := domainAca.NuevaFranjaHoraria(cmd.DiaSemana, cmd.HoraInicio, cmd.HoraFin, cmd.ZonaHoraria)
	if err != nil {
		return nil, err
	}

	ahora := s.clk.Now()
	fInicio := cmd.FechaInicio
	if fInicio.IsZero() {
		fInicio = periodo.FechaInicio()
	}
	fFin := cmd.FechaFin
	if fFin.IsZero() {
		fFin = periodo.FechaFin()
	}

	asig, err := domainAca.NuevaAsignacion(
		shared.NewID(),
		cmd.PeriodoID,
		cmd.DocenteIDs,
		cmd.DocenteNombre,
		cmd.GrupoID,
		cmd.AsignaturaID,
		cmd.FacultadID,
		cmd.EspacioID,
		cmd.EspacioNombre,
		franja,
		cmd.Modalidad,
		cmd.ParametrosOverride,
		fInicio,
		fFin,
		cmd.CodigoExterno,
		ahora,
	)
	if err != nil {
		return nil, err
	}

	// 4. Detección de colisiones contra asignaciones activas del periodo (US-ACA-03 AC-02, AC-03, RF-ACA-005)
	existentes, err := s.asignacionRepo.ListByPeriodoID(ctx, cmd.PeriodoID)
	if err != nil {
		return nil, fmt.Errorf("error al verificar colisiones: %w", err)
	}

	if colision := domainAca.DetectarColisiones(existentes, *asig); colision != nil {
		s.log.Warn("colisión horaria rechazada", applog.Extra(map[string]interface{}{"tipo": colision.Tipo, "mensaje": colision.Mensaje}))
		return nil, fmt.Errorf("%w: %s", ErrColisionDetectada, colision.Mensaje)
	}

	var advertencias []string
	advertencias = append(advertencias, franjaAdv...)

	// 5. Advertencia si espacio no tiene geometría capturada (US-ACA-03 AC-04)
	if !asig.ExentaGeoespacial() && asig.EspacioID() != "" {
		espacio, err := s.espacioRepo.FindByID(ctx, asig.EspacioID())
		if err == nil && espacio != nil {
			if espacio.Geometria == nil || len(espacio.Geometria.Coordinates()) == 0 {
				advertencias = append(advertencias, "Advertencia: El espacio asignado no tiene geometría levantada. Las sesiones generadas no podrán validarse espacialmente hasta capturar su geocerca (US-ACA-03 AC-04).")
			}
		}
	}

	if err := s.asignacionRepo.Create(ctx, asig); err != nil {
		return nil, fmt.Errorf("error al persistir asignación: %w", err)
	}

	s.log.Info("asignación creada", applog.UsuarioID(actor.UsuarioID), applog.Extra(map[string]interface{}{"id": asig.ID(), "periodo": asig.PeriodoID(), "grupo": asig.GrupoID()}))
	return &ResultadoAsignacion{
		Asignacion:   asig,
		Advertencias: advertencias,
	}, nil
}

func (s *Service) ListarAsignaciones(ctx context.Context, periodoID string) ([]domainAca.Asignacion, error) {
	return s.asignacionRepo.ListByPeriodoID(ctx, periodoID)
}

func (s *Service) EliminarAsignacion(ctx context.Context, actor ContextoActor, id string) error {
	return s.asignacionRepo.DeleteLogico(ctx, id)
}
