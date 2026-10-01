package academico

import (
	"context"

	domainAca "github.com/siaa/backend/internal/domain/academico"
)

// ─────────────────────────────────────────────────────────────
// Edición de la estructura curricular (US-ACA-01 AC-04). Se corrigen código, nombre y
// datos propios; el padre (sede, facultad, programa, asignatura, periodo) no cambia para
// no romper lo que ya cuelga de cada nivel. Las validaciones son las mismas de la creación.
// ─────────────────────────────────────────────────────────────

func (s *Service) ActualizarFacultad(ctx context.Context, actor ContextoActor, id, codigo, nombre string) (*domainAca.Facultad, error) {
	prev, err := s.estructuraRepo.GetFacultadByID(ctx, id)
	if err != nil || prev == nil {
		return nil, ErrFacultadNoEncontrada
	}
	if !actor.permiteFacultad(prev.ID(), prev.SedeID()) {
		return nil, ErrFueraDeAmbitoFacultad
	}
	v, err := domainAca.NuevaFacultad(id, codigo, nombre, prev.SedeID(), prev.CodigoExterno(), s.clk.Now())
	if err != nil {
		return nil, err
	}
	f := domainAca.ReconstituirFacultad(id, v.Codigo(), v.Nombre(), prev.SedeID(), prev.CodigoExterno(), false, prev.CreadoEn(), v.ActualizadoEn())
	return f, s.estructuraRepo.UpdateFacultad(ctx, f)
}

func (s *Service) ActualizarPrograma(ctx context.Context, actor ContextoActor, id, codigo, nombre string) (*domainAca.Programa, error) {
	prev, err := s.estructuraRepo.GetProgramaByID(ctx, id)
	if err != nil || prev == nil {
		return nil, ErrProgramaNoEncontrado
	}
	if err := s.exigirFacultad(ctx, actor, prev.FacultadID()); err != nil {
		return nil, err
	}
	v, err := domainAca.NuevoPrograma(id, codigo, nombre, prev.FacultadID(), prev.CodigoExterno(), s.clk.Now())
	if err != nil {
		return nil, err
	}
	p := domainAca.ReconstituirPrograma(id, v.Codigo(), v.Nombre(), prev.FacultadID(), prev.CodigoExterno(), false, prev.CreadoEn(), v.ActualizadoEn())
	return p, s.estructuraRepo.UpdatePrograma(ctx, p)
}

func (s *Service) ActualizarAsignatura(ctx context.Context, actor ContextoActor, id, codigo, nombre string, creditos int) (*domainAca.Asignatura, error) {
	prev, err := s.estructuraRepo.GetAsignaturaByID(ctx, id)
	if err != nil || prev == nil {
		return nil, ErrAsignaturaNoEncontrada
	}
	if prog, err := s.estructuraRepo.GetProgramaByID(ctx, prev.ProgramaID()); err == nil && prog != nil {
		if err := s.exigirFacultad(ctx, actor, prog.FacultadID()); err != nil {
			return nil, err
		}
	}
	v, err := domainAca.NuevaAsignatura(id, codigo, nombre, prev.ProgramaID(), creditos, prev.CodigoExterno(), s.clk.Now())
	if err != nil {
		return nil, err
	}
	a := domainAca.ReconstituirAsignatura(id, v.Codigo(), v.Nombre(), prev.ProgramaID(), v.Creditos(), prev.CodigoExterno(), false, prev.CreadoEn(), v.ActualizadoEn())
	return a, s.estructuraRepo.UpdateAsignatura(ctx, a)
}

func (s *Service) ActualizarGrupo(ctx context.Context, actor ContextoActor, id, numero string, cupo int) (*domainAca.Grupo, error) {
	prev, err := s.estructuraRepo.GetGrupoByID(ctx, id)
	if err != nil || prev == nil {
		return nil, ErrGrupoNoEncontrado
	}
	per, err := s.periodoRepo.GetByID(ctx, prev.PeriodoID())
	if err != nil || per == nil {
		return nil, ErrPeriodoNoEncontrado
	}
	if err := per.PuedeModificar(); err != nil {
		return nil, err
	}
	v, err := domainAca.NuevoGrupo(id, numero, prev.AsignaturaID(), prev.PeriodoID(), cupo, prev.CodigoExterno(), s.clk.Now())
	if err != nil {
		return nil, err
	}
	g := domainAca.ReconstituirGrupo(id, v.Numero(), prev.AsignaturaID(), prev.PeriodoID(), v.Cupo(), prev.CodigoExterno(), false, prev.CreadoEn(), v.ActualizadoEn())
	return g, s.estructuraRepo.UpdateGrupo(ctx, g)
}

// exigirFacultad verifica que el actor tenga en su ámbito la facultad indicada.
func (s *Service) exigirFacultad(ctx context.Context, actor ContextoActor, facultadID string) error {
	if !actor.porAmbito() {
		return nil
	}
	fac, err := s.estructuraRepo.GetFacultadByID(ctx, facultadID)
	if err != nil || fac == nil {
		return ErrFacultadNoEncontrada
	}
	if !actor.permiteFacultad(fac.ID(), fac.SedeID()) {
		return ErrFueraDeAmbitoFacultad
	}
	return nil
}
