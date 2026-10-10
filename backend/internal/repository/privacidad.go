// Package repository — persistencia del consentimiento y de la retención de ubicaciones
// (EP-11: RNF-LEG-001, RNF-LEG-006).
package repository

import (
	"context"
	"time"

	"github.com/siaa/backend/internal/domain/privacidad"
)

// ConsentimientoRepository guarda cada decisión como registro nuevo (historial probatorio).
type ConsentimientoRepository interface {
	Registrar(ctx context.Context, c *privacidad.Consentimiento) error
	// Ultimo devuelve la decisión más reciente del usuario, o nil si nunca decidió.
	Ultimo(ctx context.Context, usuarioID string) (*privacidad.Consentimiento, error)
}

// RetencionRepository anonimiza las ubicaciones de marcaje más antiguas que el límite.
type RetencionRepository interface {
	// AnonimizarUbicaciones elimina coordenadas y precisión de los marcajes anteriores a
	// `antesDe` y de sus copias en la bitácora, salvo los protegidos por una investigación en
	// curso (US-AUD-04 AC-03); devuelve cuántos marcajes cambió.
	AnonimizarUbicaciones(ctx context.Context, antesDe time.Time, excluir privacidad.ExclusionRetencion) (int64, error)
	// ContarRetenidos cuenta los marcajes vencidos con coordenadas que protege `retener`.
	ContarRetenidos(ctx context.Context, antesDe time.Time, retener privacidad.ExclusionRetencion) (int64, error)
}

// InvestigacionRepository guarda las marcas de investigación que suspenden la retención.
type InvestigacionRepository interface {
	Crear(ctx context.Context, i *privacidad.Investigacion) error
	// Obtener devuelve la investigación o nil si no existe.
	Obtener(ctx context.Context, id string) (*privacidad.Investigacion, error)
	// Activas lista las investigaciones sin liberar, las más recientes primero.
	Activas(ctx context.Context) ([]*privacidad.Investigacion, error)
	// Liberar persiste el cierre (LiberadaEn y LiberadaPor) de una investigación activa.
	Liberar(ctx context.Context, i *privacidad.Investigacion) error
}
