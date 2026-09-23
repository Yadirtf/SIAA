package repository

import (
	"context"
	"time"

	domainAca "github.com/siaa/backend/internal/domain/academico"
)

// PeriodoRepository define los métodos de persistencia para periodos académicos.
type PeriodoRepository interface {
	Create(ctx context.Context, p *domainAca.Periodo) error
	Update(ctx context.Context, p *domainAca.Periodo) error
	GetByID(ctx context.Context, id string) (*domainAca.Periodo, error)
	ListAll(ctx context.Context) ([]*domainAca.Periodo, error)
	ListBySedeID(ctx context.Context, sedeID string) ([]*domainAca.Periodo, error)
	FindActivoSolapado(ctx context.Context, sedeID string, inicio, fin time.Time, excluirID string) (*domainAca.Periodo, error)
}

// EstructuraRepository define los métodos de persistencia para la jerarquía académica (US-ACA-01 AC-04, AC-05).
type EstructuraRepository interface {
	// Facultades
	CreateFacultad(ctx context.Context, f *domainAca.Facultad) error
	UpdateFacultad(ctx context.Context, f *domainAca.Facultad) error
	GetFacultadByID(ctx context.Context, id string) (*domainAca.Facultad, error)
	ListFacultades(ctx context.Context, sedeID string) ([]*domainAca.Facultad, error)
	DeleteFacultadLogico(ctx context.Context, id string) error

	// Programas
	CreatePrograma(ctx context.Context, p *domainAca.Programa) error
	UpdatePrograma(ctx context.Context, p *domainAca.Programa) error
	GetProgramaByID(ctx context.Context, id string) (*domainAca.Programa, error)
	ListProgramas(ctx context.Context, facultadID string) ([]*domainAca.Programa, error)
	DeleteProgramaLogico(ctx context.Context, id string) error

	// Asignaturas
	CreateAsignatura(ctx context.Context, a *domainAca.Asignatura) error
	UpdateAsignatura(ctx context.Context, a *domainAca.Asignatura) error
	GetAsignaturaByID(ctx context.Context, id string) (*domainAca.Asignatura, error)
	ListAsignaturas(ctx context.Context, programaID string) ([]*domainAca.Asignatura, error)
	DeleteAsignaturaLogico(ctx context.Context, id string) error

	// Grupos
	CreateGrupo(ctx context.Context, g *domainAca.Grupo) error
	UpdateGrupo(ctx context.Context, g *domainAca.Grupo) error
	GetGrupoByID(ctx context.Context, id string) (*domainAca.Grupo, error)
	ListGrupos(ctx context.Context, asignaturaID string, periodoID string) ([]*domainAca.Grupo, error)
	DeleteGrupoLogico(ctx context.Context, id string) error
}

// AsignacionRepository define los métodos de persistencia para asignaciones (US-ACA-03).
type AsignacionRepository interface {
	Create(ctx context.Context, a *domainAca.Asignacion) error
	Update(ctx context.Context, a *domainAca.Asignacion) error
	GetByID(ctx context.Context, id string) (*domainAca.Asignacion, error)
	ListByPeriodoID(ctx context.Context, periodoID string) ([]domainAca.Asignacion, error)
	ListByDocenteID(ctx context.Context, periodoID string, docenteID string) ([]domainAca.Asignacion, error)
	ListByEspacioID(ctx context.Context, periodoID string, espacioID string) ([]domainAca.Asignacion, error)
	DeleteLogico(ctx context.Context, id string) error
}

// CalendarioExcepcionRepository define los métodos de persistencia para excepciones lectivas (US-ACA-04).
type CalendarioExcepcionRepository interface {
	Create(ctx context.Context, e *domainAca.CalendarioExcepcion) error
	Update(ctx context.Context, e *domainAca.CalendarioExcepcion) error
	GetByID(ctx context.Context, id string) (*domainAca.CalendarioExcepcion, error)
	ListAll(ctx context.Context) ([]*domainAca.CalendarioExcepcion, error)
	ListByRango(ctx context.Context, inicio, fin time.Time) ([]*domainAca.CalendarioExcepcion, error)
	DeleteLogico(ctx context.Context, id string) error
}
