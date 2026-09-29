// Package handler — gestión administrativa de usuarios (US-ROL-01..05, RF-ROL-003/005).
package handler

import (
	"net/http"
	"strconv"
	"time"

	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/domain/user"
	"github.com/siaa/backend/internal/repository"
	"github.com/siaa/backend/internal/transport/http/middleware"
	"github.com/siaa/backend/internal/usecase/usuarios"
)

// UsuariosHandler expone el CRUD de usuarios, roles, ámbitos e importación CSV.
type UsuariosHandler struct {
	svc *usuarios.Service
}

// NewUsuariosHandler crea el handler de gestión de usuarios.
func NewUsuariosHandler(svc *usuarios.Service) *UsuariosHandler {
	return &UsuariosHandler{svc: svc}
}

func actorUsuarios(c echo.Context) usuarios.Actor {
	a := usuarios.Actor{Alcance: middleware.AlcanceDe(c)}
	if claims, ok := middleware.GetClaims(c); ok {
		a.UsuarioID, a.RolActivo = claims.UsuarioID, claims.RolActivo
	}
	return a
}

// Listar maneja GET /usuarios?q=&rol=&activo=&pagina=&limite=. Devuelve la lista y el total
// en la cabecera X-Total-Count.
func (h *UsuariosHandler) Listar(c echo.Context) error {
	f := repository.FiltroUsuarios{Texto: c.QueryParam("q"), Rol: c.QueryParam("rol")}
	f.Pagina, _ = strconv.Atoi(c.QueryParam("pagina"))
	f.Limite, _ = strconv.Atoi(c.QueryParam("limite"))
	if v := c.QueryParam("activo"); v != "" {
		activo := v == "true"
		f.Activo = &activo
	}
	pag, err := h.svc.Listar(c.Request().Context(), actorUsuarios(c), f)
	if err != nil {
		return err
	}
	ahora := time.Now()
	res := make([]UsuarioDTO, len(pag.Usuarios))
	for i, u := range pag.Usuarios {
		res[i] = usuarioToDTO(u, ahora)
	}
	c.Response().Header().Set("X-Total-Count", strconv.FormatInt(pag.Total, 10))
	return c.JSON(http.StatusOK, res)
}

// Obtener maneja GET /usuarios/:id.
func (h *UsuariosHandler) Obtener(c echo.Context) error {
	u, err := h.svc.Obtener(c.Request().Context(), actorUsuarios(c), c.Param("id"))
	if err != nil {
		return err
	}
	return c.JSON(http.StatusOK, usuarioToDTO(u, time.Now()))
}

// Crear maneja POST /usuarios.
func (h *UsuariosHandler) Crear(c echo.Context) error {
	var cmd usuarios.CrearCmd
	if err := c.Bind(&cmd); err != nil {
		return shared.NewValidationError("Cuerpo de la solicitud inválido")
	}
	res, err := h.svc.Crear(c.Request().Context(), actorUsuarios(c), cmd)
	if err != nil {
		return err
	}
	return c.JSON(http.StatusCreated, map[string]interface{}{
		"usuario":           usuarioToDTO(res.Usuario, time.Now()),
		"invitacionEnviada": res.InvitacionEnviada,
	})
}

// Actualizar maneja PUT /usuarios/:id.
func (h *UsuariosHandler) Actualizar(c echo.Context) error {
	var cmd usuarios.ActualizarCmd
	if err := c.Bind(&cmd); err != nil {
		return shared.NewValidationError("Cuerpo de la solicitud inválido")
	}
	u, err := h.svc.Actualizar(c.Request().Context(), actorUsuarios(c), c.Param("id"), cmd)
	return responderUsuario(c, u, err)
}

type estadoUsuarioRequest struct {
	Motivo string `json:"motivo"`
}

// Activar maneja POST /usuarios/:id/activar.
func (h *UsuariosHandler) Activar(c echo.Context) error {
	return h.cambiarEstado(c, true)
}

// Desactivar maneja POST /usuarios/:id/desactivar; exige motivo y cierra sus sesiones.
func (h *UsuariosHandler) Desactivar(c echo.Context) error {
	return h.cambiarEstado(c, false)
}

func (h *UsuariosHandler) cambiarEstado(c echo.Context, activo bool) error {
	var req estadoUsuarioRequest
	_ = c.Bind(&req)
	u, err := h.svc.CambiarEstado(c.Request().Context(), actorUsuarios(c), c.Param("id"), activo, req.Motivo)
	return responderUsuario(c, u, err)
}

// AsignarRoles maneja PUT /usuarios/:id/roles con {"roles":[{"nombre":"COORDINADOR"}]}.
func (h *UsuariosHandler) AsignarRoles(c echo.Context) error {
	var req struct {
		Roles []usuarios.RolCmd `json:"roles"`
	}
	if err := c.Bind(&req); err != nil {
		return shared.NewValidationError("Cuerpo de la solicitud inválido")
	}
	u, err := h.svc.AsignarRoles(c.Request().Context(), actorUsuarios(c), c.Param("id"), req.Roles)
	return responderUsuario(c, u, err)
}

// AsignarAmbitos maneja PUT /usuarios/:id/ambitos con {"ambitos":[{"tipo":"FACULTAD","id":"..."}]}.
func (h *UsuariosHandler) AsignarAmbitos(c echo.Context) error {
	var req struct {
		Ambitos []rbac.Scope `json:"ambitos"`
	}
	if err := c.Bind(&req); err != nil {
		return shared.NewValidationError("Cuerpo de la solicitud inválido")
	}
	u, err := h.svc.AsignarAmbitos(c.Request().Context(), actorUsuarios(c), c.Param("id"), req.Ambitos)
	return responderUsuario(c, u, err)
}

// Importar maneja POST /usuarios/importar?confirmar=true con el CSV como cuerpo (text/csv).
// Sin confirmar solo devuelve la vista previa por fila.
func (h *UsuariosHandler) Importar(c echo.Context) error {
	confirmar := c.QueryParam("confirmar") == "true"
	cuerpo := http.MaxBytesReader(c.Response(), c.Request().Body, 5<<20)
	res, err := h.svc.ImportarCSV(c.Request().Context(), actorUsuarios(c), cuerpo, confirmar)
	if err != nil {
		return err
	}
	return c.JSON(http.StatusOK, res)
}

func responderUsuario(c echo.Context, u *user.Usuario, err error) error {
	if err != nil {
		return err
	}
	return c.JSON(http.StatusOK, usuarioToDTO(u, time.Now()))
}
