package repository

import (
	"context"
	"time"
)

// ProcesoRepository guarda la marca de agua de los procesos periódicos (ADR-09): hasta qué
// instante ya se procesó, para que cada ciclo revise solo la ventana nueva.
type ProcesoRepository interface {
	ObtenerMarca(ctx context.Context, proceso string) (*time.Time, error)
	GuardarMarca(ctx context.Context, proceso string, hasta time.Time) error
}
