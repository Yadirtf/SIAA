package handler

import (
	"net/http"

	"github.com/labstack/echo/v4"

	domainAca "github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/transport/http/dto"
	usecaseAca "github.com/siaa/backend/internal/usecase/academico"
)

// ─────────────────────────────────────────────────────────────
// CALENDARIO DE EXCEPCIONES (US-ACA-04)
// ─────────────────────────────────────────────────────────────

func (h *AcademicoHandler) CrearExcepcion(c echo.Context) error {
	var req dto.CrearExcepcionRequest
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

	actor := extraerActorAcademico(c)
	exc, err := h.svc.CrearExcepcion(c.Request().Context(), actor, usecaseAca.CrearExcepcionCmd{
		Nombre:      req.Nombre,
		Tipo:        domainAca.TipoExcepcion(req.Tipo),
		Ambito:      domainAca.AmbitoExcepcion(req.Ambito),
		AmbitoID:    req.AmbitoID,
		FechaInicio: fIni,
		FechaFin:    fFin,
	})
	if err != nil {
		return mapearErrorAcademico(err)
	}

	return c.JSON(http.StatusCreated, dto.FromExcepcionDomain(exc))
}

func (h *AcademicoHandler) ListarExcepciones(c echo.Context) error {
	lista, err := h.svc.ListarExcepciones(c.Request().Context())
	if err != nil {
		return mapearErrorAcademico(err)
	}

	res := make([]dto.ExcepcionResponse, 0, len(lista))
	for _, e := range lista {
		res = append(res, dto.FromExcepcionDomain(e))
	}
	return c.JSON(http.StatusOK, res)
}

func (h *AcademicoHandler) EliminarExcepcion(c echo.Context) error {
	id := c.Param("id")
	actor := extraerActorAcademico(c)
	if err := h.svc.EliminarExcepcion(c.Request().Context(), actor, id); err != nil {
		return mapearErrorAcademico(err)
	}
	return c.NoContent(http.StatusNoContent)
}
