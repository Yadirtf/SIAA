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

// ─────────────────────────────────────────────────────────────
// Mocks en memoria para el módulo Académico
// ─────────────────────────────────────────────────────────────

type mockPeriodoRepo struct {
	periodos map[string]*domainAca.Periodo
}

func newMockPeriodoRepo() *mockPeriodoRepo {
	return &mockPeriodoRepo{periodos: make(map[string]*domainAca.Periodo)}
}

func (m *mockPeriodoRepo) Create(ctx context.Context, p *domainAca.Periodo) error {
	id := p.ID()
	if id == "" {
		id = shared.NewID()
		p = domainAca.ReconstituirPeriodo(id, p.Codigo(), p.Nombre(), p.FechaInicio(), p.FechaFin(), p.Estado(), p.SedeID(), p.CodigoExterno(), p.Borrado(), p.CreadoEn(), p.ActualizadoEn())
	}
	m.periodos[id] = p
	return nil
}

func (m *mockPeriodoRepo) Update(ctx context.Context, p *domainAca.Periodo) error {
	m.periodos[p.ID()] = p
	return nil
}

func (m *mockPeriodoRepo) GetByID(ctx context.Context, id string) (*domainAca.Periodo, error) {
	p, ok := m.periodos[id]
	if !ok || p.Borrado() {
		return nil, nil
	}
	return p, nil
}

func (m *mockPeriodoRepo) ListAll(ctx context.Context) ([]*domainAca.Periodo, error) {
	var list []*domainAca.Periodo
	for _, p := range m.periodos {
		if !p.Borrado() {
			list = append(list, p)
		}
	}
	return list, nil
}

func (m *mockPeriodoRepo) ListBySedeID(ctx context.Context, sedeID string) ([]*domainAca.Periodo, error) {
	var list []*domainAca.Periodo
	for _, p := range m.periodos {
		if !p.Borrado() && p.SedeID() == sedeID {
			list = append(list, p)
		}
	}
	return list, nil
}

func (m *mockPeriodoRepo) FindActivoSolapado(ctx context.Context, sedeID string, inicio, fin time.Time, excluirID string) (*domainAca.Periodo, error) {
	for _, p := range m.periodos {
		if p.Borrado() || (excluirID != "" && p.ID() == excluirID) {
			continue
		}
		if p.Estado() == domainAca.EstadoActivo && p.SedeID() == sedeID {
			if p.FechaInicio().Before(fin) && inicio.Before(p.FechaFin()) {
				return p, nil
			}
		}
	}
	return nil, nil
}

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
		// Marcar borrado
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

type mockExcepcionRepo struct {
	excepciones map[string]*domainAca.CalendarioExcepcion
}

func newMockExcepcionRepo() *mockExcepcionRepo {
	return &mockExcepcionRepo{excepciones: make(map[string]*domainAca.CalendarioExcepcion)}
}

func (m *mockExcepcionRepo) Create(ctx context.Context, e *domainAca.CalendarioExcepcion) error {
	m.excepciones[e.ID()] = e
	return nil
}

func (m *mockExcepcionRepo) Update(ctx context.Context, e *domainAca.CalendarioExcepcion) error {
	m.excepciones[e.ID()] = e
	return nil
}

func (m *mockExcepcionRepo) GetByID(ctx context.Context, id string) (*domainAca.CalendarioExcepcion, error) {
	e, ok := m.excepciones[id]
	if !ok || e.Borrado() {
		return nil, nil
	}
	return e, nil
}

func (m *mockExcepcionRepo) ListAll(ctx context.Context) ([]*domainAca.CalendarioExcepcion, error) {
	var list []*domainAca.CalendarioExcepcion
	for _, e := range m.excepciones {
		if !e.Borrado() {
			list = append(list, e)
		}
	}
	return list, nil
}

func (m *mockExcepcionRepo) ListByRango(ctx context.Context, inicio, fin time.Time) ([]*domainAca.CalendarioExcepcion, error) {
	var list []*domainAca.CalendarioExcepcion
	for _, e := range m.excepciones {
		if !e.Borrado() && !e.FechaFin().Before(inicio) && !e.FechaInicio().After(fin) {
			list = append(list, e)
		}
	}
	return list, nil
}

