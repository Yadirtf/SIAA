package academico

import (
	"context"
	"fmt"

	domainAca "github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/repository"
)

// motivoAsignacionEliminada se guarda en las sesiones futuras que se cancelan al borrar su asignación.
const motivoAsignacionEliminada = "Asignación eliminada"

// ResultadoEdicionAsignacion informa la asignación editada y cómo quedaron sus sesiones futuras.
type ResultadoEdicionAsignacion struct {
	Asignacion           *domainAca.Asignacion
	Advertencias         []string
	SesionesReemplazadas int
	SesionesGeneradas    int
}

// ActualizarAsignacion corrige docente, aula, franja o modalidad de una asignación (cambios reales a
// mitad de semestre). Repite las validaciones de la creación, incluido el cruce de horario sin
// contarse a sí misma. Las sesiones ya dictadas o cuya ventana ya abrió no se tocan; las futuras se
// reemplazan por las de la asignación nueva.
func (s *Service) ActualizarAsignacion(ctx context.Context, actor ContextoActor, id string, cmd CrearAsignacionCmd) (*ResultadoEdicionAsignacion, error) {
	prev, err := s.asignacionRepo.GetByID(ctx, id)
	if err != nil || prev == nil || prev.Borrado() {
		return nil, ErrAsignacionNoEncontrada
	}
	periodo, err := s.periodoRepo.GetByID(ctx, prev.PeriodoID())
	if err != nil || periodo == nil {
		return nil, ErrPeriodoNoEncontrado
	}
	if err := periodo.PuedeModificar(); err != nil {
		return nil, err
	}
	if !actor.permiteFacultad(prev.FacultadID(), periodo.SedeID()) {
		return nil, ErrFueraDeAmbitoFacultad
	}

	// El periodo no cambia; asignatura y facultad se derivan otra vez del grupo.
	cmd.PeriodoID, cmd.AsignaturaID, cmd.FacultadID = prev.PeriodoID(), "", ""
	if cmd.GrupoID == "" {
		cmd.GrupoID = prev.GrupoID()
	}
	if err := s.completarAsignacion(ctx, &cmd, periodo.SedeID()); err != nil {
		return nil, err
	}
	if !actor.permiteFacultad(cmd.FacultadID, periodo.SedeID()) {
		return nil, ErrFueraDeAmbitoFacultad
	}
	franja, advertencias, err := domainAca.NuevaFranjaHoraria(cmd.DiaSemana, cmd.HoraInicio, cmd.HoraFin, cmd.ZonaHoraria)
	if err != nil {
		return nil, err
	}
	ahora := s.clk.Now()
	v, err := domainAca.NuevaAsignacion(id, cmd.PeriodoID, cmd.DocenteIDs, cmd.DocenteNombre, cmd.GrupoID,
		cmd.AsignaturaID, cmd.FacultadID, cmd.EspacioID, cmd.EspacioNombre, franja, cmd.Modalidad,
		prev.ParametrosOverride(), prev.FechaInicio(), prev.FechaFin(), prev.CodigoExterno(), ahora)
	if err != nil {
		return nil, err
	}
	asig := domainAca.ReconstituirAsignacion(id, v.PeriodoID(), v.DocenteIDs(), v.DocenteNombre(), v.GrupoID(),
		v.AsignaturaID(), v.FacultadID(), v.EspacioID(), v.EspacioNombre(), v.Franja(), v.Modalidad(),
		v.ExentaGeoespacial(), v.ParametrosOverride(), prev.Estado(), v.FechaInicio(), v.FechaFin(),
		v.CodigoExterno(), false, prev.CreadoEn(), ahora)

	existentes, err := s.asignacionRepo.ListByPeriodoID(ctx, cmd.PeriodoID)
	if err != nil {
		return nil, fmt.Errorf("error al verificar colisiones: %w", err)
	}
	if colision := domainAca.DetectarColisiones(existentes, *asig); colision != nil {
		return nil, s.errorColisionLegible(ctx, colision, existentes)
	}
	if err := s.asignacionRepo.Update(ctx, asig); err != nil {
		return nil, fmt.Errorf("error al actualizar asignación: %w", err)
	}

	res := &ResultadoEdicionAsignacion{Asignacion: asig, Advertencias: advertencias}
	res.SesionesReemplazadas, res.SesionesGeneradas = s.reemplazarSesionesFuturas(ctx, actor, asig)
	s.auditar(ctx, "asignacion", id, "ASIGNACION_ACTUALIZADA", actor, resumenAsignacion(prev), resumenAsignacion(asig))
	return res, nil
}

// reemplazarSesionesFuturas oculta las sesiones PROGRAMADAS cuya ventana de entrada aún no abre
// (no pueden tener marcajes) y genera las de la asignación vigente desde ahora.
func (s *Service) reemplazarSesionesFuturas(ctx context.Context, actor ContextoActor, asig *domainAca.Asignacion) (int, int) {
	futuras := s.sesionesFuturas(ctx, asig.ID())
	ids := make([]string, 0, len(futuras))
	for _, ses := range futuras {
		ids = append(ids, ses.ID())
	}
	ocultas, err := s.sesionRepo.EliminarLogico(ctx, ids)
	if err != nil {
		s.log.Warn("no se pudieron reemplazar las sesiones futuras")
		return 0, 0
	}
	asigID := asig.ID()
	informe, err := s.GenerarSesiones(ctx, GenerarSesionesCmd{
		PeriodoID: asig.PeriodoID(), AsignacionID: &asigID, Actor: actor, Desde: s.clk.Now(),
	})
	if err != nil {
		return int(ocultas), 0
	}
	return int(ocultas), informe.SesionesGeneradas
}

// cancelarSesionesFuturas cancela, al eliminar una asignación, las sesiones que aún no ocurren para
// que no queden como inasistencias. Devuelve cuántas canceló.
func (s *Service) cancelarSesionesFuturas(ctx context.Context, actor ContextoActor, asignacionID string) int {
	canceladas := 0
	for _, ses := range s.sesionesFuturas(ctx, asignacionID) {
		if err := ses.Cancelar(motivoAsignacionEliminada, s.clk.Now()); err != nil {
			continue
		}
		if err := s.sesionRepo.Update(ctx, ses); err == nil {
			canceladas++
		}
	}
	if canceladas > 0 {
		s.auditar(ctx, "asignacion", asignacionID, "SESIONES_FUTURAS_CANCELADAS", actor, nil, map[string]interface{}{"canceladas": canceladas})
	}
	return canceladas
}

func (s *Service) sesionesFuturas(ctx context.Context, asignacionID string) []*domainAca.Sesion {
	if s.sesionRepo == nil {
		return nil
	}
	programada := domainAca.EstadoSesionProgramada
	lista, err := s.sesionRepo.List(ctx, repository.SesionFilter{AsignacionID: asignacionID, Estado: &programada})
	if err != nil {
		return nil
	}
	ahora := s.clk.Now()
	futuras := make([]*domainAca.Sesion, 0, len(lista))
	for _, ses := range lista {
		if ses.VentanaEntradaAbre().After(ahora) {
			futuras = append(futuras, ses)
		}
	}
	return futuras
}

func resumenAsignacion(a *domainAca.Asignacion) map[string]interface{} {
	return map[string]interface{}{
		"docenteIds": a.DocenteIDs(), "grupoId": a.GrupoID(), "espacioId": a.EspacioID(),
		"diaSemana": a.Franja().DiaSemana(), "horaInicio": a.Franja().HoraInicio(),
		"horaFin": a.Franja().HoraFin(), "modalidad": a.Modalidad(),
	}
}
