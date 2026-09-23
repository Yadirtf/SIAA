package handler

import (
	"net/http"
	"time"

	"github.com/labstack/echo/v4"

	domainAca "github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/transport/http/dto"
	usecaseAca "github.com/siaa/backend/internal/usecase/academico"
)

// ─────────────────────────────────────────────────────────────
// ASIGNACIONES (US-ACA-02, US-ACA-03)
// ─────────────────────────────────────────────────────────────

func (h *AcademicoHandler) CrearAsignacion(c echo.Context) error {
	var req dto.CrearAsignacionRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "cuerpo de solicitud inválido")
	}

	var fIni, fFin time.Time
	if req.FechaInicio != "" {
		fIni, _ = dto.ParseFechaFlexible(req.FechaInicio)
	}
	if req.FechaFin != "" {
		fFin, _ = dto.ParseFechaFlexible(req.FechaFin)
	}

	var ext *string
	if req.CodigoExterno != "" {
		ext = &req.CodigoExterno
	}

	actor := extraerActorAcademico(c)
	cmd := usecaseAca.CrearAsignacionCmd{
		PeriodoID:          req.PeriodoID,
		DocenteIDs:         req.DocenteIDs,
		DocenteNombre:      req.DocenteNombre,
		GrupoID:            req.GrupoID,
		AsignaturaID:       req.AsignaturaID,
		FacultadID:         req.FacultadID,
		EspacioID:          req.EspacioID,
		EspacioNombre:      req.EspacioNombre,
		DiaSemana:          req.Franja.DiaSemana,
		HoraInicio:         req.Franja.HoraInicio,
		HoraFin:            req.Franja.HoraFin,
		ZonaHoraria:        req.Franja.ZonaHoraria,
		Modalidad:          domainAca.ModalidadAsignacion(req.Modalidad),
		ParametrosOverride: req.ParametrosOverride,
		FechaInicio:        fIni,
		FechaFin:           fFin,
		CodigoExterno:      ext,
	}

	res, err := h.svc.CrearAsignacion(c.Request().Context(), actor, cmd)
	if err != nil {
		return mapearErrorAcademico(err)
	}

	return c.JSON(http.StatusCreated, dto.FromAsignacionDomain(res.Asignacion, res.Advertencias))
}

func (h *AcademicoHandler) ListarAsignaciones(c echo.Context) error {
	periodoID := c.QueryParam("periodoId")
	lista, err := h.svc.ListarAsignaciones(c.Request().Context(), periodoID)
	if err != nil {
		return mapearErrorAcademico(err)
	}

	res := make([]dto.AsignacionResponse, 0, len(lista))
	for _, a := range lista {
		res = append(res, dto.FromAsignacionDomain(&a, nil))
	}
	return c.JSON(http.StatusOK, res)
}

func (h *AcademicoHandler) EliminarAsignacion(c echo.Context) error {
	id := c.Param("id")
	actor := extraerActorAcademico(c)
	if err := h.svc.EliminarAsignacion(c.Request().Context(), actor, id); err != nil {
		return mapearErrorAcademico(err)
	}
	return c.NoContent(http.StatusNoContent)
}
