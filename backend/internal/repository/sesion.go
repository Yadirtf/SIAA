// Package repository — interfaz del repositorio de sesiones académicas.
// Satisface US-ACA-05, US-ACA-06, US-ACA-08, US-MAR-01.
package repository

import (
	"context"
	"time"

	"github.com/siaa/backend/internal/domain/academico"
)

// SesionFilter define los criterios de filtrado para consulta de sesiones.
type SesionFilter struct {
	PeriodoID    string
	AsignacionID string
	DocenteID    string
	EspacioID    string
	Fecha        string
	Estado       *academico.EstadoSesion
}

// SesionRepository define las operaciones de persistencia sobre sesiones.
type SesionRepository interface {
	Create(ctx context.Context, s *academico.Sesion) error
	CreateBatch(ctx context.Context, sesiones []*academico.Sesion) (int, error)
	FindByID(ctx context.Context, id string) (*academico.Sesion, error)
	FindByAsignacionFechaHora(ctx context.Context, asignacionID string, fecha string, horaInicio string) (*academico.Sesion, error)
	ListByPeriodo(ctx context.Context, periodoID string) ([]*academico.Sesion, error)
	ListByDocenteYFecha(ctx context.Context, docenteID string, fecha string) ([]*academico.Sesion, error)
	List(ctx context.Context, filter SesionFilter) ([]*academico.Sesion, error)
	Update(ctx context.Context, s *academico.Sesion) error
	CountSesionesFuturasPorEspacio(ctx context.Context, espacioID string, desde time.Time) (int64, error)
}
