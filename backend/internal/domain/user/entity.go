// Package user define las entidades de dominio relacionadas con el usuario.
// Estas entidades son el corazón del modelo — no dependen de infraestructura.
package user

import (
	"time"

	"github.com/siaa/backend/internal/domain/rbac"
)

// Usuario representa un usuario del sistema.
// Es la entidad central del dominio de autenticación y autorización.
type Usuario struct {
	ID                   string
	Correo               string
	PasswordHash         string
	Nombre               string
	Apellido             string
	Activo               bool
	Eliminado            bool
	Roles                []RolAsignado
	Ambitos              []rbac.Scope
	IntentosFallidos     int
	BloqueadoHasta       *time.Time
	DispositivoVinculado *string
	CreadoEn             time.Time
	ActualizadoEn        time.Time
}

// RolAsignado es la asignación de un rol a un usuario con vigencia opcional.
type RolAsignado struct {
	RolID          string
	Nombre         rbac.RoleName
	VigenciaInicio *time.Time
	VigenciaFin    *time.Time
}

// Dispositivo representa un dispositivo móvil vinculado a un usuario.
type Dispositivo struct {
	ID                  string
	UsuarioID           string
	InstalacionID       string
	Modelo              string
	SO                  string
	VersionApp          string
	Confiable           bool
	PendienteAprobacion bool
	CreadoEn            time.Time
}
