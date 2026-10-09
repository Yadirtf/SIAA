// Package handler — tablero en vivo, ocupación de espacios y asistencia estudiantil
// (US-REP-03, US-REP-04, US-REP-05).
package handler

import (
	"net/http"

	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/usecase/reportes"
)

// WithTablero habilita GET /reportes/tablero (US-REP-03).
func (h *ReportesHandler) WithTablero(t *reportes.TableroService) *ReportesHandler {
	h.tablero = t
	return h
}

// WithOcupacion habilita el reporte de ocupación y su exportación (US-REP-04).
func (h *ReportesHandler) WithOcupacion(o *reportes.OcupacionService) *ReportesHandler {
	h.ocupacion = o
	return h
}

// WithAsistenciaGrupos habilita el reporte de asistencia estudiantil (US-REP-05).
func (h *ReportesHandler) WithAsistenciaGrupos(a *reportes.AsistenciaGrupoService) *ReportesHandler {
	h.asistencia = a
	return h
}

func noDisponible() error {
	return echo.NewHTTPError(http.StatusServiceUnavailable, "reporte no disponible en esta instalación")
}

// Tablero maneja GET /reportes/tablero?facultadId= .
func (h *ReportesHandler) Tablero(c echo.Context) error {
	if h.tablero == nil {
		return noDisponible()
	}
	tab, err := h.tablero.Calcular(c.Request().Context(), actorReportes(c), c.QueryParam("facultadId"))
	if err != nil {
		return err
	}
	c.Response().Header().Set("Cache-Control", "no-store")
	return c.JSON(http.StatusOK, tab)
}

func filtroOcupacion(c echo.Context) reportes.FiltroOcupacion {
	return reportes.FiltroOcupacion{
		PeriodoID:  c.QueryParam("periodoId"),
		FacultadID: c.QueryParam("facultadId"),
		SedeID:     c.QueryParam("sedeId"),
		BloqueID:   c.QueryParam("bloqueId"),
		Desde:      c.QueryParam("desde"),
		Hasta:      c.QueryParam("hasta"),
		Agrupacion: c.QueryParam("agrupacion"),
	}
}

// Ocupacion maneja GET /reportes/ocupacion?agrupacion=aula|bloque|sede&periodoId=&desde=&hasta=&sedeId=&bloqueId=&facultadId= .
func (h *ReportesHandler) Ocupacion(c echo.Context) error {
	if h.ocupacion == nil {
		return noDisponible()
	}
	rep, err := h.ocupacion.Calcular(c.Request().Context(), actorReportes(c), filtroOcupacion(c))
	if err != nil {
		return err
	}
	return c.JSON(http.StatusOK, rep)
}

// ExportarOcupacion maneja GET /reportes/ocupacion/exportar?formato=xlsx|pdf&... .
func (h *ReportesHandler) ExportarOcupacion(c echo.Context) error {
	if h.ocupacion == nil {
		return noDisponible()
	}
	arch, err := h.ocupacion.Exportar(c.Request().Context(), actorReportes(c), filtroOcupacion(c), c.QueryParam("formato"))
	if err != nil {
		return err
	}
	return enviarArchivo(c, arch.Nombre, arch.Mime, arch.Contenido)
}

// AsistenciaGrupo maneja GET /reportes/asistencia-estudiantil?grupoId= .
func (h *ReportesHandler) AsistenciaGrupo(c echo.Context) error {
	if h.asistencia == nil {
		return noDisponible()
	}
	rep, err := h.asistencia.DelGrupo(c.Request().Context(), actorReportes(c), c.QueryParam("grupoId"))
	if err != nil {
		return err
	}
	return c.JSON(http.StatusOK, rep)
}

// GruposAsistencia maneja GET /reportes/asistencia-estudiantil/grupos?periodoId= .
func (h *ReportesHandler) GruposAsistencia(c echo.Context) error {
	if h.asistencia == nil {
		return noDisponible()
	}
	grupos, err := h.asistencia.GruposVisibles(c.Request().Context(), actorReportes(c), c.QueryParam("periodoId"))
	if err != nil {
		return err
	}
	return c.JSON(http.StatusOK, grupos)
}
