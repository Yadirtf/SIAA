// Package repository — consultas de los avisos programados del worker (US-JUS-04 AC-02,
// US-ROL-05 AC-02). Son interfaces aparte para no ampliar los repositorios principales.
package repository

import (
	"context"
	"time"

	"github.com/siaa/backend/internal/domain/justificacion"
	"github.com/siaa/backend/internal/domain/user"
)

// JustificacionesSinResolverRepository encuentra las justificaciones que siguen sin decisión.
type JustificacionesSinResolverRepository interface {
	// SinResolver devuelve las RADICADAS o EN_REVISION radicadas antes de `radicadasAntesDe`,
	// las más antiguas primero.
	SinResolver(ctx context.Context, radicadasAntesDe time.Time, limite int) ([]*justificacion.Justificacion, error)
}

// RolesPorVencerRepository encuentra los usuarios con algún rol cuya vigencia termina pronto.
type RolesPorVencerRepository interface {
	// ConRolesPorVencer devuelve los usuarios activos con un rol cuya VigenciaFin cae en (desde, hasta].
	ConRolesPorVencer(ctx context.Context, desde, hasta time.Time) ([]*user.Usuario, error)
}
