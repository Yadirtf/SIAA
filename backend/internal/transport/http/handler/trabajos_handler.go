package handler

import (
	"net/http"

	"github.com/labstack/echo/v4"
)

// ObtenerTrabajo consulta el estado y el resultado de un trabajo asíncrono (US-ACA-05 AC-04).
// GET /api/v1/trabajos/:id
func (h *AcademicoHandler) ObtenerTrabajo(c echo.Context) error {
	t, err := h.svc.ObtenerTrabajo(c.Request().Context(), extraerActorAcademico(c), c.Param("id"))
	if err != nil {
		return mapearErrorAcademico(err)
	}
	return c.JSON(http.StatusOK, t)
}
