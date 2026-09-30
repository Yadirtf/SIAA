package unit_test

import (
	"context"
	"time"

	domainAca "github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/repository"
)

// mockSesionRepo implementa repository.SesionRepository en memoria para tests.
type mockSesionRepo struct {
	sesiones map[string]*domainAca.Sesion
}

func newMockSesionRepo() *mockSesionRepo {
	return &mockSesionRepo{sesiones: make(map[string]*domainAca.Sesion)}
}

func (m *mockSesionRepo) Create(ctx context.Context, s *domainAca.Sesion) error {
	m.sesiones[s.ID()] = s
	return nil
}

func (m *mockSesionRepo) CreateBatch(ctx context.Context, sesiones []*domainAca.Sesion) (int, error) {
	c := 0
	for _, s := range sesiones {
		m.sesiones[s.ID()] = s
		c++
	}
	return c, nil
}

func (m *mockSesionRepo) FindByID(ctx context.Context, id string) (*domainAca.Sesion, error) {
	s, ok := m.sesiones[id]
	if !ok {
		return nil, nil
	}
	return s, nil
}

func (m *mockSesionRepo) FindByAsignacionFechaHora(ctx context.Context, asigID, fecha, hora string) (*domainAca.Sesion, error) {
	for _, s := range m.sesiones {
		if s.AsignacionID() == asigID && s.Fecha() == fecha && s.HoraInicio() == hora {
			return s, nil
		}
	}
	return nil, nil
}

func (m *mockSesionRepo) ListByPeriodo(ctx context.Context, periodoID string) ([]*domainAca.Sesion, error) {
	var res []*domainAca.Sesion
	for _, s := range m.sesiones {
		if s.PeriodoID() == periodoID {
			res = append(res, s)
		}
	}
	return res, nil
}

func (m *mockSesionRepo) ListByDocenteYFecha(ctx context.Context, docenteID, fecha string) ([]*domainAca.Sesion, error) {
	var res []*domainAca.Sesion
	for _, s := range m.sesiones {
		if s.Fecha() == fecha && s.TieneDocente(docenteID) {
			res = append(res, s)
		}
	}
	return res, nil
}

func (m *mockSesionRepo) List(ctx context.Context, filter repository.SesionFilter) ([]*domainAca.Sesion, error) {
	var res []*domainAca.Sesion
	for _, s := range m.sesiones {
		if filter.PeriodoID != "" && s.PeriodoID() != filter.PeriodoID {
			continue
		}
		if filter.AsignacionID != "" && s.AsignacionID() != filter.AsignacionID {
			continue
		}
		if filter.DocenteID != "" && !s.TieneDocente(filter.DocenteID) {
			continue
		}
		if filter.EspacioID != "" && s.EspacioID() != filter.EspacioID {
			continue
		}
		if filter.Fecha != "" && s.Fecha() != filter.Fecha {
			continue
		}
		if filter.Estado != nil && s.Estado() != *filter.Estado {
			continue
		}
		res = append(res, s)
	}
	return res, nil
}

func (m *mockSesionRepo) Update(ctx context.Context, s *domainAca.Sesion) error {
	m.sesiones[s.ID()] = s
	return nil
}

func (m *mockSesionRepo) CountSesionesFuturasPorEspacio(ctx context.Context, espacioID string, desde time.Time) (int64, error) {
	var count int64
	for _, s := range m.sesiones {
		if s.EspacioID() == espacioID && s.InicioProgramado().After(desde) {
			count++
		}
	}
	return count, nil
}
