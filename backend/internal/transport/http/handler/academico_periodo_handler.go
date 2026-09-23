package handler

import (
	"net/http"

	"github.com/labstack/echo/v4"

	domainAca "github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/transport/http/dto"
	usecaseAca "github.com/siaa/backend/internal/usecase/academico"
)

// ─────────────────────────────────────────────────────────────
// PERIODOS (US-ACA-01)
// ─────────────────────────────────────────────────────────────

func (h *AcademicoHandler) CrearPeriodo(c echo.Context) error {
	var req dto.CrearPeriodoRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "cuerpo de solicitud inválido")
	}

	fIni, err := dto.ParseFechaFlexible(req.FechaInicio)
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "fecha de inicio inválida: use YYYY-MM-DD")
	}
	fFin, err := dto.ParseFechaFlexible(req.FechaFin)
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "fecha de fin inválida: use YYYY-MM-DD")
	}

	var ext *string
	if req.CodigoExterno != "" {
		ext = &req.CodigoExterno
	}

	actor := extraerActorAcademico(c)
	res, err := h.svc.CrearPeriodo(c.Request().Context(), actor, usecaseAca.CrearPeriodoCmd{
		Codigo:        req.Codigo,
		Nombre:        req.Nombre,
		FechaInicio:   fIni,
		FechaFin:      fFin,
		Estado:        domainAca.EstadoPeriodo(req.Estado),
		SedeID:        req.SedeID,
		CodigoExterno: ext,
	})
	if err != nil {
		return mapearErrorAcademico(err)
	}

	return c.JSON(http.StatusCreated, dto.FromPeriodoDomain(res.Periodo, res.Advertencias))
}

func (h *AcademicoHandler) ActualizarPeriodo(c echo.Context) error {
	id := c.Param("id")
	var req dto.CrearPeriodoRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "cuerpo de solicitud inválido")
	}

	fIni, err := dto.ParseFechaFlexible(req.FechaInicio)
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "fecha de inicio inválida: use YYYY-MM-DD")
	}
	fFin, err := dto.ParseFechaFlexible(req.FechaFin)
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "fecha de fin inválida: use YYYY-MM-DD")
	}

	var ext *string
	if req.CodigoExterno != "" {
		ext = &req.CodigoExterno
	}

	actor := extraerActorAcademico(c)
	res, err := h.svc.ActualizarPeriodo(c.Request().Context(), actor, id, usecaseAca.CrearPeriodoCmd{
		Codigo:        req.Codigo,
		Nombre:        req.Nombre,
		FechaInicio:   fIni,
		FechaFin:      fFin,
		Estado:        domainAca.EstadoPeriodo(req.Estado),
		SedeID:        req.SedeID,
		CodigoExterno: ext,
	})
	if err != nil {
		return mapearErrorAcademico(err)
	}

	return c.JSON(http.StatusOK, dto.FromPeriodoDomain(res.Periodo, res.Advertencias))
}

func (h *AcademicoHandler) ObtenerPeriodo(c echo.Context) error {
	id := c.Param("id")
	p, err := h.svc.ObtenerPeriodo(c.Request().Context(), id)
	if err != nil {
		return mapearErrorAcademico(err)
	}
	return c.JSON(http.StatusOK, dto.FromPeriodoDomain(p, nil))
}

func (h *AcademicoHandler) ListarPeriodos(c echo.Context) error {
	sedeID := c.QueryParam("sedeId")
	lista, err := h.svc.ListarPeriodos(c.Request().Context(), sedeID)
	if err != nil {
		return mapearErrorAcademico(err)
	}

	res := make([]dto.PeriodoResponse, 0, len(lista))
	for _, p := range lista {
		res = append(res, dto.FromPeriodoDomain(p, nil))
	}
	return c.JSON(http.StatusOK, res)
}
