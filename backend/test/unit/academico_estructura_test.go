package unit_test

import (
	"context"
	"testing"
	"time"

	domainAca "github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/domain/shared"
	applog "github.com/siaa/backend/internal/platform/log"
	usecaseAca "github.com/siaa/backend/internal/usecase/academico"
)

type mockEstructuraRepo struct {
	facultades  map[string]*domainAca.Facultad
	programas   map[string]*domainAca.Programa
	asignaturas map[string]*domainAca.Asignatura
	grupos      map[string]*domainAca.Grupo
}

func newMockEstructuraRepo() *mockEstructuraRepo {
	return &mockEstructuraRepo{
		facultades:  make(map[string]*domainAca.Facultad),
		programas:   make(map[string]*domainAca.Programa),
		asignaturas: make(map[string]*domainAca.Asignatura),
		grupos:      make(map[string]*domainAca.Grupo),
	}
}

func (m *mockEstructuraRepo) CreateFacultad(ctx context.Context, f *domainAca.Facultad) error {
	m.facultades[f.ID()] = f
	return nil
}
func (m *mockEstructuraRepo) UpdateFacultad(ctx context.Context, f *domainAca.Facultad) error {
	m.facultades[f.ID()] = f
	return nil
}
func (m *mockEstructuraRepo) GetFacultadByID(ctx context.Context, id string) (*domainAca.Facultad, error) {
	f, ok := m.facultades[id]
	if !ok || f.Borrado() {
		return nil, nil
	}
	return f, nil
}
func (m *mockEstructuraRepo) ListFacultades(ctx context.Context, sedeID string) ([]*domainAca.Facultad, error) {
	var list []*domainAca.Facultad
	for _, f := range m.facultades {
		if !f.Borrado() && (sedeID == "" || f.SedeID() == sedeID) {
			list = append(list, f)
		}
	}
	return list, nil
}
func (m *mockEstructuraRepo) DeleteFacultadLogico(ctx context.Context, id string) error {
	if f, ok := m.facultades[id]; ok {
		m.facultades[id] = domainAca.ReconstituirFacultad(f.ID(), f.Codigo(), f.Nombre(), f.SedeID(), f.CodigoExterno(), true, f.CreadoEn(), time.Now())
	}
	return nil
}

func (m *mockEstructuraRepo) CreatePrograma(ctx context.Context, p *domainAca.Programa) error {
	m.programas[p.ID()] = p
	return nil
}
func (m *mockEstructuraRepo) UpdatePrograma(ctx context.Context, p *domainAca.Programa) error {
	m.programas[p.ID()] = p
	return nil
}
func (m *mockEstructuraRepo) GetProgramaByID(ctx context.Context, id string) (*domainAca.Programa, error) {
	p, ok := m.programas[id]
	if !ok || p.Borrado() {
		return nil, nil
	}
	return p, nil
}
func (m *mockEstructuraRepo) ListProgramas(ctx context.Context, facultadID string) ([]*domainAca.Programa, error) {
	var list []*domainAca.Programa
	for _, p := range m.programas {
		if !p.Borrado() && (facultadID == "" || p.FacultadID() == facultadID) {
			list = append(list, p)
		}
	}
	return list, nil
}
func (m *mockEstructuraRepo) DeleteProgramaLogico(ctx context.Context, id string) error {
	if p, ok := m.programas[id]; ok {
		m.programas[id] = domainAca.ReconstituirPrograma(p.ID(), p.Codigo(), p.Nombre(), p.FacultadID(), p.CodigoExterno(), true, p.CreadoEn(), time.Now())
	}
	return nil
}

func (m *mockEstructuraRepo) CreateAsignatura(ctx context.Context, a *domainAca.Asignatura) error {
	m.asignaturas[a.ID()] = a
	return nil
}
func (m *mockEstructuraRepo) UpdateAsignatura(ctx context.Context, a *domainAca.Asignatura) error {
	m.asignaturas[a.ID()] = a
	return nil
}
func (m *mockEstructuraRepo) GetAsignaturaByID(ctx context.Context, id string) (*domainAca.Asignatura, error) {
	a, ok := m.asignaturas[id]
	if !ok || a.Borrado() {
		return nil, nil
	}
	return a, nil
}
func (m *mockEstructuraRepo) ListAsignaturas(ctx context.Context, programaID string) ([]*domainAca.Asignatura, error) {
	var list []*domainAca.Asignatura
	for _, a := range m.asignaturas {
		if !a.Borrado() && (programaID == "" || a.ProgramaID() == programaID) {
			list = append(list, a)
		}
	}
	return list, nil
}
func (m *mockEstructuraRepo) DeleteAsignaturaLogico(ctx context.Context, id string) error {
	if a, ok := m.asignaturas[id]; ok {
		m.asignaturas[id] = domainAca.ReconstituirAsignatura(a.ID(), a.Codigo(), a.Nombre(), a.ProgramaID(), a.Creditos(), a.CodigoExterno(), true, a.CreadoEn(), time.Now())
	}
	return nil
}

