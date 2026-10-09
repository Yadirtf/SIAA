// Package handler — manejador HTTP para clonación de pisos, buffer e importación/exportación GeoJSON y KML.
// Satisface US-GEO-08 (AC-01..AC-03), US-GEO-11 (AC-01..AC-04), US-GEO-12 (AC-01..AC-03).
package handler

import (
	"bytes"
	"encoding/json"
	"io"
	"net/http"
	"path/filepath"
	"strings"

	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/domain/shared"
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
// Acepta GeoJSON o KML en form-data (campo file) o en el cuerpo crudo. El formato se toma de
// ?formato=geojson|kml, de la extensión del archivo o, en su defecto, del contenido.
func (h *GeoHandler) PreviewImportarGeoJSON(c echo.Context) error {
	formato := c.QueryParam("formato")
	var bodyBytes []byte
	if fileHeader, err := c.FormFile("file"); err == nil {
		f, errOpen := fileHeader.Open()
		if errOpen != nil {
			return errOpen
		}
		defer f.Close()
		if bodyBytes, err = io.ReadAll(io.LimitReader(f, maxArchivoCartografia)); err != nil {
			return err
		}
		if formato == "" {
			formato = formatoPorExtension(fileHeader.Filename)
		}
	} else {
		b, errRead := io.ReadAll(io.LimitReader(c.Request().Body, maxArchivoCartografia))
		if errRead != nil || len(b) == 0 {
			return echo.NewHTTPError(http.StatusBadRequest, "Se requiere archivo GeoJSON o KML (form-data o raw body)")
		}
		bodyBytes = b
		if formato == "" && strings.Contains(c.Request().Header.Get(echo.HeaderContentType), "kml") {
			formato = usecaseGeo.FormatoKML
		}
	}

	preview, err := h.svc.PreviewImportar(c.Request().Context(), bodyBytes, formato)
	if err != nil {
		return err
	}
	return c.JSON(http.StatusOK, preview)
}

// maxArchivoCartografia limita el archivo de cartografía importado (10 MiB).
const maxArchivoCartografia = 10 << 20

func formatoPorExtension(nombre string) string {
	switch strings.ToLower(filepath.Ext(nombre)) {
	case ".kml":
		return usecaseGeo.FormatoKML
	case ".geojson", ".json":
		return usecaseGeo.FormatoGeoJSON
	}
	return ""
}

// ConfirmarImportarGeoJSON maneja POST /api/v1/espacios/importar (US-GEO-11 AC-02).
func (h *GeoHandler) ConfirmarImportarGeoJSON(c echo.Context) error {
	var cmd usecaseGeo.ConfirmarImportarGeoJSONCmd
	if err := c.Bind(&cmd); err != nil {
		return err
	}

	cmd.Actor = extraerActor(c)
	res, err := h.svc.ConfirmarImportarGeoJSON(c.Request().Context(), cmd)
	if err != nil {
		return err
	}

	return c.JSON(http.StatusCreated, map[string]interface{}{
		"totalImportados": res.TotalImportados,
		"omitidos":        res.Omitidos,
		"mensaje":         "Importación de cartografía confirmada y procesada",
	})
}

// ExportarGeoJSON maneja GET /api/v1/espacios/exportar?formato=geojson|kml (US-GEO-11 AC-03).
func (h *GeoHandler) ExportarGeoJSON(c echo.Context) error {
	sedeID := c.QueryParam("sedeId")
	bloqueID := c.QueryParam("bloqueId")
	ctx := c.Request().Context()

	switch strings.ToLower(c.QueryParam("formato")) {
	case "", usecaseGeo.FormatoGeoJSON:
		fc, err := h.svc.ExportarEspaciosGeoJSON(ctx, sedeID, bloqueID)
		if err != nil {
			return err
		}
		c.Response().Header().Set(echo.HeaderContentType, "application/geo+json")
		c.Response().Header().Set("Content-Disposition", "attachment; filename=\"espacios_cartografia.geojson\"")
		return json.NewEncoder(c.Response()).Encode(fc)
	case usecaseGeo.FormatoKML:
		var buf bytes.Buffer
		if err := h.svc.ExportarEspaciosKML(ctx, &buf, sedeID, bloqueID); err != nil {
			return err
		}
		c.Response().Header().Set("Content-Disposition", "attachment; filename=\"espacios_cartografia.kml\"")
		return c.Blob(http.StatusOK, "application/vnd.google-earth.kml+xml", buf.Bytes())
	default:
		return shared.NewValidationError("Formato de exportación no soportado; use geojson o kml",
			shared.FieldError{Campo: "formato", Error: "FORMATO_NO_SOPORTADO"})
	}
}
