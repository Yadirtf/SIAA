// Package handler — manejador para la consulta de roles del sistema.
// US-ROL-01 AC-01.
package handler

import (
	"net/http"

	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/domain/rbac"
)

// RoleDTO representa un rol con sus permisos asociados según la matriz SRS §3.2.
type RoleDTO struct {
	Nombre   string   `json:"nombre"`
	Permisos []string `json:"permisos"`
}

// RolesHandler maneja las solicitudes relacionadas con roles y permisos.
type RolesHandler struct{}

// NewRolesHandler inicializa una nueva instancia de RolesHandler.
func NewRolesHandler() *RolesHandler {
	return &RolesHandler{}
}

// ListarRoles godoc
// @Summary     Listar roles del sistema
// @Description Retorna los roles predefinidos con la matriz exacta de permisos del SRS §3.2
// @Tags        roles
// @Produce     json
// @Success     200 {array} RoleDTO
// @Failure     401 {object} middleware.errorResponse
// @Failure     403 {object} middleware.errorResponse
// @Router      /roles [get]
func (h *RolesHandler) ListarRoles(c echo.Context) error {
	rolesOrdenados := []rbac.RoleName{
		rbac.RolSuperadmin,
		rbac.RolAdminInst,
		rbac.RolCoordinador,
		rbac.RolDocente,
		rbac.RolEstudiante,
		rbac.RolMonitor,
		rbac.RolAuditor,
	}

	res := make([]RoleDTO, 0, len(rolesOrdenados))
	for _, r := range rolesOrdenados {
		perms := rbac.DefaultPermissions[r]
		pStrings := make([]string, len(perms))
		for i, p := range perms {
			pStrings[i] = string(p)
		}
		res = append(res, RoleDTO{
			Nombre:   string(r),
			Permisos: pStrings,
		})
	}

	return c.JSON(http.StatusOK, res)
}
