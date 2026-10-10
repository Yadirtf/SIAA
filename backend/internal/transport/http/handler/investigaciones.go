// Package handler — investigaciones que suspenden la retención de datos (US-AUD-04 AC-03).
// GET  /privacidad/investigaciones               — en curso (auditoria:leer)
// POST /privacidad/investigaciones               — marcar un usuario, sesión o marcaje (auditoria:investigar)
// POST /privacidad/investigaciones/:id/liberar   — cerrar la investigación (auditoria:investigar)
package handler

import (
	"net/http"
	"time"

	"github.com/labstack/echo/v4"

	domain "github.com/siaa/backend/internal/domain/privacidad"
	mw "github.com/siaa/backend/internal/transport/http/middleware"
	"github.com/siaa/backend/internal/usecase/privacidad"
)

// InvestigacionesHandler expone la gestión de investigaciones en curso.
type InvestigacionesHandler struct {
	svc *privacidad.Investigaciones
}

// NewInvestigacionesHandler crea el handler.
func NewInvestigacionesHandler(svc *privacidad.Investigaciones) *InvestigacionesHandler {
	return &InvestigacionesHandler{svc: svc}
}

type investigacionRequest struct {
	Alcance    string `json:"alcance"`
	ObjetivoID string `json:"objetivoId"`
	Motivo     string `json:"motivo"`
}

type investigacionResponse struct {
	ID          string     `json:"id"`
	Alcance     string     `json:"alcance"`
	ObjetivoID  string     `json:"objetivoId"`
	Motivo      string     `json:"motivo"`
	CreadaPor   string     `json:"creadaPor"`
	CreadaEn    time.Time  `json:"creadaEn"`
	Activa      bool       `json:"activa"`
	LiberadaPor string     `json:"liberadaPor,omitempty"`
	LiberadaEn  *time.Time `json:"liberadaEn,omitempty"`
}

func investigacionDTO(i *domain.Investigacion) investigacionResponse {
	return investigacionResponse{
		ID: i.ID, Alcance: string(i.Alcance), ObjetivoID: i.ObjetivoID, Motivo: i.Motivo,
		CreadaPor: i.CreadaPor, CreadaEn: i.CreadaEn, Activa: i.Activa(),
		LiberadaPor: i.LiberadaPor, LiberadaEn: i.LiberadaEn,
	}
}

func actorInvestigacion(c echo.Context) string {
	if claims, ok := mw.GetClaims(c); ok && claims != nil {
		return claims.UsuarioID
	}
	return ""
}

// Listar devuelve las investigaciones en curso.
func (h *InvestigacionesHandler) Listar(c echo.Context) error {
	activas, err := h.svc.Activas(c.Request().Context())
	if err != nil {
		return err
	}
	items := make([]investigacionResponse, 0, len(activas))
	for _, i := range activas {
		items = append(items, investigacionDTO(i))
	}
	return c.JSON(http.StatusOK, map[string]interface{}{"items": items, "total": len(items)})
}

// Marcar suspende la retención de los registros indicados.
func (h *InvestigacionesHandler) Marcar(c echo.Context) error {
	var req investigacionRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "cuerpo de solicitud inválido")
	}
	inv, err := h.svc.Marcar(c.Request().Context(), actorInvestigacion(c), privacidad.SolicitudInvestigacion{
		Alcance: domain.AlcanceInvestigacion(req.Alcance), ObjetivoID: req.ObjetivoID, Motivo: req.Motivo,
	})
	if err != nil {
		return err
	}
	return c.JSON(http.StatusCreated, investigacionDTO(inv))
}

// Liberar cierra la investigación.
func (h *InvestigacionesHandler) Liberar(c echo.Context) error {
	inv, err := h.svc.Liberar(c.Request().Context(), actorInvestigacion(c), c.Param("id"))
	if err != nil {
		return err
	}
	return c.JSON(http.StatusOK, investigacionDTO(inv))
}
