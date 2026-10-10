// Package handler — manejador HTTP de la carga masiva académica en CSV o XLSX (US-ACA-07).
package handler

import (
	"io"
	"net/http"
	"strings"

	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/platform/importar"
)

// leerArchivoCarga toma el archivo del campo multipart "file" (o "archivo") o del cuerpo crudo.
func leerArchivoCarga(c echo.Context) (string, []byte, error) {
	for _, campo := range []string{"file", "archivo"} {
		fh, err := c.FormFile(campo)
		if err != nil {
			continue
		}
		if fh.Size > importar.TamanoMaximo {
			return "", nil, echo.NewHTTPError(http.StatusRequestEntityTooLarge, "El archivo supera el tamaño permitido")
		}
		f, err := fh.Open()
		if err != nil {
			return "", nil, err
		}
		defer f.Close()
		b, err := io.ReadAll(io.LimitReader(f, importar.TamanoMaximo+1))
		return fh.Filename, b, err
	}
	b, err := io.ReadAll(io.LimitReader(c.Request().Body, importar.TamanoMaximo+1))
	if err != nil || len(b) == 0 {
		return "", nil, echo.NewHTTPError(http.StatusBadRequest, "Se requiere un archivo CSV o XLSX (form-data o cuerpo)")
	}
	return "carga.csv", b, nil
}

// PreviewImportarAcademicoCSV maneja POST /academico/importar/preview: informe por fila sin persistir (AC-01).
func (h *AcademicoHandler) PreviewImportarAcademicoCSV(c echo.Context) error {
	_, contenido, err := leerArchivoCarga(c)
	if err != nil {
		return err
	}
	preview, err := h.svc.PreviewImportacion(c.Request().Context(), extraerActorAcademico(c), contenido)
	if err != nil {
		return mapearErrorAcademico(err)
	}
	return c.JSON(http.StatusOK, preview)
}

// DiagnosticoImportarAcademico maneja POST /academico/importar/diagnostico: el mismo archivo
// con una columna de diagnóstico por fila (AC-02).
func (h *AcademicoHandler) DiagnosticoImportarAcademico(c echo.Context) error {
	nombre, contenido, err := leerArchivoCarga(c)
	if err != nil {
		return err
	}
	salida, tipo, err := h.svc.DiagnosticoImportacion(c.Request().Context(), extraerActorAcademico(c), contenido)
	if err != nil {
		return mapearErrorAcademico(err)
	}
	base := strings.TrimSuffix(strings.TrimSuffix(nombre, ".csv"), ".xlsx")
	ext := ".csv"
	if strings.Contains(tipo, "spreadsheet") {
		ext = ".xlsx"
	}
	c.Response().Header().Set("Content-Disposition", `attachment; filename="`+base+`-diagnostico`+ext+`"`)
	return c.Blob(http.StatusOK, tipo, salida)
}

// ConfirmarImportarAcademico maneja POST /academico/importar: revalida el archivo y lo aplica
// como un lote; si supera el umbral de errores responde 422 sin aplicar nada (AC-03, AC-06).
func (h *AcademicoHandler) ConfirmarImportarAcademico(c echo.Context) error {
	nombre, contenido, err := leerArchivoCarga(c)
	if err != nil {
		return err
	}
	res, err := h.svc.ConfirmarImportacion(c.Request().Context(), extraerActorAcademico(c), nombre, contenido)
	if err != nil {
		return mapearErrorAcademico(err)
	}
	if !res.Aplicada {
		return c.JSON(http.StatusUnprocessableEntity, res)
	}
	return c.JSON(http.StatusCreated, res)
}

// PlantillaImportarAcademico maneja GET /academico/importar/plantilla?formato=csv|xlsx (T-ACA-07.1).
func (h *AcademicoHandler) PlantillaImportarAcademico(c echo.Context) error {
	formato := importar.FormatoCSV
	if strings.EqualFold(c.QueryParam("formato"), "xlsx") {
		formato = importar.FormatoXLSX
	}
	salida, tipo, err := importar.Plantilla(formato)
	if err != nil {
		return err
	}
	c.Response().Header().Set("Content-Disposition", `attachment; filename="plantilla-carga-academica.`+strings.ToLower(formato)+`"`)
	return c.Blob(http.StatusOK, tipo, salida)
}
