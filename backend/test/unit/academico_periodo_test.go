package unit_test

import (
	"context"
	"strings"
	"testing"
	"time"

	domainAca "github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/domain/shared"
	applog "github.com/siaa/backend/internal/platform/log"
	usecaseAca "github.com/siaa/backend/internal/usecase/academico"
)

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

// ─────────────────────────────────────────────────────────────
// Tests de US-ACA-01: Periodos y Estados
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
