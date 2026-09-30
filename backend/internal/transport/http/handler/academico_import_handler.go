// Package handler — manejador HTTP para importación masiva CSV de estructura académica (US-ACA-07).
package handler

import (
	"bytes"
	"io"
	"net/http"

	"github.com/labstack/echo/v4"

	usecaseAca "github.com/siaa/backend/internal/usecase/academico"
)

// PreviewImportarAcademicoCSV maneja POST /api/v1/academico/importar/preview (US-ACA-07 AC-01, AC-02).
func (h *AcademicoHandler) PreviewImportarAcademicoCSV(c echo.Context) error {
	fileHeader, err := c.FormFile("file")
	var r io.Reader
	if err == nil {
		f, errOpen := fileHeader.Open()
		if errOpen != nil {
			return errOpen
		}
		defer f.Close()
		content, _ := io.ReadAll(f)
		r = bytes.NewReader(content)
	} else {
		// Fallback: leer del cuerpo raw
		b, errRead := io.ReadAll(c.Request().Body)
		if errRead != nil || len(b) == 0 {
			return echo.NewHTTPError(http.StatusBadRequest, "Se requiere archivo CSV (form-data o raw body)")
		}
		r = bytes.NewReader(b)
	}

	preview, err := h.svc.ValidarImportacionCSV(r)
	if err != nil {
		return mapearErrorAcademico(err)
	}

	return c.JSON(http.StatusOK, preview)
}

// ConfirmarImportarAcademico maneja POST /api/v1/academico/importar (US-ACA-07 AC-03, AC-04).
func (h *AcademicoHandler) ConfirmarImportarAcademico(c echo.Context) error {
	var cmd usecaseAca.ConfirmarImportacionAcademicaCmd
	if err := c.Bind(&cmd); err != nil {
		return err
	}

	cmd.Actor = extraerActorAcademico(c)
	resultado, err := h.svc.ConfirmarImportacionAcademica(c.Request().Context(), cmd)
	if err != nil {
		return mapearErrorAcademico(err)
	}

	return c.JSON(http.StatusCreated, resultado)
}
