// Package handler — manejador HTTP para la jerarquía física de espacios (US-GEO-01).
package handler

import (
	"net/http"
	"strconv"

	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/domain/geo"
	"github.com/siaa/backend/internal/repository"
	"github.com/siaa/backend/internal/transport/http/dto"
	"github.com/siaa/backend/internal/transport/http/middleware"
	usecaseGeo "github.com/siaa/backend/internal/usecase/geo"
)

// GeoHandler maneja las peticiones HTTP de sedes, bloques y espacios.
type GeoHandler struct {
	svc *usecaseGeo.Service
}

func NewGeoHandler(svc *usecaseGeo.Service) *GeoHandler {
	return &GeoHandler{svc: svc}
}

// ─────────────────────────────────────────────────────────────
// SEDES
// ─────────────────────────────────────────────────────────────

func (h *GeoHandler) CrearSede(c echo.Context) error {
	var req dto.CrearSedeRequest
	if err := c.Bind(&req); err != nil {
		return err
	}
	if err := c.Validate(&req); err != nil {
		return err
	}

	actor := extraerActor(c)
	sede, err := h.svc.CrearSede(c.Request().Context(), usecaseGeo.CrearSedeCmd{
		Codigo:    req.Codigo,
		Nombre:    req.Nombre,
		Direccion: req.Direccion,
		Actor:     actor,
	})
	if err != nil {
		return err
	}

	return c.JSON(http.StatusCreated, dto.SedeToResponse(sede))
}

func (h *GeoHandler) ListarSedes(c echo.Context) error {
	sedes, err := h.svc.ListarSedes(c.Request().Context())
	if err != nil {
		return err
	}

	res := make([]dto.SedeResponse, 0, len(sedes))
	for _, s := range sedes {
		res = append(res, dto.SedeToResponse(s))
	}
	return c.JSON(http.StatusOK, res)
}

func (h *GeoHandler) ObtenerSede(c echo.Context) error {
	id := c.Param("id")
	sede, err := h.svc.ObtenerSedePorID(c.Request().Context(), id)
	if err != nil {
		return err
	}
	return c.JSON(http.StatusOK, dto.SedeToResponse(sede))
}

// ─────────────────────────────────────────────────────────────
// BLOQUES
// ─────────────────────────────────────────────────────────────

func (h *GeoHandler) CrearBloque(c echo.Context) error {
	var req dto.CrearBloqueRequest
	if err := c.Bind(&req); err != nil {
		return err
	}
	if err := c.Validate(&req); err != nil {
		return err
	}

	actor := extraerActor(c)
	bloque, err := h.svc.CrearBloque(c.Request().Context(), usecaseGeo.CrearBloqueCmd{
		SedeID: req.SedeID,
		Codigo: req.Codigo,
		Nombre: req.Nombre,
		Pisos:  req.Pisos,
		Actor:  actor,
	})
	if err != nil {
		return err
	}

	return c.JSON(http.StatusCreated, dto.BloqueToResponse(bloque))
}

func (h *GeoHandler) ListarBloques(c echo.Context) error {
	sedeID := c.QueryParam("sedeId")
	bloques, err := h.svc.ListarBloques(c.Request().Context(), sedeID)
	if err != nil {
		return err
	}

	res := make([]dto.BloqueResponse, 0, len(bloques))
	for _, b := range bloques {
		res = append(res, dto.BloqueToResponse(b))
	}
	return c.JSON(http.StatusOK, res)
}

func (h *GeoHandler) ObtenerBloque(c echo.Context) error {
	id := c.Param("id")
	bloque, err := h.svc.ObtenerBloquePorID(c.Request().Context(), id)
	if err != nil {
		return err
	}
	return c.JSON(http.StatusOK, dto.BloqueToResponse(bloque))
}

// ─────────────────────────────────────────────────────────────
// ESPACIOS
// ─────────────────────────────────────────────────────────────

