// Package handler — manejador para la consulta y gestión de roles del sistema.
// Satisface US-ROL-01 (matriz RBAC) y US-ROL-03 (roles personalizados).
package handler

import (
	"net/http"

	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/transport/http/middleware"
	usecaseRbac "github.com/siaa/backend/internal/usecase/rbac"
)

// RoleDTO representa un rol con sus permisos asociados según la matriz SRS §3.2.
type RoleDTO struct {
	ID            string   `json:"id,omitempty"`
	Nombre        string   `json:"nombre"`
	Descripcion   string   `json:"descripcion,omitempty"`
	Permisos      []string `json:"permisos"`
	EsPredefinido bool     `json:"esPredefinido"`
}

// CrearRolRequest es el cuerpo para registrar un rol personalizado.
type CrearRolRequest struct {
	Nombre      string   `json:"nombre"      validate:"required"`
	Descripcion string   `json:"descripcion"`
	Permisos    []string `json:"permisos"    validate:"required,min=1"`
}

// ActualizarRolRequest es el cuerpo para modificar un rol personalizado.
type ActualizarRolRequest struct {
	Descripcion string   `json:"descripcion"`
	Permisos    []string `json:"permisos" validate:"required,min=1"`
}

// RolesHandler maneja las solicitudes relacionadas con roles y permisos.
type RolesHandler struct {
	svc *usecaseRbac.Service
}

// NewRolesHandler inicializa una nueva instancia de RolesHandler.
// Permite inyectar el servicio de RBAC o operar en modo fallback si es nulo.
func NewRolesHandler(svcs ...*usecaseRbac.Service) *RolesHandler {
	var svc *usecaseRbac.Service
	if len(svcs) > 0 {
		svc = svcs[0]
	}
	return &RolesHandler{svc: svc}
}

// ListarRoles retorna los roles predefinidos y personalizados del sistema.
func (h *RolesHandler) ListarRoles(c echo.Context) error {
	if h.svc != nil {
		roles, err := h.svc.ListarRoles(c.Request().Context())
		if err != nil {
			return err
		}
		res := make([]RoleDTO, 0, len(roles))
		for _, r := range roles {
			pStrings := make([]string, len(r.Permisos))
			for i, p := range r.Permisos {
				pStrings[i] = string(p)
			}
			res = append(res, RoleDTO{
				ID:            r.ID,
				Nombre:        r.Nombre,
				Descripcion:   r.Descripcion,
				Permisos:      pStrings,
				EsPredefinido: r.EsPredefinido,
			})
		}
		return c.JSON(http.StatusOK, res)
	}

	// Fallback por defecto si el servicio no está inyectado
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
			Nombre:        string(r),
			Permisos:      pStrings,
			EsPredefinido: true,
		})
	}

	return c.JSON(http.StatusOK, res)
}

// CrearRol crea un nuevo rol personalizado (US-ROL-03 AC-01, AC-02).
func (h *RolesHandler) CrearRol(c echo.Context) error {
	actorID := c.Get(middleware.CtxUsuarioID).(string)

	var req CrearRolRequest
	if err := c.Bind(&req); err != nil {
		return echo.ErrBadRequest
	}
	if err := c.Validate(&req); err != nil {
		return err
	}

	rol, err := h.svc.CrearRol(c.Request().Context(), actorID, req.Nombre, req.Descripcion, req.Permisos)
	if err != nil {
		return err
	}

	return c.JSON(http.StatusCreated, rol)
}

// ActualizarRol actualiza los permisos de un rol personalizado (US-ROL-03 AC-03, AC-05).
func (h *RolesHandler) ActualizarRol(c echo.Context) error {
	actorID := c.Get(middleware.CtxUsuarioID).(string)
	id := c.Param("id")

	var req ActualizarRolRequest
	if err := c.Bind(&req); err != nil {
		return echo.ErrBadRequest
	}
	if err := c.Validate(&req); err != nil {
		return err
	}

	rol, err := h.svc.ActualizarRol(c.Request().Context(), actorID, id, req.Descripcion, req.Permisos)
	if err != nil {
		return err
	}

	return c.JSON(http.StatusOK, rol)
}

// EliminarRol elimina un rol personalizado si no está en uso (US-ROL-03 AC-03, AC-04, AC-05).
func (h *RolesHandler) EliminarRol(c echo.Context) error {
	actorID := c.Get(middleware.CtxUsuarioID).(string)
	id := c.Param("id")

	if err := h.svc.EliminarRol(c.Request().Context(), actorID, id); err != nil {
		return err
	}

	return c.NoContent(http.StatusNoContent)
}