func (m *mockEstructuraRepo) CreateGrupo(ctx context.Context, g *domainAca.Grupo) error {
	m.grupos[g.ID()] = g
	return nil
}
func (m *mockEstructuraRepo) UpdateGrupo(ctx context.Context, g *domainAca.Grupo) error {
	m.grupos[g.ID()] = g
	return nil
}
func (m *mockEstructuraRepo) GetGrupoByID(ctx context.Context, id string) (*domainAca.Grupo, error) {
	g, ok := m.grupos[id]
	if !ok || g.Borrado() {
		return nil, nil
	}
	return g, nil
}
func (m *mockEstructuraRepo) ListGrupos(ctx context.Context, asignaturaID, periodoID string) ([]*domainAca.Grupo, error) {
	var list []*domainAca.Grupo
	for _, g := range m.grupos {
		if !g.Borrado() && (asignaturaID == "" || g.AsignaturaID() == asignaturaID) && (periodoID == "" || g.PeriodoID() == periodoID) {
			list = append(list, g)
		}
	}
	return list, nil
}
func (m *mockEstructuraRepo) DeleteGrupoLogico(ctx context.Context, id string) error {
	if g, ok := m.grupos[id]; ok {
		m.grupos[id] = domainAca.ReconstituirGrupo(g.ID(), g.Numero(), g.AsignaturaID(), g.PeriodoID(), g.Cupo(), g.CodigoExterno(), true, g.CreadoEn(), time.Now())
	}
	return nil
}

// ─────────────────────────────────────────────────────────────
// Tests de US-ACA-01 AC-04 y AC-05: Jerarquía y Borrado Lógico
// ─────────────────────────────────────────────────────────────

func TestUSACA01_JerarquiaEstructuraYBorradoLogico(t *testing.T) {
	now := time.Now()
	clk := shared.NewFakeClock(now)
	logger := applog.New(applog.LevelDebug, nil)

	estRepo := newMockEstructuraRepo()
	periodoRepo := newMockPeriodoRepo()
	svc := usecaseAca.NewService(
		periodoRepo,
		estRepo,
		nil,
		nil,
		nil,
		nil,
		nil,
		clk,
		logger,
	)

	ctx := context.Background()
	admin := usecaseAca.ContextoActor{UsuarioID: "admin-1", Rol: string(rbac.RolAdminInst)}

	// 1. Crear Facultad
	extFac := "EXT-FAC-01"
	fac, err := svc.CrearFacultad(ctx, admin, "ING", "Facultad de Ingeniería", "sede-1", &extFac)
	if err != nil {
		t.Fatalf("error al crear facultad: %v", err)
	}
	if fac.Codigo() != "ING" || *fac.CodigoExterno() != extFac {
		t.Errorf("datos inconsistentes en facultad: %+v", fac)
	}

	// 2. Crear Programa
	extProg := "EXT-PROG-SYS"
	prog, err := svc.CrearPrograma(ctx, admin, "SIS", "Ingeniería de Sistemas", fac.ID(), &extProg)
	if err != nil {
		t.Fatalf("error al crear programa: %v", err)
	}
	if prog.FacultadID() != fac.ID() {
		t.Errorf("facultadID incorrecto en programa: %s", prog.FacultadID())
	}

	// 3. Crear Asignatura
	extAsig := "EXT-ASIG-PROG1"
	asig, err := svc.CrearAsignatura(ctx, admin, "SIS101", "Programación I", prog.ID(), 3, &extAsig)
	if err != nil {
		t.Fatalf("error al crear asignatura: %v", err)
	}

	// 4. Crear Periodo para el Grupo
	per, _ := domainAca.NuevoPeriodo("per-2026", "2026-2", "Periodo 2", now, now.Add(24*time.Hour*120), domainAca.EstadoActivo, "sede-1", nil, now)
	_ = periodoRepo.Create(ctx, per)

	// 5. Crear Grupo
	grp, err := svc.CrearGrupo(ctx, admin, "01", asig.ID(), per.ID(), 30, nil)
	if err != nil {
		t.Fatalf("error al crear grupo: %v", err)
	}
	if grp.AsignaturaID() != asig.ID() {
		t.Errorf("asignaturaId incorrecto en grupo: %s", grp.AsignaturaID())
	}

	// 6. Borrado lógico de Facultad
	err = svc.EliminarFacultad(ctx, admin, fac.ID())
	if err != nil {
		t.Fatalf("error al eliminar facultad: %v", err)
	}
	facs, _ := svc.ListarFacultades(ctx, "sede-1")
	if len(facs) != 0 {
		t.Errorf("la facultad debía estar borrada lógicamente, obtenidas: %d", len(facs))
	}
}
