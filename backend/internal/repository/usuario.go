// Package repository — entidad Usuario y su repositorio.
// ADR-02: usecase depende de interfaces, no de implementaciones concretas.
package repository

import (
	"context"
	"time"

	"github.com/siaa/backend/internal/domain/user"
)

// UsuarioRepository define las operaciones de persistencia sobre usuarios.
type UsuarioRepository interface {
	// FindByCorreo busca un usuario activo por correo electrónico.
	FindByCorreo(ctx context.Context, correo string) (*user.Usuario, error)
	// FindByID busca un usuario por su identificador único.
	FindByID(ctx context.Context, id string) (*user.Usuario, error)
	// UpdateIntentosFallidos actualiza el contador de fallos, fecha de bloqueo y timestamp del último fallo.
	UpdateIntentosFallidos(ctx context.Context, id string, intentos int, bloqueadoHasta *time.Time, ultimoFalloEn *time.Time) error
	// ResetIntentosFallidos reinicia el contador y elimina el bloqueo.
	ResetIntentosFallidos(ctx context.Context, id string) error
	// UpdatePassword actualiza el hash de contraseña del usuario.
	UpdatePassword(ctx context.Context, id, passwordHash string) error
	// Create persiste un nuevo usuario.
	Create(ctx context.Context, u *user.Usuario) error
	// Update actualiza todos los campos del usuario.
	Update(ctx context.Context, u *user.Usuario) error
	// Listar retorna una lista de usuarios activos no eliminados.
	Listar(ctx context.Context, limite int) ([]*user.Usuario, error)
	// FindByDocumento busca un usuario no eliminado por documento de identidad.
	FindByDocumento(ctx context.Context, documento string) (*user.Usuario, error)
	// Buscar lista usuarios no eliminados con filtros y paginación; devuelve también el total.
	Buscar(ctx context.Context, f FiltroUsuarios) ([]*user.Usuario, int64, error)
}

// FiltroUsuarios filtra la gestión de usuarios (US-ROL, RF-ROL-003).
type FiltroUsuarios struct {
	Texto  string // Coincidencia parcial en nombre, apellido, correo o documento.
	Rol    string
	Activo *bool
	Pagina int
	Limite int
	// Visibilidad restringe el listado a quien opera por ámbito; nil = sin restricción.
	Visibilidad *VisibilidadUsuarios
}

// VisibilidadUsuarios: un usuario es visible si comparte algún ámbito o tiene uno de los roles.
type VisibilidadUsuarios struct {
	AmbitoIDs     []string
	RolesVisibles []string
}
