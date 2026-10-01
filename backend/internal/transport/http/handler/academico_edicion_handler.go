package handler

import (
	"net/http"

	"github.com/labstack/echo/v4"

	domainAca "github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/transport/http/dto"
	usecaseAca "github.com/siaa/backend/internal/usecase/academico"
)

// ─────────────────────────────────────────────────────────────
// EDICIÓN de asignaciones y estructura curricular (US-ACA-01 AC-04, US-ACA-03)
// ─────────────────────────────────────────────────────────────

// ActualizarAsignacionResponse informa además cómo quedaron las sesiones futuras.
type ActualizarAsignacionResponse struct {
	dto.AsignacionResponse
	SesionesReemplazadas int `json:"sesionesReemplazadas"`
	SesionesGeneradas    int `json:"sesionesGeneradas"`
}

// ActualizarAsignacion maneja PUT /api/v1/asignaciones/:id.
func (h *AcademicoHandler) ActualizarAsignacion(c echo.Context) error {
	var req dto.CrearAsignacionRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "cuerpo de solicitud inválido")
	}
	res, err := h.svc.ActualizarAsignacion(c.Request().Context(), extraerActorAcademico(c), c.Param("id"), usecaseAca.CrearAsignacionCmd{
		DocenteIDs:  req.DocenteIDs,
		GrupoID:     req.GrupoID,
		EspacioID:   req.EspacioID,
		DiaSemana:   req.Franja.DiaSemana,
		HoraInicio:  req.Franja.HoraInicio,
		HoraFin:     req.Franja.HoraFin,
		ZonaHoraria: req.Franja.ZonaHoraria,
		Modalidad:   domainAca.ModalidadAsignacion(req.Modalidad),
	})
	if err != nil {
		return mapearErrorAcademico(err)
	}
	return c.JSON(http.StatusOK, ActualizarAsignacionResponse{
		AsignacionResponse:   dto.FromAsignacionDomain(res.Asignacion, res.Advertencias),
		SesionesReemplazadas: res.SesionesReemplazadas,
		SesionesGeneradas:    res.SesionesGeneradas,
	})
}

// ActualizarFacultad maneja PUT /api/v1/facultades/:id.
func (h *AcademicoHandler) ActualizarFacultad(c echo.Context) error {
	var req dto.CrearFacultadRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "cuerpo de solicitud inválido")
	}
	f, err := h.svc.ActualizarFacultad(c.Request().Context(), extraerActorAcademico(c), c.Param("id"), req.Codigo, req.Nombre)
	if err != nil {
		return mapearErrorAcademico(err)
	}
	return c.JSON(http.StatusOK, dto.FromFacultadDomain(f))
}

// ActualizarPrograma maneja PUT /api/v1/programas/:id.
func (h *AcademicoHandler) ActualizarPrograma(c echo.Context) error {
	var req dto.CrearProgramaRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "cuerpo de solicitud inválido")
	}
	p, err := h.svc.ActualizarPrograma(c.Request().Context(), extraerActorAcademico(c), c.Param("id"), req.Codigo, req.Nombre)
	if err != nil {
		return mapearErrorAcademico(err)
	}
	return c.JSON(http.StatusOK, dto.FromProgramaDomain(p))
}

// ActualizarAsignatura maneja PUT /api/v1/asignaturas/:id.
func (h *AcademicoHandler) ActualizarAsignatura(c echo.Context) error {
	var req dto.CrearAsignaturaRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "cuerpo de solicitud inválido")
	}
	a, err := h.svc.ActualizarAsignatura(c.Request().Context(), extraerActorAcademico(c), c.Param("id"), req.Codigo, req.Nombre, req.Creditos)
	if err != nil {
		return mapearErrorAcademico(err)
	}
	return c.JSON(http.StatusOK, dto.FromAsignaturaDomain(a))
}

// ActualizarGrupo maneja PUT /api/v1/grupos/:id.
func (h *AcademicoHandler) ActualizarGrupo(c echo.Context) error {
	var req dto.CrearGrupoRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "cuerpo de solicitud inválido")
	}
	g, err := h.svc.ActualizarGrupo(c.Request().Context(), extraerActorAcademico(c), c.Param("id"), req.Numero, req.Cupo)
	if err != nil {
		return mapearErrorAcademico(err)
	}
	return c.JSON(http.StatusOK, dto.FromGrupoDomain(g))
}
