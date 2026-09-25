// Package handler — manejadores HTTP para Sedes y Bloques (US-GEO-01).
package handler

import (
	"net/http"

	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/transport/http/dto"
	"github.com/siaa/backend/internal/transport/http/middleware"
	usecaseGeo "github.com/siaa/backend/internal/usecase/geo"
)

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
	claims, _ := middleware.GetClaims(c)
	sedeID, err := middleware.EnforceScopeFilter(claims, rbac.ScopeSede, c.QueryParam("sedeId"))
	if err != nil {
		return err
	}

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