func (m *mockExcepcionRepo) DeleteLogico(ctx context.Context, id string) error {
	if e, ok := m.excepciones[id]; ok {
		m.excepciones[id] = domainAca.ReconstituirCalendarioExcepcion(
			e.ID(), e.Nombre(), e.Tipo(), e.Ambito(), e.AmbitoID(),
			e.FechaInicio(), e.FechaFin(), true, e.CreadoEn(), time.Now(),
		)
	}
	return nil
}

// ─────────────────────────────────────────────────────────────
// Tests de US-ACA-01: Periodos y Estructura
// ─────────────────────────────────────────────────────────────

func TestUSACA01_PeriodosYEstados(t *testing.T) {
	now := time.Date(2026, 9, 22, 12, 0, 0, 0, time.UTC)
	clk := shared.NewFakeClock(now)
	logger := applog.New(applog.LevelDebug, nil)

	periodoRepo := newMockPeriodoRepo()
	asignacionRepo := newMockAsignacionRepo()
	excepcionRepo := newMockExcepcionRepo()
	espacioRepo := newMockEspacioRepo()

	svc := usecaseAca.NewService(
		periodoRepo,
		nil,
		asignacionRepo,
		excepcionRepo,
		nil,
		espacioRepo,
		nil,
		clk,
		logger,
	)

	ctx := context.Background()
	adminActor := usecaseAca.ContextoActor{UsuarioID: "admin-1", Rol: string(rbac.RolAdminInst)}

	// AC-01: Crear periodo válido
	res, err := svc.CrearPeriodo(ctx, adminActor, usecaseAca.CrearPeriodoCmd{
		Codigo:      "2026-2",
		Nombre:      "Periodo 2026-II",
		FechaInicio: time.Date(2026, 8, 1, 0, 0, 0, 0, time.UTC),
		FechaFin:    time.Date(2026, 12, 15, 23, 59, 59, 0, time.UTC),
		Estado:      domainAca.EstadoActivo,
		SedeID:      "sede-principal",
	})
	if err != nil {
		t.Fatalf("error inesperado al crear periodo: %v", err)
	}
	if res.Periodo.Estado() != domainAca.EstadoActivo {
		t.Errorf("esperado estado ACTIVO, obtenido %s", res.Periodo.Estado())
	}

	// AC-03: Advertencia si se activa un segundo periodo solapado en la misma sede
	res2, err := svc.CrearPeriodo(ctx, adminActor, usecaseAca.CrearPeriodoCmd{
		Codigo:      "2026-2-INT",
		Nombre:      "Intersemestral 2026",
		FechaInicio: time.Date(2026, 10, 1, 0, 0, 0, 0, time.UTC),
		FechaFin:    time.Date(2026, 11, 30, 23, 59, 59, 0, time.UTC),
		Estado:      domainAca.EstadoActivo,
		SedeID:      "sede-principal",
	})
	if err != nil {
		t.Fatalf("error al crear segundo periodo: %v", err)
	}
	if len(res2.Advertencias) == 0 {
		t.Errorf("esperada advertencia de solapamiento de periodo activo (AC-03)")
	}

	// AC-02: Rechazar modificaciones sobre periodo cerrado
	pCerrado, _ := domainAca.NuevoPeriodo(
		"per-cerrado",
		"2026-1",
		"Periodo Cerrado",
		time.Date(2026, 1, 15, 0, 0, 0, 0, time.UTC),
		time.Date(2026, 6, 15, 0, 0, 0, 0, time.UTC),
		domainAca.EstadoCerrado,
		"sede-principal",
		nil,
		now,
	)
	_ = periodoRepo.Create(ctx, pCerrado)

	_, err = svc.ActualizarPeriodo(ctx, adminActor, "per-cerrado", usecaseAca.CrearPeriodoCmd{
		Codigo:      "2026-1-MODIF",
		Nombre:      "Intento Modificar",
		FechaInicio: time.Date(2026, 1, 15, 0, 0, 0, 0, time.UTC),
		FechaFin:    time.Date(2026, 6, 15, 0, 0, 0, 0, time.UTC),
		Estado:      domainAca.EstadoActivo,
	})
	if err == nil || !strings.Contains(err.Error(), "periodo cerrado") {
		t.Errorf("esperado rechazo por periodo cerrado (AC-02), obtenido: %v", err)
	}
}