func (h *GeoHandler) CrearEspacio(c echo.Context) error {
	var req dto.CrearEspacioRequest
	if err := c.Bind(&req); err != nil {
		return err
	}
	if err := c.Validate(&req); err != nil {
		return err
	}

	actor := extraerActor(c)
	espacio, err := h.svc.CrearEspacio(c.Request().Context(), usecaseGeo.CrearEspacioCmd{
		SedeID:              req.SedeID,
		Torre:               req.Torre,
		BloqueID:            req.BloqueID,
		Piso:                req.Piso,
		Codigo:              req.Codigo,
		Nombre:              req.Nombre,
		Capacidad:           req.Capacidad,
		Tipo:                req.Tipo,
		FacultadResponsable: req.FacultadResponsable,
		Estado:              req.Estado,
		NivelValidacion:     req.NivelValidacion,
		BufferMetros:        req.BufferMetros,
		Actor:               actor,
	})
	if err != nil {
		return err
	}

	return c.JSON(http.StatusCreated, dto.EspacioToResponse(espacio))
}

func (h *GeoHandler) ListarEspacios(c echo.Context) error {
	filter := repository.EspacioFilter{
		SedeID:   c.QueryParam("sedeId"),
		BloqueID: c.QueryParam("bloqueId"),
	}
	if pStr := c.QueryParam("piso"); pStr != "" {
		if p, err := strconv.Atoi(pStr); err == nil {
			filter.Piso = &p
		}
	}
	if tStr := c.QueryParam("tipo"); tStr != "" {
		t := geo.TipoEspacio(tStr)
		filter.Tipo = &t
	}
	if eStr := c.QueryParam("estado"); eStr != "" {
		e := geo.EstadoEspacio(eStr)
		filter.Estado = &e
	}

	espacios, err := h.svc.ListarEspacios(c.Request().Context(), filter)
	if err != nil {
		return err
	}

	res := make([]dto.EspacioResponse, 0, len(espacios))
	for _, e := range espacios {
		res = append(res, dto.EspacioToResponse(e))
	}
	return c.JSON(http.StatusOK, res)
}

func (h *GeoHandler) ObtenerEspacio(c echo.Context) error {
	id := c.Param("id")
	espacio, err := h.svc.ObtenerEspacioPorID(c.Request().Context(), id)
	if err != nil {
		return err
	}
	return c.JSON(http.StatusOK, dto.EspacioToResponse(espacio))
}

func (h *GeoHandler) ActualizarEspacio(c echo.Context) error {
	id := c.Param("id")
	var req dto.ActualizarEspacioRequest
	if err := c.Bind(&req); err != nil {
		return err
	}
	if err := c.Validate(&req); err != nil {
		return err
	}

	actor := extraerActor(c)
	espacio, err := h.svc.ActualizarEspacio(c.Request().Context(), id, usecaseGeo.ActualizarEspacioCmd{
		SedeID:              req.SedeID,
		Torre:               req.Torre,
		BloqueID:            req.BloqueID,
		Piso:                req.Piso,
		Codigo:              req.Codigo,
		Nombre:              req.Nombre,
		Capacidad:           req.Capacidad,
		Tipo:                req.Tipo,
		FacultadResponsable: req.FacultadResponsable,
		Estado:              req.Estado,
		NivelValidacion:     req.NivelValidacion,
		BufferMetros:        req.BufferMetros,
		ConfirmarImpacto:    req.ConfirmarImpacto,
		Actor:               actor,
	})
	if err != nil {
		return err
	}

	return c.JSON(http.StatusOK, dto.EspacioToResponse(espacio))
}

func (h *GeoHandler) EliminarEspacio(c echo.Context) error {
	id := c.Param("id")
	actor := extraerActor(c)

	if err := h.svc.EliminarEspacio(c.Request().Context(), id, actor); err != nil {
		return err
	}

	return c.NoContent(http.StatusNoContent)
}

// ─────────────────────────────────────────────────────────────
// HELPER EXTRAER ACTOR
// ─────────────────────────────────────────────────────────────

func extraerActor(c echo.Context) usecaseGeo.ContextoActor {
	correlationID, _ := c.Get(middleware.CtxCorrelationID).(string)
	actorID, _ := c.Get(middleware.CtxUsuarioID).(string)
	rolActivo := ""
	if claims, ok := middleware.GetClaims(c); ok {
		rolActivo = claims.RolActivo
	}
	return usecaseGeo.ContextoActor{
		ActorID:       actorID,
		RolActivo:     rolActivo,
		CorrelationID: correlationID,
		IPOrigen:      c.RealIP(),
		AgenteUsuario: c.Request().UserAgent(),
	}
}
