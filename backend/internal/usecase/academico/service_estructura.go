package academico

import (
	"context"

	domainAca "github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/domain/shared"
)

// ─────────────────────────────────────────────────────────────
// 2. GESTIÓN DE ESTRUCTURA ACADÉMICA (US-ACA-01 AC-04, AC-05)
// ─────────────────────────────────────────────────────────────

// Facultades
func (s *Service) CrearFacultad(ctx context.Context, actor ContextoActor, codigo, nombre, sedeID string, codigoExterno *string) (*domainAca.Facultad, error) {
	f, err := domainAca.NuevaFacultad(shared.NewID(), codigo, nombre, sedeID, codigoExterno, s.clk.Now())
	if err != nil {
		return nil, err
	}
	if err := s.estructuraRepo.CreateFacultad(ctx, f); err != nil {
		return nil, err
	}
	return f, nil
}

func (s *Service) ListarFacultades(ctx context.Context, sedeID string) ([]*domainAca.Facultad, error) {
	return s.estructuraRepo.ListFacultades(ctx, sedeID)
}

func (s *Service) EliminarFacultad(ctx context.Context, actor ContextoActor, id string) error {
	// Borrado lógico con trazabilidad (US-ACA-01 AC-05)
	return s.estructuraRepo.DeleteFacultadLogico(ctx, id)
}

// Programas
func (s *Service) CrearPrograma(ctx context.Context, actor ContextoActor, codigo, nombre, facultadID string, codigoExterno *string) (*domainAca.Programa, error) {
	fac, err := s.estructuraRepo.GetFacultadByID(ctx, facultadID)
	if err != nil || fac == nil {
		return nil, ErrFacultadNoEncontrada
	}
	p, err := domainAca.NuevoPrograma(shared.NewID(), codigo, nombre, facultadID, codigoExterno, s.clk.Now())
	if err != nil {
		return nil, err
	}
	if err := s.estructuraRepo.CreatePrograma(ctx, p); err != nil {
		return nil, err
	}
	return p, nil
}

func (s *Service) ListarProgramas(ctx context.Context, facultadID string) ([]*domainAca.Programa, error) {
	return s.estructuraRepo.ListProgramas(ctx, facultadID)
}

func (s *Service) EliminarPrograma(ctx context.Context, actor ContextoActor, id string) error {
	return s.estructuraRepo.DeleteProgramaLogico(ctx, id)
}

// Asignaturas
func (s *Service) CrearAsignatura(ctx context.Context, actor ContextoActor, codigo, nombre, programaID string, creditos int, codigoExterno *string) (*domainAca.Asignatura, error) {
	prog, err := s.estructuraRepo.GetProgramaByID(ctx, programaID)
	if err != nil || prog == nil {
		return nil, ErrProgramaNoEncontrado
	}
	a, err := domainAca.NuevaAsignatura(shared.NewID(), codigo, nombre, programaID, creditos, codigoExterno, s.clk.Now())
	if err != nil {
		return nil, err
	}
	if err := s.estructuraRepo.CreateAsignatura(ctx, a); err != nil {
		return nil, err
	}
	return a, nil
}

func (s *Service) ListarAsignaturas(ctx context.Context, programaID string) ([]*domainAca.Asignatura, error) {
	return s.estructuraRepo.ListAsignaturas(ctx, programaID)
}

func (s *Service) EliminarAsignatura(ctx context.Context, actor ContextoActor, id string) error {
	return s.estructuraRepo.DeleteAsignaturaLogico(ctx, id)
}

// Grupos
func (s *Service) CrearGrupo(ctx context.Context, actor ContextoActor, numero, asignaturaID, periodoID string, cupo int, codigoExterno *string) (*domainAca.Grupo, error) {
	asig, err := s.estructuraRepo.GetAsignaturaByID(ctx, asignaturaID)
	if err != nil || asig == nil {
		return nil, ErrAsignaturaNoEncontrada
	}
	per, err := s.periodoRepo.GetByID(ctx, periodoID)
	if err != nil || per == nil {
		return nil, ErrPeriodoNoEncontrado
	}
	if err := per.PuedeModificar(); err != nil {
		return nil, err
	}
	g, err := domainAca.NuevoGrupo(shared.NewID(), numero, asignaturaID, periodoID, cupo, codigoExterno, s.clk.Now())
	if err != nil {
		return nil, err
	}
	if err := s.estructuraRepo.CreateGrupo(ctx, g); err != nil {
		return nil, err
	}
	return g, nil
}

func (s *Service) ListarGrupos(ctx context.Context, asignaturaID, periodoID string) ([]*domainAca.Grupo, error) {
	return s.estructuraRepo.ListGrupos(ctx, asignaturaID, periodoID)
}

func (s *Service) EliminarGrupo(ctx context.Context, actor ContextoActor, id string) error {
	return s.estructuraRepo.DeleteGrupoLogico(ctx, id)
}
