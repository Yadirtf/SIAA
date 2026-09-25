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
	ID                     string
	Correo                 string
	PasswordHash           string
	Nombre                 string
	Apellido               string
	Activo                 bool
	Eliminado              bool
	Roles                  []RolAsignado
	Ambitos                []rbac.Scope
	IntentosFallidos       int
	BloqueadoHasta         *time.Time
	UltimoFalloEn          *time.Time
	DispositivoVinculado   *string
	SesionesRevocadasAntes *time.Time
	TOTPSecreto            string
	TOTPActivado           bool
	BackupCodes            []string
	IntentosFallidosTOTP   int
	BloqueadoHastaTOTP     *time.Time
	CreadoEn               time.Time
	ActualizadoEn          time.Time
}

// RolAsignado es la asignación de un rol a un usuario con vigencia opcional.
type RolAsignado struct {
	RolID          string
	Nombre         rbac.RoleName
	VigenciaInicio *time.Time
	VigenciaFin    *time.Time
}

// IsVigente verifica la validez temporal del rol (US-ROL-05 AC-01).
// Satisface: (VigenciaInicio == nil || now >= VigenciaInicio) && (VigenciaFin == nil || now <= VigenciaFin)
func (ra *RolAsignado) IsVigente(now time.Time) bool {
	if ra.VigenciaInicio != nil && now.Before(*ra.VigenciaInicio) {
		return false
	}
	if ra.VigenciaFin != nil && now.After(*ra.VigenciaFin) {
		return false
	}
	return true
}

// Dispositivo representa un dispositivo móvil vinculado a un usuario (US-AUT-03).
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
	ActualizadoEn       time.Time
	RevocadoEn          *time.Time
}

// EsValidoParaMarcaje indica si el dispositivo está activo, es confiable y no está pendiente de aprobación (AC-02).
func (d *Dispositivo) EsValidoParaMarcaje() bool {
	return d.Confiable && !d.PendienteAprobacion && d.RevocadoEn == nil
}

// Aprobar autoriza el dispositivo como confiable (AC-03).
func (d *Dispositivo) Aprobar(now time.Time) {
	d.PendienteAprobacion = false
	d.Confiable = true
	d.RevocadoEn = nil
	d.ActualizadoEn = now
}

// Revocar invalida el dispositivo para marcajes futuros (AC-06).
func (d *Dispositivo) Revocar(now time.Time) {
	d.Confiable = false
	d.RevocadoEn = &now
	d.ActualizadoEn = now
}
