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
	// `antesDe` y de sus copias en la bitácora; devuelve cuántos marcajes cambió.
	AnonimizarUbicaciones(ctx context.Context, antesDe time.Time) (int64, error)
}
