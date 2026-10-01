// Package handler — edición de sedes y bloques (US-GEO-01).
package handler

import (
	"net/http"

	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/transport/http/dto"
	usecaseGeo "github.com/siaa/backend/internal/usecase/geo"
)

// ActualizarSede maneja PUT /api/v1/sedes/:id.
func (h *GeoHandler) ActualizarSede(c echo.Context) error {
	var req dto.CrearSedeRequest
	if err := c.Bind(&req); err != nil {
		return err
	}
	if err := c.Validate(&req); err != nil {
		return err
	}
	sede, err := h.svc.ActualizarSede(c.Request().Context(), c.Param("id"), usecaseGeo.CrearSedeCmd{
		Codigo: req.Codigo, Nombre: req.Nombre, Direccion: req.Direccion, Actor: extraerActor(c),
	})
	if err != nil {
		return err
	}
	return c.JSON(http.StatusOK, dto.SedeToResponse(sede))
}

// ActualizarBloqueRequest no exige sede: un bloque no cambia de sede.
type ActualizarBloqueRequest struct {
	Codigo string `json:"codigo" validate:"required"`
	Nombre string `json:"nombre" validate:"required"`
	Pisos  []int  `json:"pisos"`
}

// ActualizarBloque maneja PUT /api/v1/bloques/:id.
func (h *GeoHandler) ActualizarBloque(c echo.Context) error {
	var req ActualizarBloqueRequest
	if err := c.Bind(&req); err != nil {
		return err
	}
	if err := c.Validate(&req); err != nil {
		return err
	}
	bloque, err := h.svc.ActualizarBloque(c.Request().Context(), c.Param("id"), usecaseGeo.CrearBloqueCmd{
		Codigo: req.Codigo, Nombre: req.Nombre, Pisos: req.Pisos, Actor: extraerActor(c),
	})
	if err != nil {
		return err
	}
	return c.JSON(http.StatusOK, dto.BloqueToResponse(bloque))
}