// ─────────────────────────────────────────────────────────────
// Tests de US-ACA-02: Franjas Horarias
// ─────────────────────────────────────────────────────────────

func TestUSACA02_FranjaHorariaValidaciones(t *testing.T) {
	// AC-02: Hora de fin menor o igual a inicio
	_, _, err := domainAca.NuevaFranjaHoraria(1, "10:00", "08:00", "America/Bogota")
	if err == nil {
		t.Errorf("esperado error cuando horaFin <= horaInicio")
	}

	// AC-03: Zona horaria default
	f, _, err := domainAca.NuevaFranjaHoraria(2, "08:00", "10:00", "")
	if err != nil {
		t.Fatalf("error inesperado: %v", err)
	}
	if f.ZonaHoraria() != "America/Bogota" {
		t.Errorf("esperado America/Bogota por defecto, obtenido: %s", f.ZonaHoraria())
	}

	// AC-04: Advertencia duración menor a 15 min
	_, advs, err := domainAca.NuevaFranjaHoraria(3, "08:00", "08:10", "America/Bogota")
	if err != nil {
		t.Fatalf("error: %v", err)
	}
	if len(advs) == 0 || !strings.Contains(advs[0], "15 minutos") {
		t.Errorf("esperada advertencia de duración < 15 min")
	}

	// AC-04: Advertencia duración mayor a 8 horas
	_, advsLarga, err := domainAca.NuevaFranjaHoraria(3, "07:00", "17:00", "America/Bogota")
	if err != nil {
		t.Fatalf("error: %v", err)
	}
	if len(advsLarga) == 0 || !strings.Contains(advsLarga[0], "8 horas") {
		t.Errorf("esperada advertencia de duración > 8 horas")
	}
}

// ─────────────────────────────────────────────────────────────
// Tests de US-ACA-03: Detección de Colisiones en Asignaciones
// ─────────────────────────────────────────────────────────────

func TestUSACA03_ColisionDocenteYAula(t *testing.T) {
	franjaLunes8a10, _, _ := domainAca.NuevaFranjaHoraria(1, "08:00", "10:00", "America/Bogota")
	franjaLunes9a11, _, _ := domainAca.NuevaFranjaHoraria(1, "09:00", "11:00", "America/Bogota")  // Solapada
	franjaLunes10a12, _, _ := domainAca.NuevaFranjaHoraria(1, "10:00", "12:00", "America/Bogota") // Adyacente (no solapada)
	franjaMartes8a10, _, _ := domainAca.NuevaFranjaHoraria(2, "08:00", "10:00", "America/Bogota") // Otro día

	now := time.Now()
	fIni := time.Date(2026, 8, 1, 0, 0, 0, 0, time.UTC)
	fFin := time.Date(2026, 12, 1, 0, 0, 0, 0, time.UTC)

	asigBase, _ := domainAca.NuevaAsignacion(
		"asig-1",
		"per-1",
		[]string{"docente-juan"},
		"Juan Perez",
		"grupo-101",
		"asig-mat",
		"fac-ing",
		"aula-201",
		"Aula 201",
		franjaLunes8a10,
		domainAca.ModalidadPresencial,
		nil,
		fIni,
		fFin,
		nil,
		now,
	)

	existentes := []domainAca.Asignacion{*asigBase}

	// 1. AC-02: Colisión de docente solapado (Lunes 9-11)
	asigDocenteSolapado, _ := domainAca.NuevaAsignacion(
		"asig-2",
		"per-1",
		[]string{"docente-juan"}, // Mismo docente
		"Juan Perez",
		"grupo-102",
		"asig-fis",
		"fac-ing",
		"aula-305", // Aula distinta
		"Aula 305",
		franjaLunes9a11,
		domainAca.ModalidadPresencial,
		nil,
		fIni,
		fFin,
		nil,
		now,
	)
	col := domainAca.DetectarColisiones(existentes, *asigDocenteSolapado)
	if col == nil || col.Tipo != domainAca.ColisionDocente {
		t.Fatalf("esperada colisión docente (AC-02), obtenido: %v", col)
	}

	// 2. AC-03: Colisión de aula solapada (Lunes 9-11)
	asigAulaSolapada, _ := domainAca.NuevaAsignacion(
		"asig-3",
		"per-1",
		[]string{"docente-maria"}, // Docente distinto
		"Maria Gomez",
		"grupo-103",
		"asig-quim",
		"fac-ing",
		"aula-201", // Misma aula
		"Aula 201",
		franjaLunes9a11,
		domainAca.ModalidadPresencial,
		nil,
		fIni,
		fFin,
		nil,
		now,
	)
	colAula := domainAca.DetectarColisiones(existentes, *asigAulaSolapada)
	if colAula == nil || colAula.Tipo != domainAca.ColisionAula {
		t.Fatalf("esperada colisión de aula (AC-03), obtenido: %v", colAula)
	}

	// 3. Caso no colisión: Franja contigua (Lunes 10 a 12, arista adyacente sin solapamiento)
	asigContigua, _ := domainAca.NuevaAsignacion(
		"asig-4",
		"per-1",
		[]string{"docente-juan"},
		"Juan Perez",
		"grupo-104",
		"asig-mat2",
		"fac-ing",
		"aula-201",
		"Aula 201",
		franjaLunes10a12,
		domainAca.ModalidadPresencial,
		nil,
		fIni,
		fFin,
		nil,
		now,
	)
	colContigua := domainAca.DetectarColisiones(existentes, *asigContigua)
	if colContigua != nil {
		t.Errorf("no debía colisionar en franja contigua 10:00: %v", colContigua)
	}

	// 4. Caso no colisión: Mismo horario pero distinto día
	asigOtroDia, _ := domainAca.NuevaAsignacion(
		"asig-5",
		"per-1",
		[]string{"docente-juan"},
		"Juan Perez",
		"grupo-105",
		"asig-mat3",
		"fac-ing",
		"aula-201",
		"Aula 201",
		franjaMartes8a10,
		domainAca.ModalidadPresencial,
		nil,
		fIni,
		fFin,
		nil,
		now,
	)
	colOtroDia := domainAca.DetectarColisiones(existentes, *asigOtroDia)
	if colOtroDia != nil {
		t.Errorf("no debía colisionar en día diferente: %v", colOtroDia)
	}
}

