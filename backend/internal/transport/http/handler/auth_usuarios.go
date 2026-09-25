// Package handler — Handler para listar usuarios del sistema (US-AUT, US-ROL, selectores UI).
package handler

import (
	"net/http"

	"github.com/labstack/echo/v4"
)

// UsuarioItemDTO representa la información sintetizada de un usuario para selectores en UI y gestión.
type UsuarioItemDTO struct {
	ID       string   `json:"id"`
	Correo   string   `json:"correo"`
	Nombre   string   `json:"nombre"`
	Apellido string   `json:"apellido"`
	Roles    []string `json:"roles"`
	Activo   bool     `json:"activo"`
}

// ListarUsuarios procesa GET /api/v1/usuarios.
// Retorna la lista de usuarios activos para filtrado y selectores administrativos.
func (h *AuthHandler) ListarUsuarios(c echo.Context) error {
	usuarios, err := h.svc.ListarUsuarios(c.Request().Context(), 250)
	if err != nil {
		return err
	}

	res := make([]UsuarioItemDTO, len(usuarios))
	for i, u := range usuarios {
		roles := make([]string, len(u.Roles))
		for j, r := range u.Roles {
			roles[j] = string(r.Nombre)
		}
		res[i] = UsuarioItemDTO{
			ID:       u.ID,
			Correo:   u.Correo,
			Nombre:   u.Nombre,
			Apellido: u.Apellido,
			Roles:    roles,
			Activo:   u.Activo,
		}
	}

	return c.JSON(http.StatusOK, res)
}
