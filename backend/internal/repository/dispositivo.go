// Package repository — dispositivos móviles vinculados a usuarios.
// ADR-02: usecase depende de interfaces, no de implementaciones concretas.
// US-AUT-03: vinculación de dispositivo confiable.
package repository

import (
	"context"
	"time"

	"github.com/siaa/backend/internal/domain/user"
)

// DispositivoRepository define operaciones sobre dispositivos registrados.
type DispositivoRepository interface {
	// FindByID busca un dispositivo por su identificador.
	FindByID(ctx context.Context, id string) (*user.Dispositivo, error)
	// FindByInstalacion busca el dispositivo de un usuario por ID de instalación.
	FindByInstalacion(ctx context.Context, usuarioID, instalacionID string) (*user.Dispositivo, error)
	// Create registra un nuevo dispositivo.
	Create(ctx context.Context, d *user.Dispositivo) error
	// FindByUsuario lista todos los dispositivos de un usuario.
	FindByUsuario(ctx context.Context, usuarioID string) ([]*user.Dispositivo, error)
	// FindRecentByInstalacion busca dispositivos vinculados a una instalación a partir de una fecha (detección de anomalías R-03).
	FindRecentByInstalacion(ctx context.Context, instalacionID string, desde time.Time) ([]*user.Dispositivo, error)
	// Update actualiza el estado de un dispositivo (ej: aprobación o revocación).
	Update(ctx context.Context, d *user.Dispositivo) error
}
