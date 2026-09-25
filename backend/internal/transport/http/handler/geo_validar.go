// Package handler — endpoint para validación seca de geometría (US-GEO-04, AC-05, T-GEO-04.3).
package handler

import (
	"net/http"

	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/transport/http/dto"
	usecaseGeo "github.com/siaa/backend/internal/usecase/geo"
)

// ValidarGeometria evalúa un polígono contra las reglas geométricas del sistema sin persistir (AC-05).
// POST /api/v1/espacios/validar-geometria
func (h *GeoHandler) ValidarGeometria(c echo.Context) error {
	var req dto.ValidarGeometriaRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "cuerpo de solicitud inválido")
	}
	if err := c.Validate(&req); err != nil {
		return err
	}

	cmd := usecaseGeo.ValidarGeometriaCmd{
		Coordenadas: req.Coordenadas,
		MinAreaM2:   req.MinAreaM2,
		MaxAreaM2:   req.MaxAreaM2,
	}

	res := h.svc.ValidarGeometria(c.Request().Context(), cmd)
	return c.JSON(http.StatusOK, dto.ValidarGeometriaToResponse(res))
}
