// Package handler — DTO de la gestión de usuarios (US-ROL-01..05).
package handler

import (
	"time"

	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/domain/user"
)

// RolAsignadoDTO es un rol del usuario con su vigencia.
type RolAsignadoDTO struct {
	Nombre         string     `json:"nombre"`
	VigenciaInicio *time.Time `json:"vigenciaInicio,omitempty"`
	VigenciaFin    *time.Time `json:"vigenciaFin,omitempty"`
}

// UsuarioDTO es la vista administrativa de un usuario (sin secretos).
// roles conserva la lista de nombres que ya consumen los selectores de la web.
type UsuarioDTO struct {
	ID           string           `json:"id"`
	Correo       string           `json:"correo"`
	Nombre       string           `json:"nombre"`
	Apellido     string           `json:"apellido"`
	Documento    string           `json:"documento,omitempty"`
	Activo       bool             `json:"activo"`
	Bloqueado    bool             `json:"bloqueado"`
	TOTPActivado bool             `json:"totpActivado"`
	Roles        []string         `json:"roles"`
	RolesDetalle []RolAsignadoDTO `json:"rolesDetalle"`
	Ambitos      []rbac.Scope     `json:"ambitos"`
	CreadoEn     time.Time        `json:"creadoEn"`
}

func usuarioToDTO(u *user.Usuario, ahora time.Time) UsuarioDTO {
	d := UsuarioDTO{
		ID: u.ID, Correo: u.Correo, Nombre: u.Nombre, Apellido: u.Apellido, Documento: u.Documento,
		Activo: u.Activo, TOTPActivado: u.TOTPActivado, CreadoEn: u.CreadoEn,
		Bloqueado:    u.BloqueadoHasta != nil && u.BloqueadoHasta.After(ahora),
		Roles:        make([]string, len(u.Roles)),
		RolesDetalle: make([]RolAsignadoDTO, len(u.Roles)),
		Ambitos:      u.Ambitos,
	}
	for i, r := range u.Roles {
		d.Roles[i] = string(r.Nombre)
		d.RolesDetalle[i] = RolAsignadoDTO{Nombre: string(r.Nombre), VigenciaInicio: r.VigenciaInicio, VigenciaFin: r.VigenciaFin}
	}
	if d.Ambitos == nil {
		d.Ambitos = []rbac.Scope{}
	}
	return d
}
