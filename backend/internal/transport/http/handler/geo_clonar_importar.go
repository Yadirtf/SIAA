// Package handler — manejador HTTP para clonación de pisos, buffer e importación/exportación GeoJSON.
// Satisface US-GEO-08 (AC-01..AC-03), US-GEO-11 (AC-01..AC-04), US-GEO-12 (AC-01..AC-03).
package handler

import (
	"encoding/json"
	"io"
	"net/http"

	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/transport/http/dto"
	usecaseGeo "github.com/siaa/backend/internal/usecase/geo"
)

// ClonarPiso maneja POST /api/v1/bloques/:id/clonar-piso (US-GEO-12).
func (h *GeoHandler) ClonarPiso(c echo.Context) error {
	bloqueID := c.Param("id")
	var req dto.ClonarPisoRequest
	if err := c.Bind(&req); err != nil {
		return err
	}
	if err := c.Validate(&req); err != nil {
		return err
	}

	actor := extraerActor(c)
	res, err := h.svc.ClonarPiso(c.Request().Context(), usecaseGeo.ClonarPisoCmd{
		BloqueID:      bloqueID,
		PisoOrigen:    req.PisoOrigen,
		PisoDestino:   req.PisoDestino,
		PrefijoCodigo: req.PrefijoCodigo,
		Actor:         actor,
	})
	if err != nil {
		return err
	}

	return c.JSON(http.StatusOK, res)
}

// ActualizarBuffer maneja PATCH /api/v1/espacios/:id/buffer (US-GEO-08).
func (h *GeoHandler) ActualizarBuffer(c echo.Context) error {
	espacioID := c.Param("id")
	var req dto.ActualizarBufferRequest
	if err := c.Bind(&req); err != nil {
		return err
	}
	if err := c.Validate(&req); err != nil {
		return err
	}

	actor := extraerActor(c)
	espacio, err := h.svc.ActualizarBuffer(c.Request().Context(), usecaseGeo.ActualizarBufferCmd{
		EspacioID:    espacioID,
		BufferMetros: req.BufferMetros,
		Actor:        actor,
	})
	if err != nil {
		return err
	}

	return c.JSON(http.StatusOK, dto.EspacioToResponse(espacio))
}

// PreviewImportarGeoJSON maneja POST /api/v1/espacios/importar/preview (US-GEO-11 AC-01, AC-04).
func (h *GeoHandler) PreviewImportarGeoJSON(c echo.Context) error {
	fileHeader, err := c.FormFile("file")
	var bodyBytes []byte
	if err == nil {
		f, errOpen := fileHeader.Open()
		if errOpen != nil {
			return errOpen
		}
		defer f.Close()
		bodyBytes, err = io.ReadAll(f)
		if err != nil {
			return err
		}
	} else {
		// Fallback: intentar leer JSON directamente del cuerpo de la petición
		b, errRead := io.ReadAll(c.Request().Body)
		if errRead != nil || len(b) == 0 {
			return echo.NewHTTPError(http.StatusBadRequest, "Se requiere archivo GeoJSON (form-data o raw body)")
		}
		bodyBytes = b
	}

	preview, err := h.svc.PreviewImportarGeoJSON(bodyBytes)
	if err != nil {
		return err
	}

	return c.JSON(http.StatusOK, preview)
}

// ConfirmarImportarGeoJSON maneja POST /api/v1/espacios/importar (US-GEO-11 AC-02).
func (h *GeoHandler) ConfirmarImportarGeoJSON(c echo.Context) error {
	var cmd usecaseGeo.ConfirmarImportarGeoJSONCmd
	if err := c.Bind(&cmd); err != nil {
		return err
	}

	cmd.Actor = extraerActor(c)
	creados, err := h.svc.ConfirmarImportarGeoJSON(c.Request().Context(), cmd)
	if err != nil {
		return err
	}

	return c.JSON(http.StatusCreated, map[string]interface{}{
		"totalImportados": creados,
		"mensaje":         "Importación GeoJSON confirmada y procesada",
	})
}

// ExportarGeoJSON maneja GET /api/v1/espacios/exportar (US-GEO-11 AC-03).
func (h *GeoHandler) ExportarGeoJSON(c echo.Context) error {
	sedeID := c.QueryParam("sedeId")
	bloqueID := c.QueryParam("bloqueId")

	fc, err := h.svc.ExportarEspaciosGeoJSON(c.Request().Context(), sedeID, bloqueID)
	if err != nil {
		return err
	}

	c.Response().Header().Set(echo.HeaderContentType, "application/geo+json")
	c.Response().Header().Set("Content-Disposition", "attachment; filename=\"espacios_cartografia.geojson\"")
	return json.NewEncoder(c.Response()).Encode(fc)
}
