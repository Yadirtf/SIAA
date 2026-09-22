// Package repository — contratos para la jerarquía física y cartografía.
// ADR-02: usecase depende de interfaces, no de implementaciones concretas.
package repository

import (
	"context"
	"time"

	"github.com/siaa/backend/internal/domain/geo"
)

// SedeRepository define operaciones de persistencia para sedes.
type SedeRepository interface {
	Create(ctx context.Context, s *geo.Sede) error
	FindByID(ctx context.Context, id string) (*geo.Sede, error)
	FindByCodigo(ctx context.Context, codigo string) (*geo.Sede, error)
	List(ctx context.Context) ([]*geo.Sede, error)
	Update(ctx context.Context, s *geo.Sede) error
	SoftDelete(ctx context.Context, id string) error
}

// BloqueRepository define operaciones de persistencia para bloques.
type BloqueRepository interface {
	Create(ctx context.Context, b *geo.Bloque) error
	FindByID(ctx context.Context, id string) (*geo.Bloque, error)
	FindByCodigo(ctx context.Context, sedeID, codigo string) (*geo.Bloque, error)
	ListBySede(ctx context.Context, sedeID string) ([]*geo.Bloque, error)
	List(ctx context.Context) ([]*geo.Bloque, error)
	Update(ctx context.Context, b *geo.Bloque) error
	SoftDelete(ctx context.Context, id string) error
}

// EspacioFilter define criterios de filtrado para consulta de espacios.
type EspacioFilter struct {
	SedeID   string
	BloqueID string
	Piso     *int
	Tipo     *geo.TipoEspacio
	Estado   *geo.EstadoEspacio
}

// EspacioRepository define operaciones de persistencia para espacios.
type EspacioRepository interface {
	Create(ctx context.Context, e *geo.Espacio) error
	FindByID(ctx context.Context, id string) (*geo.Espacio, error)
	FindByCodigo(ctx context.Context, codigo string) (*geo.Espacio, error)
	List(ctx context.Context, filter EspacioFilter) ([]*geo.Espacio, error)
	Update(ctx context.Context, e *geo.Espacio) error
	SoftDelete(ctx context.Context, id string) error
	BuscarIntersecciones(ctx context.Context, espacioID string, bloqueID *string, piso *int, geom geo.GeoPolygon) ([]*geo.Espacio, error)
}

// SesionFutureChecker abstrae la verificación de sesiones futuras asociadas a un espacio.
// Permite desacoplar US-GEO-01 de la implementación completa de sesiones (US-ACA-05).
type SesionFutureChecker interface {
	CountSesionesFuturasPorEspacio(ctx context.Context, espacioID string, desde time.Time) (int64, error)
}
