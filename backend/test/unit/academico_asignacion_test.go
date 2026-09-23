package unit_test

import (
	"context"
	"strings"
	"testing"
	"time"

	domainAca "github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/domain/geo"
	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/domain/shared"
	applog "github.com/siaa/backend/internal/platform/log"
	usecaseAca "github.com/siaa/backend/internal/usecase/academico"
)

type mockAsignacionRepo struct {
	asignaciones map[string]domainAca.Asignacion
}

func newMockAsignacionRepo() *mockAsignacionRepo {
	return &mockAsignacionRepo{asignaciones: make(map[string]domainAca.Asignacion)}
}

func (m *mockAsignacionRepo) Create(ctx context.Context, a *domainAca.Asignacion) error {
	m.asignaciones[a.ID()] = *a
	return nil
}

func (m *mockAsignacionRepo) Update(ctx context.Context, a *domainAca.Asignacion) error {
	m.asignaciones[a.ID()] = *a
	return nil
}

func (m *mockAsignacionRepo) GetByID(ctx context.Context, id string) (*domainAca.Asignacion, error) {
	a, ok := m.asignaciones[id]
	if !ok || a.Borrado() {
		return nil, nil
	}
	return &a, nil
}

func (m *mockAsignacionRepo) ListByPeriodoID(ctx context.Context, periodoID string) ([]domainAca.Asignacion, error) {
	var list []domainAca.Asignacion
	for _, a := range m.asignaciones {
		if !a.Borrado() && a.PeriodoID() == periodoID {
			list = append(list, a)
		}
	}
	return list, nil
}

func (m *mockAsignacionRepo) ListByDocenteID(ctx context.Context, periodoID, docenteID string) ([]domainAca.Asignacion, error) {
	var list []domainAca.Asignacion
	for _, a := range m.asignaciones {
		if !a.Borrado() && (periodoID == "" || a.PeriodoID() == periodoID) && a.ContieneDocente(docenteID) {
			list = append(list, a)
		}
	}
	return list, nil
}

func (m *mockAsignacionRepo) ListByEspacioID(ctx context.Context, periodoID, espacioID string) ([]domainAca.Asignacion, error) {
	var list []domainAca.Asignacion
	for _, a := range m.asignaciones {
		if !a.Borrado() && (periodoID == "" || a.PeriodoID() == periodoID) && a.EspacioID() == espacioID {
			list = append(list, a)
		}
	}
	return list, nil
}

func (m *mockAsignacionRepo) DeleteLogico(ctx context.Context, id string) error {
	if a, ok := m.asignaciones[id]; ok {
		m.asignaciones[id] = *domainAca.ReconstituirAsignacion(
			a.ID(), a.PeriodoID(), a.DocenteIDs(), a.DocenteNombre(), a.GrupoID(),
			a.AsignaturaID(), a.FacultadID(), a.EspacioID(), a.EspacioNombre(),
			a.Franja(), a.Modalidad(), a.ExentaGeoespacial(), a.ParametrosOverride(),
			a.Estado(), a.FechaInicio(), a.FechaFin(), a.CodigoExterno(), true,
			a.CreadoEn(), time.Now(),
		)
	}
	return nil
}

func TestUSACA02_FranjaHorariaValidaciones(t *testing.T) {
	_, _, err := domainAca.NuevaFranjaHoraria(1, "10:00", "08:00", "America/Bogota")
	if err == nil {
		t.Errorf("esperado error cuando horaFin <= horaInicio")
	}

	f, _, err := domainAca.NuevaFranjaHoraria(2, "08:00", "10:00", "")
	if err != nil {
		t.Fatalf("error inesperado: %v", err)
	}
	if f.ZonaHoraria() != "America/Bogota" {
		t.Errorf("esperado America/Bogota por defecto, obtenido: %s", f.ZonaHoraria())
	}

	_, advs, err := domainAca.NuevaFranjaHoraria(3, "08:00", "08:10", "America/Bogota")
	if err != nil {
		t.Fatalf("error: %v", err)
	}
	if len(advs) == 0 || !strings.Contains(advs[0], "15 minutos") {
		t.Errorf("esperada advertencia de duración < 15 min")
	}

	_, advsLarga, err := domainAca.NuevaFranjaHoraria(3, "07:00", "17:00", "America/Bogota")
	if err != nil {
		t.Fatalf("error: %v", err)
	}
	if len(advsLarga) == 0 || !strings.Contains(advsLarga[0], "8 horas") {
		t.Errorf("esperada advertencia de duración > 8 horas")
	}
}

