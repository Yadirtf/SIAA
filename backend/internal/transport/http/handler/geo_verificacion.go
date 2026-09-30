// Package handler — configuración de la verificación complementaria de un espacio (RF-GEO-016).
package handler

import (
	"net/http"

	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/domain/geo"
	"github.com/siaa/backend/internal/transport/http/dto"
	usecaseGeo "github.com/siaa/backend/internal/usecase/geo"
)

// ActualizarVerificacion maneja PUT /api/v1/espacios/:id/verificacion.
func (h *GeoHandler) ActualizarVerificacion(c echo.Context) error {
	var req dto.VerificacionEspacioDTO
	if err := c.Bind(&req); err != nil {
		return err
	}
	espacio, err := h.svc.ActualizarVerificacion(c.Request().Context(), usecaseGeo.ActualizarVerificacionCmd{
		EspacioID: c.Param("id"),
		Verificacion: geo.VerificacionEspacio{
			WifiBssids: req.WifiBssids,
			BleUUID:    req.BleUUID,
			QrCodigo:   req.QrCodigo,
		},
		Actor: extraerActor(c),
	})
	if err != nil {
		return err
	}
	return c.JSON(http.StatusOK, dto.EspacioToResponse(espacio))
}
