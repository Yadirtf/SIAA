package handler

import (
	"net/http"

	"github.com/labstack/echo/v4"

	usecaseAca "github.com/siaa/backend/internal/usecase/academico"
)

// ReprogramarSesionRequest es el cuerpo de PATCH /sesiones/:id/reprogramar (US-ACA-06 AC-01).
type ReprogramarSesionRequest struct {
	Fecha      string `json:"fecha"`      // AAAA-MM-DD
	HoraInicio string `json:"horaInicio"` // HH:MM
	HoraFin    string `json:"horaFin"`    // HH:MM
	Motivo     string `json:"motivo"`
	Confirmar  bool   `json:"confirmar,omitempty"`
}

// ReprogramarSesion mueve una sesión a otra fecha u hora con motivo obligatorio.
// PATCH /api/v1/sesiones/:id/reprogramar
func (h *AcademicoHandler) ReprogramarSesion(c echo.Context) error {
	var req ReprogramarSesionRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "cuerpo de solicitud inválido")
	}
	sesion, err := h.svc.ReprogramarSesion(c.Request().Context(), c.Param("id"),
		usecaseAca.ReprogramacionSesion{Fecha: req.Fecha, HoraInicio: req.HoraInicio, HoraFin: req.HoraFin},
		usecaseAca.CambioSesion{Motivo: req.Motivo, Confirmar: req.Confirmar}, extraerActorAcademico(c))
	if err != nil {
		return mapearErrorAcademico(err)
	}
	return c.JSON(http.StatusOK, sesionToDTO(sesion))
}
