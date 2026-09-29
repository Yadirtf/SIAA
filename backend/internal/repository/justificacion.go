// Package repository — persistencia de justificaciones y sus soportes (EP-07).
package repository

import (
	"context"
	"errors"

	"github.com/siaa/backend/internal/domain/justificacion"
)

// ErrJustificacionModificada indica que otra revisión cambió el estado primero.
var ErrJustificacionModificada = errors.New("la justificación cambió de estado mientras se revisaba")

// FiltroJustificaciones define los criterios de consulta de la bandeja de revisión.
type FiltroJustificaciones struct {
	DocenteID  string
	SesionIDs  []string
	Estado     justificacion.Estado
	Tipo       justificacion.Tipo
	FechaDesde string // YYYY-MM-DD de la sesión, inclusive
	FechaHasta string
	Alcance    *FiltroAlcance
}

// JustificacionRepository persiste las justificaciones.
type JustificacionRepository interface {
	Crear(ctx context.Context, j *justificacion.Justificacion) error
	ObtenerPorID(ctx context.Context, id string) (*justificacion.Justificacion, error)
	// ObtenerVigente devuelve la justificación en curso o aprobada de la sesión y docente.
	ObtenerVigente(ctx context.Context, sesionID, docenteID string) (*justificacion.Justificacion, error)
	Listar(ctx context.Context, f FiltroJustificaciones, skip, limit int64) ([]*justificacion.Justificacion, int64, error)
	// ActualizarEstado guarda la transición solo si el estado previo no cambió.
	ActualizarEstado(ctx context.Context, j *justificacion.Justificacion, estadoPrevio justificacion.Estado) error
}

// AdjuntoRepository guarda el contenido de los soportes cifrado en reposo.
type AdjuntoRepository interface {
	Guardar(ctx context.Context, id string, contenido []byte) error
	Obtener(ctx context.Context, id string) ([]byte, error)
}
