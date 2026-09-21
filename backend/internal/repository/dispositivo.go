// Package repository — dispositivos móviles vinculados a usuarios.
// ADR-02: usecase depende de interfaces, no de implementaciones concretas.
package repository

import (
	"context"

	"github.com/siaa/backend/internal/domain/user"
)

// DispositivoRepository define operaciones sobre dispositivos registrados.
type DispositivoRepository interface {
	// FindByInstalacion busca el dispositivo de un usuario por ID de instalación.
	FindByInstalacion(ctx context.Context, usuarioID, instalacionID string) (*user.Dispositivo, error)
	// Create registra un nuevo dispositivo.
	Create(ctx context.Context, d *user.Dispositivo) error
	// FindByUsuario lista todos los dispositivos de un usuario.
	FindByUsuario(ctx context.Context, usuarioID string) ([]*user.Dispositivo, error)
	// Update actualiza el estado de un dispositivo (ej: aprobación).
	Update(ctx context.Context, d *user.Dispositivo) error
}