func TestUSACA03_ColisionDocenteYAula(t *testing.T) {
	franjaLunes8a10, _, _ := domainAca.NuevaFranjaHoraria(1, "08:00", "10:00", "America/Bogota")
	franjaLunes9a11, _, _ := domainAca.NuevaFranjaHoraria(1, "09:00", "11:00", "America/Bogota")
	franjaLunes10a12, _, _ := domainAca.NuevaFranjaHoraria(1, "10:00", "12:00", "America/Bogota")
	franjaMartes8a10, _, _ := domainAca.NuevaFranjaHoraria(2, "08:00", "10:00", "America/Bogota")

	now := time.Now()
	fIni := time.Date(2026, 8, 1, 0, 0, 0, 0, time.UTC)
	fFin := time.Date(2026, 12, 1, 0, 0, 0, 0, time.UTC)

	asigBase, _ := domainAca.NuevaAsignacion(
		"asig-1", "per-1", []string{"docente-juan"}, "Juan Perez", "grupo-101",
		"asig-mat", "fac-ing", "aula-201", "Aula 201", franjaLunes8a10,
		domainAca.ModalidadPresencial, nil, fIni, fFin, nil, now,
	)
	existentes := []domainAca.Asignacion{*asigBase}

	// 1. AC-02: Colisión de docente solapado (Lunes 9-11)
	asigDocenteSolapado, _ := domainAca.NuevaAsignacion(
		"asig-2", "per-1", []string{"docente-juan"}, "Juan Perez", "grupo-102",
		"asig-fis", "fac-ing", "aula-305", "Aula 305", franjaLunes9a11,
		domainAca.ModalidadPresencial, nil, fIni, fFin, nil, now,
	)
	col := domainAca.DetectarColisiones(existentes, *asigDocenteSolapado)
	if col == nil || col.Tipo != domainAca.ColisionDocente {
		t.Fatalf("esperada colisión docente (AC-02), obtenido: %v", col)
	}

	// 2. AC-03: Colisión de aula solapada (Lunes 9-11)
	asigAulaSolapada, _ := domainAca.NuevaAsignacion(
		"asig-3", "per-1", []string{"docente-maria"}, "Maria Gomez", "grupo-103",
		"asig-quim", "fac-ing", "aula-201", "Aula 201", franjaLunes9a11,
		domainAca.ModalidadPresencial, nil, fIni, fFin, nil, now,
	)
	colAula := domainAca.DetectarColisiones(existentes, *asigAulaSolapada)
	if colAula == nil || colAula.Tipo != domainAca.ColisionAula {
		t.Fatalf("esperada colisión de aula (AC-03), obtenido: %v", colAula)
	}

	// 3. Caso no colisión: Franja contigua (Lunes 10 a 12)
	asigContigua, _ := domainAca.NuevaAsignacion(
		"asig-4", "per-1", []string{"docente-juan"}, "Juan Perez", "grupo-104",
		"asig-mat2", "fac-ing", "aula-201", "Aula 201", franjaLunes10a12,
		domainAca.ModalidadPresencial, nil, fIni, fFin, nil, now,
	)
	if colContigua := domainAca.DetectarColisiones(existentes, *asigContigua); colContigua != nil {
		t.Errorf("no debía colisionar en franja contigua 10:00: %v", colContigua)
	}

	// 4. Caso no colisión: Distinto día
	asigOtroDia, _ := domainAca.NuevaAsignacion(
		"asig-5", "per-1", []string{"docente-juan"}, "Juan Perez", "grupo-105",
		"asig-mat3", "fac-ing", "aula-201", "Aula 201", franjaMartes8a10,
		domainAca.ModalidadPresencial, nil, fIni, fFin, nil, now,
	)
	if colOtroDia := domainAca.DetectarColisiones(existentes, *asigOtroDia); colOtroDia != nil {
		t.Errorf("no debía colisionar en día diferente: %v", colOtroDia)
	}
}

