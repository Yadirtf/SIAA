package handler

import (
	"net/http"

	"github.com/labstack/echo/v4"
)

// estudiantesGrupoRequest admite ids, documentos o correos (uno por elemento).
type estudiantesGrupoRequest struct {
	Estudiantes []string `json:"estudiantes"`
}

// ListarEstudiantesGrupo devuelve los integrantes del grupo (US-MAR-13).
// GET /api/v1/grupos/:id/estudiantes
func (h *AcademicoHandler) ListarEstudiantesGrupo(c echo.Context) error {
	lista, err := h.svc.ListarEstudiantesGrupo(c.Request().Context(), extraerActorAcademico(c), c.Param("id"))
	if err != nil {
		return mapearErrorAcademico(err)
	}
	return c.JSON(http.StatusOK, lista)
}

// ReemplazarEstudiantesGrupo deja en el grupo exactamente los estudiantes enviados.
// PUT /api/v1/grupos/:id/estudiantes
func (h *AcademicoHandler) ReemplazarEstudiantesGrupo(c echo.Context) error {
	var req estudiantesGrupoRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "cuerpo de solicitud inválido")
	}
	res, err := h.svc.ReemplazarEstudiantesGrupo(c.Request().Context(), extraerActorAcademico(c), c.Param("id"), req.Estudiantes)
	if err != nil {
		return mapearErrorAcademico(err)
	}
	return c.JSON(http.StatusOK, res)
}
