// Package academico — aplicación del alcance ABAC a la gestión académica (RF-ROL-003).
package academico

import (
	"context"

	domainAca "github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/domain/rbac"
)

// alcanceEfectivo devuelve el alcance a aplicar. Si el actor no trae uno calculado pero sí
// ámbitos (o es coordinador), se deriva de ellos; si no, el uso es interno y sin restricción.
func (a ContextoActor) alcanceEfectivo() *rbac.Alcance {
	if a.Alcance != nil {
		return a.Alcance
	}
	if a.Rol == string(rbac.RolCoordinador) || len(a.Scopes) > 0 {
		al := rbac.NuevoAlcance(a.Rol, nil, a.UsuarioID, a.Scopes)
		return &al
	}
	return nil
}

// permiteFacultad indica si el actor puede operar sobre la facultad (de la sede dada).
func (a ContextoActor) permiteFacultad(facultadID, sedeID string) bool {
	al := a.alcanceEfectivo()
	return al == nil || al.PermiteFacultad(facultadID, sedeID)
}

// porAmbito indica si el actor está restringido a sus sedes y facultades. Los catálogos de
// estructura (facultades, programas) solo se restringen en ese caso: un docente o estudiante
// los consulta como referencia, sin datos operativos.
func (a ContextoActor) porAmbito() bool {
	al := a.alcanceEfectivo()
	return al != nil && al.PorAmbito()
}

// permiteAsignacion indica si el actor puede ver la asignación: el docente solo las suyas,
// el coordinador las de sus facultades.
func (a ContextoActor) permiteAsignacion(asig *domainAca.Asignacion, sedeID string) bool {
	al := a.alcanceEfectivo()
	if al == nil {
		return true
	}
	return al.PermiteSesion(asig.DocenteIDs(), asig.FacultadID(), sedeID)
}

// sesionEnAlcance obtiene la sesión y verifica que el actor pueda operarla.
func (s *Service) sesionEnAlcance(ctx context.Context, id string, actor ContextoActor) (*domainAca.Sesion, error) {
	sesion, err := s.ObtenerSesionPorID(ctx, id)
	if err != nil {
		return nil, err
	}
	if al := actor.alcanceEfectivo(); al != nil && !al.PermiteSesion(sesion.DocenteIDs(), sesion.FacultadID(), sesion.SedeID()) {
		return nil, ErrFueraDeAmbitoFacultad
	}
	return sesion, nil
}

// sedeDePeriodo devuelve la sede del periodo, o vacío si no existe.
func (s *Service) sedeDePeriodo(ctx context.Context, periodoID string) string {
	p, err := s.periodoRepo.GetByID(ctx, periodoID)
	if err != nil || p == nil {
		return ""
	}
	return p.SedeID()
}

// ListarAsignacionesEnAlcance lista las asignaciones del periodo visibles para el actor.
func (s *Service) ListarAsignacionesEnAlcance(ctx context.Context, actor ContextoActor, periodoID string) ([]domainAca.Asignacion, error) {
	lista, err := s.asignacionRepo.ListByPeriodoID(ctx, periodoID)
	if err != nil || actor.alcanceEfectivo() == nil {
		return lista, err
	}
	sede := s.sedeDePeriodo(ctx, periodoID)
	visibles := make([]domainAca.Asignacion, 0, len(lista))
	for i := range lista {
		if a := lista[i]; actor.permiteAsignacion(&a, sede) {
			visibles = append(visibles, a)
		}
	}
	return visibles, nil
}

// ListarFacultadesEnAlcance lista las facultades que el actor puede ver.
func (s *Service) ListarFacultadesEnAlcance(ctx context.Context, actor ContextoActor, sedeID string) ([]*domainAca.Facultad, error) {
	lista, err := s.estructuraRepo.ListFacultades(ctx, sedeID)
	if err != nil || !actor.porAmbito() {
		return lista, err
	}
	visibles := make([]*domainAca.Facultad, 0, len(lista))
	for _, f := range lista {
		if actor.permiteFacultad(f.ID(), f.SedeID()) {
			visibles = append(visibles, f)
		}
	}
	return visibles, nil
}

// ListarProgramasEnAlcance lista los programas de las facultades visibles para el actor.
// Pedir explícitamente una facultad fuera del alcance devuelve 403 (CA-010).
func (s *Service) ListarProgramasEnAlcance(ctx context.Context, actor ContextoActor, facultadID string) ([]*domainAca.Programa, error) {
	if !actor.porAmbito() {
		return s.estructuraRepo.ListProgramas(ctx, facultadID)
	}
	facultades, err := s.ListarFacultadesEnAlcance(ctx, actor, "")
	if err != nil {
		return nil, err
	}
	permitidas := make(map[string]bool, len(facultades))
	for _, f := range facultades {
		permitidas[f.ID()] = true
	}
	if facultadID != "" && !permitidas[facultadID] {
		return nil, ErrFueraDeAmbitoFacultad
	}
	lista, err := s.estructuraRepo.ListProgramas(ctx, facultadID)
	if err != nil {
		return nil, err
	}
	visibles := make([]*domainAca.Programa, 0, len(lista))
	for _, p := range lista {
		if permitidas[p.FacultadID()] {
			visibles = append(visibles, p)
		}
	}
	return visibles, nil
}