// ─────────────────────────────────────────────────────────────
// Tests de US-ACA-03: Advertencia Geometría y Exención Virtual
// ─────────────────────────────────────────────────────────────

func TestUSACA03_EspacioSinGeometriaYModalidadVirtual(t *testing.T) {
	now := time.Now()
	clk := shared.NewFakeClock(now)
	logger := applog.New(applog.LevelDebug, nil)

	periodoRepo := newMockPeriodoRepo()
	asignacionRepo := newMockAsignacionRepo()
	espacioRepo := newMockEspacioRepo()

	p, _ := domainAca.NuevoPeriodo(
		"per-1",
		"2026-2",
		"Periodo 2",
		time.Date(2026, 8, 1, 0, 0, 0, 0, time.UTC),
		time.Date(2026, 12, 1, 0, 0, 0, 0, time.UTC),
		domainAca.EstadoActivo,
		"sede-1",
		nil,
		now,
	)
	_ = periodoRepo.Create(context.Background(), p)

	// Espacio SIN geometría cargada (AC-04)
	espacioSinGeom := &geo.Espacio{
		ID:        "aula-vacia",
		Nombre:    "Aula Sin Poligono",
		Geometria: nil,
	}
	_ = espacioRepo.Create(context.Background(), espacioSinGeom)

	svc := usecaseAca.NewService(
		periodoRepo,
		nil,
		asignacionRepo,
		nil,
		nil,
		espacioRepo,
		nil,
		clk,
		logger,
	)

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

// ─────────────────────────────────────────────────────────────
// Tests de US-ACA-03 AC-07: Control de Alcance ABAC para Coordinador
// ─────────────────────────────────────────────────────────────

func TestUSACA03_ABACCoordinador(t *testing.T) {
	now := time.Now()
	clk := shared.NewFakeClock(now)
	logger := applog.New(applog.LevelDebug, nil)

	periodoRepo := newMockPeriodoRepo()
	asignacionRepo := newMockAsignacionRepo()
	espacioRepo := newMockEspacioRepo()

	p, _ := domainAca.NuevoPeriodo(
		"per-1",
		"2026-2",
		"Periodo 2",
		time.Date(2026, 8, 1, 0, 0, 0, 0, time.UTC),
		time.Date(2026, 12, 1, 0, 0, 0, 0, time.UTC),
		domainAca.EstadoActivo,
		"sede-1",
		nil,
		now,
	)
	_ = periodoRepo.Create(context.Background(), p)

	svc := usecaseAca.NewService(
		periodoRepo,
		nil,
		asignacionRepo,
		nil,
		nil,
		espacioRepo,
		nil,
		clk,
		logger,
	)

	// Coordinador con ámbito exclusivo en 'fac-ingenieria'
	coordActor := usecaseAca.ContextoActor{
		UsuarioID: "coord-1",
		Rol:       string(rbac.RolCoordinador),
		Scopes: []rbac.Scope{
			{Tipo: rbac.ScopeFacultad, ID: "fac-ingenieria"},
		},
	}

	// Intento de crear asignación en 'fac-medicina' -> 403 / ErrFueraDeAmbitoFacultad (AC-07)
	_, err := svc.CrearAsignacion(context.Background(), coordActor, usecaseAca.CrearAsignacionCmd{
		PeriodoID:     "per-1",
		DocenteIDs:    []string{"doc-1"},
		DocenteNombre: "Profesor",
		GrupoID:       "grp-1",
		FacultadID:    "fac-medicina", // Fuera de su ámbito
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
		FacultadID:    "fac-ingenieria", // En su ámbito
		DiaSemana:     3,
		HoraInicio:    "08:00",
		HoraFin:       "10:00",
		Modalidad:     domainAca.ModalidadVirtual,
	})
	if err != nil {
		t.Errorf("no debía fallar asignación dentro de su facultad: %v", err)
	}
}

// ─────────────────────────────────────────────────────────────
// Tests de US-ACA-04: Calendario de Excepciones y Ámbitos
// ─────────────────────────────────────────────────────────────

func TestUSACA04_CalendarioExcepcionesAmbitos(t *testing.T) {
	now := time.Now()

	// Excepción global: Lunes festivo
	festivoGlobal, err := domainAca.NuevaCalendarioExcepcion(
		"exc-1",
		"Día de la Raza",
		domainAca.ExcepcionFestivo,
		domainAca.AmbitoGlobal,
		"",
		time.Date(2026, 10, 12, 0, 0, 0, 0, time.UTC),
		time.Date(2026, 10, 12, 23, 59, 59, 0, time.UTC),
		now,
	)
	if err != nil {
		t.Fatalf("error: %v", err)
	}

	// Excepción por facultad: Semana cultural de Ingeniería (AC-05)
	culturalIng, err := domainAca.NuevaCalendarioExcepcion(
		"exc-2",
		"Semana de Ingeniería",
		domainAca.ExcepcionJornadaInstitucional,
		domainAca.AmbitoFacultad,
		"fac-ingenieria",
		time.Date(2026, 10, 19, 0, 0, 0, 0, time.UTC),
		time.Date(2026, 10, 23, 23, 59, 59, 0, time.UTC),
		now,
	)
	if err != nil {
		t.Fatalf("error: %v", err)
	}

	fechaFestivo := time.Date(2026, 10, 12, 8, 0, 0, 0, time.UTC)
	fechaCultural := time.Date(2026, 10, 20, 10, 0, 0, 0, time.UTC)
	fechaOrdinaria := time.Date(2026, 10, 15, 8, 0, 0, 0, time.UTC)

	// Global afecta a cualquier facultad/sede (AC-01, AC-02)
	if !festivoGlobal.AfectaFechaYAmbito(fechaFestivo, "sede-cualquiera", "fac-cualquiera") {
		t.Errorf("festivo global debe afectar a cualquier sede/facultad")
	}

	// AC-05: Ámbito de facultad solo afecta a sesiones de esa facultad
	if !culturalIng.AfectaFechaYAmbito(fechaCultural, "sede-1", "fac-ingenieria") {
		t.Errorf("excepción de facultad debe afectar a Ingeniería")
	}
	if culturalIng.AfectaFechaYAmbito(fechaCultural, "sede-1", "fac-medicina") {
		t.Errorf("excepción de facultad NO debe afectar a Medicina (AC-05)")
	}

	// Fecha ordinaria no es afectada
	if festivoGlobal.AfectaFechaYAmbito(fechaOrdinaria, "sede-1", "fac-ingenieria") {
		t.Errorf("fecha ordinaria no debe estar afectada")
	}
}
