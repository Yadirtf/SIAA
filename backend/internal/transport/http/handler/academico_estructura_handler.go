package handler

import (
	"net/http"

	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/transport/http/dto"
)

// ─────────────────────────────────────────────────────────────
// ESTRUCTURA: FACULTADES, PROGRAMAS, ASIGNATURAS, GRUPOS (US-ACA-01)
// ─────────────────────────────────────────────────────────────

func (h *AcademicoHandler) CrearFacultad(c echo.Context) error {
	var req dto.CrearFacultadRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "cuerpo de solicitud inválido")
	}
	actor := extraerActorAcademico(c)
	var ext *string
	if req.CodigoExterno != "" {
		ext = &req.CodigoExterno
	}
	f, err := h.svc.CrearFacultad(c.Request().Context(), actor, req.Codigo, req.Nombre, req.SedeID, ext)
	if err != nil {
		return mapearErrorAcademico(err)
	}
	return c.JSON(http.StatusCreated, dto.FromFacultadDomain(f))
}

func (h *AcademicoHandler) ListarFacultades(c echo.Context) error {
	sedeID := c.QueryParam("sedeId")
	lista, err := h.svc.ListarFacultades(c.Request().Context(), sedeID)
	if err != nil {
		return mapearErrorAcademico(err)
	}
	res := make([]dto.FacultadResponse, 0, len(lista))
	for _, f := range lista {
		res = append(res, dto.FromFacultadDomain(f))
	}
	return c.JSON(http.StatusOK, res)
}

func (h *AcademicoHandler) EliminarFacultad(c echo.Context) error {
	id := c.Param("id")
	actor := extraerActorAcademico(c)
	if err := h.svc.EliminarFacultad(c.Request().Context(), actor, id); err != nil {
		return mapearErrorAcademico(err)
	}
	return c.NoContent(http.StatusNoContent)
}

func (h *AcademicoHandler) CrearPrograma(c echo.Context) error {
	var req dto.CrearProgramaRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "cuerpo de solicitud inválido")
	}
	actor := extraerActorAcademico(c)
	var ext *string
	if req.CodigoExterno != "" {
		ext = &req.CodigoExterno
	}
	p, err := h.svc.CrearPrograma(c.Request().Context(), actor, req.Codigo, req.Nombre, req.FacultadID, ext)
	if err != nil {
		return mapearErrorAcademico(err)
	}
	return c.JSON(http.StatusCreated, dto.FromProgramaDomain(p))
}

func (h *AcademicoHandler) ListarProgramas(c echo.Context) error {
	facultadID := c.QueryParam("facultadId")
	lista, err := h.svc.ListarProgramas(c.Request().Context(), facultadID)
	if err != nil {
		return mapearErrorAcademico(err)
	}
	res := make([]dto.ProgramaResponse, 0, len(lista))
	for _, p := range lista {
		res = append(res, dto.FromProgramaDomain(p))
	}
	return c.JSON(http.StatusOK, res)
}

func (h *AcademicoHandler) EliminarPrograma(c echo.Context) error {
	id := c.Param("id")
	actor := extraerActorAcademico(c)
	if err := h.svc.EliminarPrograma(c.Request().Context(), actor, id); err != nil {
		return mapearErrorAcademico(err)
	}
	return c.NoContent(http.StatusNoContent)
}

func (h *AcademicoHandler) CrearAsignatura(c echo.Context) error {
	var req dto.CrearAsignaturaRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "cuerpo de solicitud inválido")
	}
	actor := extraerActorAcademico(c)
	var ext *string
	if req.CodigoExterno != "" {
		ext = &req.CodigoExterno
	}
	a, err := h.svc.CrearAsignatura(c.Request().Context(), actor, req.Codigo, req.Nombre, req.ProgramaID, req.Creditos, ext)
	if err != nil {
		return mapearErrorAcademico(err)
	}
	return c.JSON(http.StatusCreated, dto.FromAsignaturaDomain(a))
}

func (h *AcademicoHandler) ListarAsignaturas(c echo.Context) error {
	programaID := c.QueryParam("programaId")
	lista, err := h.svc.ListarAsignaturas(c.Request().Context(), programaID)
	if err != nil {
		return mapearErrorAcademico(err)
	}
	res := make([]dto.AsignaturaResponse, 0, len(lista))
	for _, a := range lista {
		res = append(res, dto.FromAsignaturaDomain(a))
	}
	return c.JSON(http.StatusOK, res)
}

func (h *AcademicoHandler) EliminarAsignatura(c echo.Context) error {
	id := c.Param("id")
	actor := extraerActorAcademico(c)
	if err := h.svc.EliminarAsignatura(c.Request().Context(), actor, id); err != nil {
		return mapearErrorAcademico(err)
	}
	return c.NoContent(http.StatusNoContent)
}

func (h *AcademicoHandler) CrearGrupo(c echo.Context) error {
	var req dto.CrearGrupoRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "cuerpo de solicitud inválido")
	}
	actor := extraerActorAcademico(c)
	var ext *string
	if req.CodigoExterno != "" {
		ext = &req.CodigoExterno
	}
	g, err := h.svc.CrearGrupo(c.Request().Context(), actor, req.Numero, req.AsignaturaID, req.PeriodoID, req.Cupo, ext)
	if err != nil {
		return mapearErrorAcademico(err)
	}
	return c.JSON(http.StatusCreated, dto.FromGrupoDomain(g))
}

func (h *AcademicoHandler) ListarGrupos(c echo.Context) error {
	asignaturaID := c.QueryParam("asignaturaId")
	periodoID := c.QueryParam("periodoId")
	lista, err := h.svc.ListarGrupos(c.Request().Context(), asignaturaID, periodoID)
	if err != nil {
		return mapearErrorAcademico(err)
	}
	res := make([]dto.GrupoResponse, 0, len(lista))
	for _, g := range lista {
		res = append(res, dto.FromGrupoDomain(g))
	}
	return c.JSON(http.StatusOK, res)
}

func (h *AcademicoHandler) EliminarGrupo(c echo.Context) error {
	id := c.Param("id")
	actor := extraerActorAcademico(c)
	if err := h.svc.EliminarGrupo(c.Request().Context(), actor, id); err != nil {
		return mapearErrorAcademico(err)
	}
	return c.NoContent(http.StatusNoContent)
}
