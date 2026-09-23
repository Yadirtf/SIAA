package unit_test

import (
	"context"
	"testing"
	"time"

	domainAca "github.com/siaa/backend/internal/domain/academico"
)

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
