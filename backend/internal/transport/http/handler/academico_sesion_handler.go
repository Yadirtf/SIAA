// Package handler — manejador HTTP para generación y administración de sesiones académicas.
// Satisface US-ACA-05, US-ACA-06, US-ACA-08.
package handler

import (
	"net/http"

	"github.com/labstack/echo/v4"

	domainAca "github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/repository"
	usecaseAca "github.com/siaa/backend/internal/usecase/academico"
)

type GenerarSesionesRequest struct {
	AsignacionID *string `json:"asignacionId,omitempty"`
}

type CancelarSesionRequest struct {
	Motivo string `json:"motivo" validate:"required"`
}

type ReasignarAulaRequest struct {
	NuevoEspacioID string `json:"nuevoEspacioId" validate:"required"`
	Motivo         string `json:"motivo,omitempty"`
}

type SesionResponseDTO struct {
	ID                      string                 `json:"id"`
	PeriodoID               string                 `json:"periodoId"`
	AsignacionID            string                 `json:"asignacionId"`
	AsignaturaID            string                 `json:"asignaturaId"`
	GrupoID                 string                 `json:"grupoId"`
	DocenteIDs              []string               `json:"docenteIds"`
	EspacioID               string                 `json:"espacioId"`
	Fecha                   string                 `json:"fecha"`
	HoraInicio              string                 `json:"horaInicio"`
	HoraFin                 string                 `json:"horaFin"`
	InicioProgramado        string                 `json:"inicioProgramado"`
	FinProgramado           string                 `json:"finProgramado"`
	VentanaEntradaAbre      string                 `json:"ventanaEntradaAbre"`
	VentanaEntradaCierra    string                 `json:"ventanaEntradaCierra"`
	VentanaSalidaAbre       *string                `json:"ventanaSalidaAbre,omitempty"`
	VentanaSalidaCierra     *string                `json:"ventanaSalidaCierra,omitempty"`
	Estado                  string                 `json:"estado"`
	EspacioVersionGeometria int                    `json:"espacioVersionGeometria"`
	ParametrosCongelados    map[string]interface{} `json:"parametrosCongelados"`
	MotivoCancelacion       string                 `json:"motivoCancelacion,omitempty"`
}

// GenerarSesiones maneja POST /api/v1/periodos/:id/generar-sesiones (US-ACA-05).
func (h *AcademicoHandler) GenerarSesiones(c echo.Context) error {
	periodoID := c.Param("id")
	var req GenerarSesionesRequest
	_ = c.Bind(&req)

	actor := extraerActorAcademico(c)
	informe, err := h.svc.GenerarSesiones(c.Request().Context(), usecaseAca.GenerarSesionesCmd{
		PeriodoID:    periodoID,
		AsignacionID: req.AsignacionID,
		Actor:        actor,
	})
	if err != nil {
		return mapearErrorAcademico(err)
	}

	return c.JSON(http.StatusOK, informe)
}

// ListarSesiones maneja GET /api/v1/sesiones.
func (h *AcademicoHandler) ListarSesiones(c echo.Context) error {
	filter := repository.SesionFilter{
		PeriodoID:    c.QueryParam("periodoId"),
		AsignacionID: c.QueryParam("asignacionId"),
		DocenteID:    c.QueryParam("docenteId"),
		EspacioID:    c.QueryParam("espacioId"),
		Fecha:        c.QueryParam("fecha"),
	}
	if estStr := c.QueryParam("estado"); estStr != "" {
		st := domainAca.EstadoSesion(estStr)
		filter.Estado = &st
	}

	sesiones, err := h.svc.ListarSesiones(c.Request().Context(), filter)
	if err != nil {
		return mapearErrorAcademico(err)
	}

	res := make([]SesionResponseDTO, len(sesiones))
	for i, s := range sesiones {
		res[i] = sesionToDTO(s)
	}
	return c.JSON(http.StatusOK, res)
}

// ObtenerSesion maneja GET /api/v1/sesiones/:id.
func (h *AcademicoHandler) ObtenerSesion(c echo.Context) error {
	id := c.Param("id")
	sesion, err := h.svc.ObtenerSesionPorID(c.Request().Context(), id)
	if err != nil {
		return mapearErrorAcademico(err)
	}
	return c.JSON(http.StatusOK, sesionToDTO(sesion))
}

// CancelarSesion maneja POST /api/v1/sesiones/:id/cancelar (US-ACA-08).
func (h *AcademicoHandler) CancelarSesion(c echo.Context) error {
	id := c.Param("id")
	var req CancelarSesionRequest
	if err := c.Bind(&req); err != nil {
		return err
	}
	if err := c.Validate(&req); err != nil {
		return err
	}

	actor := extraerActorAcademico(c)
	if err := h.svc.CancelarSesion(c.Request().Context(), id, req.Motivo, actor); err != nil {
		return mapearErrorAcademico(err)
	}
	return c.NoContent(http.StatusNoContent)
}

// ReasignarAulaSesion maneja PUT /api/v1/sesiones/:id/aula (US-ACA-06).
func (h *AcademicoHandler) ReasignarAulaSesion(c echo.Context) error {
	id := c.Param("id")
	var req ReasignarAulaRequest
	if err := c.Bind(&req); err != nil {
		return err
	}
	if err := c.Validate(&req); err != nil {
		return err
	}

	actor := extraerActorAcademico(c)
	sesion, err := h.svc.ReasignarAulaSesion(c.Request().Context(), id, req.NuevoEspacioID, req.Motivo, actor)
	if err != nil {
		return mapearErrorAcademico(err)
	}
	return c.JSON(http.StatusOK, sesionToDTO(sesion))
}

func sesionToDTO(s *domainAca.Sesion) SesionResponseDTO {
	dto := SesionResponseDTO{
		ID:                      s.ID(),
		PeriodoID:               s.PeriodoID(),
		AsignacionID:            s.AsignacionID(),
		AsignaturaID:            s.AsignaturaID(),
		GrupoID:                 s.GrupoID(),
		DocenteIDs:              s.DocenteIDs(),
		EspacioID:               s.EspacioID(),
		Fecha:                   s.Fecha(),
		HoraInicio:              s.HoraInicio(),
		HoraFin:                 s.HoraFin(),
		InicioProgramado:        s.InicioProgramado().Format("2006-01-02T15:04:05Z07:00"),
		FinProgramado:           s.FinProgramado().Format("2006-01-02T15:04:05Z07:00"),
		VentanaEntradaAbre:      s.VentanaEntradaAbre().Format("2006-01-02T15:04:05Z07:00"),
		VentanaEntradaCierra:    s.VentanaEntradaCierra().Format("2006-01-02T15:04:05Z07:00"),
		Estado:                  string(s.Estado()),
		EspacioVersionGeometria: s.EspacioVersionGeometria(),
		ParametrosCongelados:    s.ParametrosCongelados(),
		MotivoCancelacion:       s.MotivoCancelacion(),
	}
	if s.VentanaSalidaAbre() != nil {
		v := s.VentanaSalidaAbre().Format("2006-01-02T15:04:05Z07:00")
		dto.VentanaSalidaAbre = &v
	}
	if s.VentanaSalidaCierra() != nil {
		v := s.VentanaSalidaCierra().Format("2006-01-02T15:04:05Z07:00")
		dto.VentanaSalidaCierra = &v
	}
	return dto
}
