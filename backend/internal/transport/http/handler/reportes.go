// Package handler — reporte de cumplimiento y su exportación (RF-REP-001, RF-REP-004).
package handler

import (
	"fmt"
	"net/http"

	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/transport/http/middleware"
	"github.com/siaa/backend/internal/usecase/reportes"
)

// ReportesHandler expone el reporte de cumplimiento docente.
type ReportesHandler struct {
	svc *reportes.Service
}

// NewReportesHandler crea el handler de reportes.
func NewReportesHandler(svc *reportes.Service) *ReportesHandler {
	return &ReportesHandler{svc: svc}
}

func actorReportes(c echo.Context) reportes.Actor {
	a := reportes.Actor{Alcance: middleware.AlcanceDe(c)}
	if claims, ok := middleware.GetClaims(c); ok {
		a.UsuarioID, a.RolActivo = claims.UsuarioID, claims.RolActivo
	}
	return a
}

func filtroReporte(c echo.Context) reportes.Filtro {
	return reportes.Filtro{
		PeriodoID:  c.QueryParam("periodoId"),
		FacultadID: c.QueryParam("facultadId"),
		ProgramaID: c.QueryParam("programaId"),
		DocenteID:  c.QueryParam("docenteId"),
		Desde:      c.QueryParam("desde"),
		Hasta:      c.QueryParam("hasta"),
	}
}

// Cumplimiento maneja GET /reportes/cumplimiento?periodoId=&facultadId=&programaId=&docenteId=&desde=&hasta=.
func (h *ReportesHandler) Cumplimiento(c echo.Context) error {
	rep, err := h.svc.Cumplimiento(c.Request().Context(), actorReportes(c), filtroReporte(c))
	if err != nil {
		return err
	}
	return c.JSON(http.StatusOK, rep)
}

// ExportarCumplimiento maneja GET /reportes/cumplimiento/exportar?formato=xlsx|pdf&... .
func (h *ReportesHandler) ExportarCumplimiento(c echo.Context) error {
	arch, err := h.svc.ExportarCumplimiento(c.Request().Context(), actorReportes(c), filtroReporte(c), c.QueryParam("formato"))
	if err != nil {
		return err
	}
	return enviarArchivo(c, arch.Nombre, arch.Mime, arch.Contenido)
}

// enviarArchivo entrega un archivo generado como descarga.
func enviarArchivo(c echo.Context, nombre, mime string, contenido []byte) error {
	c.Response().Header().Set("Content-Disposition", fmt.Sprintf("attachment; filename=%q", nombre))
	c.Response().Header().Set("X-Content-Type-Options", "nosniff")
	return c.Blob(http.StatusOK, mime, contenido)
}
