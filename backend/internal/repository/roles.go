// Package repository — Repositorio de roles del sistema.
// Satisface US-ROL-03, AC-01..AC-05.
package repository

import (
	"context"

	"github.com/siaa/backend/internal/domain/rbac"
)

// RolRepository define las operaciones de persistencia sobre roles.
type RolRepository interface {
	Listar(ctx context.Context) ([]*rbac.Rol, error)
	FindByID(ctx context.Context, id string) (*rbac.Rol, error)
	FindByNombre(ctx context.Context, nombre string) (*rbac.Rol, error)
	Create(ctx context.Context, r *rbac.Rol) error
	Update(ctx context.Context, r *rbac.Rol) error
	Delete(ctx context.Context, id string) error
	CountUsuariosConRol(ctx context.Context, nombre string) (int, error)
}