func TestUSACA03_EspacioSinGeometriaYModalidadVirtual(t *testing.T) {
	now := time.Now()
	clk := shared.NewFakeClock(now)
	logger := applog.New(applog.LevelDebug, nil)

	periodoRepo := newMockPeriodoRepo()
	asignacionRepo := newMockAsignacionRepo()
	espacioRepo := newMockEspacioRepo()

	p, _ := domainAca.NuevoPeriodo(
		"per-1", "2026-2", "Periodo 2",
		time.Date(2026, 8, 1, 0, 0, 0, 0, time.UTC),
		time.Date(2026, 12, 1, 0, 0, 0, 0, time.UTC),
		domainAca.EstadoActivo, "sede-1", nil, now,
	)
	_ = periodoRepo.Create(context.Background(), p)

	espacioSinGeom := &geo.Espacio{ID: "aula-vacia", Nombre: "Aula Sin Poligono", Geometria: nil}
	_ = espacioRepo.Create(context.Background(), espacioSinGeom)

	svc := usecaseAca.NewService(periodoRepo, nil, asignacionRepo, nil, nil, espacioRepo, nil, clk, logger)
	actor := usecaseAca.ContextoActor{UsuarioID: "admin-1", Rol: string(rbac.RolAdminInst)}

	// AC-04: Asignación sobre aula sin geometría emite advertencia visible
	res, err := svc.CrearAsignacion(context.Background(), actor, usecaseAca.CrearAsignacionCmd{
		PeriodoID:     "per-1",
		DocenteIDs:    []string{"doc-1"},
		DocenteNombre: "Profesor Prueba",
		GrupoID:       "grp-1",
		EspacioID:     "aula-vacia",
		DiaSemana:     1,
		HoraInicio:    "08:00",
		HoraFin:       "10:00",
		Modalidad:     domainAca.ModalidadPresencial,
	})
	if err != nil {
		t.Fatalf("error inesperado: %v", err)
	}

	tieneAdvGeom := false
	for _, adv := range res.Advertencias {
		if strings.Contains(adv, "no tiene geometría") {
			tieneAdvGeom = true
			break
		}
	}
	if !tieneAdvGeom {
		t.Errorf("esperada advertencia de espacio sin geometría (AC-04)")
	}

	// AC-06: Modalidad virtual queda exenta de validación geoespacial
	resVirtual, err := svc.CrearAsignacion(context.Background(), actor, usecaseAca.CrearAsignacionCmd{
		PeriodoID:     "per-1",
		DocenteIDs:    []string{"doc-2"},
		DocenteNombre: "Profesor Virtual",
		GrupoID:       "grp-virtual",
		DiaSemana:     2,
		HoraInicio:    "08:00",
		HoraFin:       "10:00",
		Modalidad:     domainAca.ModalidadVirtual,
	})
	if err != nil {
		t.Fatalf("error en asignación virtual: %v", err)
	}
	if !resVirtual.Asignacion.ExentaGeoespacial() {
		t.Errorf("asignación virtual debe estar exenta de validación geoespacial (AC-06)")
	}
}

func TestUSACA03_ABACCoordinador(t *testing.T) {
	now := time.Now()
	clk := shared.NewFakeClock(now)
	logger := applog.New(applog.LevelDebug, nil)

	periodoRepo := newMockPeriodoRepo()
	asignacionRepo := newMockAsignacionRepo()
	espacioRepo := newMockEspacioRepo()

	p, _ := domainAca.NuevoPeriodo(
		"per-1", "2026-2", "Periodo 2",
		time.Date(2026, 8, 1, 0, 0, 0, 0, time.UTC),
		time.Date(2026, 12, 1, 0, 0, 0, 0, time.UTC),
		domainAca.EstadoActivo, "sede-1", nil, now,
	)
	_ = periodoRepo.Create(context.Background(), p)

	svc := usecaseAca.NewService(periodoRepo, nil, asignacionRepo, nil, nil, espacioRepo, nil, clk, logger)
	coordActor := usecaseAca.ContextoActor{
		UsuarioID: "coord-1",
		Rol:       string(rbac.RolCoordinador),
		Scopes:    []rbac.Scope{{Tipo: rbac.ScopeFacultad, ID: "fac-ingenieria"}},
	}

	// Intento de crear asignación en 'fac-medicina' -> 403 / ErrFueraDeAmbitoFacultad (AC-07)
	_, err := svc.CrearAsignacion(context.Background(), coordActor, usecaseAca.CrearAsignacionCmd{
		PeriodoID:     "per-1",
		DocenteIDs:    []string{"doc-1"},
		DocenteNombre: "Profesor",
		GrupoID:       "grp-1",
		FacultadID:    "fac-medicina",
		DiaSemana:     3,
		HoraInicio:    "08:00",
		HoraFin:       "10:00",
		Modalidad:     domainAca.ModalidadVirtual,
	})
	if err == nil || !strings.Contains(err.Error(), "alcance sobre la facultad") {
		t.Errorf("esperado error de alcance ABAC (AC-07), obtenido: %v", err)
	}

	// Intento dentro de 'fac-ingenieria' -> Permitido
	_, err = svc.CrearAsignacion(context.Background(), coordActor, usecaseAca.CrearAsignacionCmd{
		PeriodoID:     "per-1",
		DocenteIDs:    []string{"doc-1"},
		DocenteNombre: "Profesor",
		GrupoID:       "grp-1",
		FacultadID:    "fac-ingenieria",
		DiaSemana:     3,
		HoraInicio:    "08:00",
		HoraFin:       "10:00",
		Modalidad:     domainAca.ModalidadVirtual,
	})
	if err != nil {
		t.Errorf("no debía fallar asignación dentro de su facultad: %v", err)
	}
}
