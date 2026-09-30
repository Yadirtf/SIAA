// Package handler — aviso de privacidad y consentimiento informado (US-LEG-01, RNF-LEG-003).
package handler

import (
	"net/http"

	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/transport/http/middleware"
	"github.com/siaa/backend/internal/usecase/privacidad"
)

// PrivacidadHandler expone la política vigente y la decisión del titular.
type PrivacidadHandler struct {
	svc *privacidad.Service
}

// NewPrivacidadHandler crea el handler de privacidad.
func NewPrivacidadHandler(svc *privacidad.Service) *PrivacidadHandler {
	return &PrivacidadHandler{svc: svc}
}

// Servicio da acceso al caso de uso (lo usa el middleware que exige consentimiento).
func (h *PrivacidadHandler) Servicio() *privacidad.Service { return h.svc }

// Politica maneja GET /privacidad/politica (público).
func (h *PrivacidadHandler) Politica(c echo.Context) error {
	return c.JSON(http.StatusOK, h.svc.Politica())
}

// Estado maneja GET /me/consentimiento.
func (h *PrivacidadHandler) Estado(c echo.Context) error {
	claims, ok := middleware.GetClaims(c)
	if !ok {
		return shared.NewPermissionError()
	}
	e, err := h.svc.Estado(c.Request().Context(), claims.UsuarioID)
	if err != nil {
		return err
	}
	return c.JSON(http.StatusOK, e)
}

type decisionConsentimientoRequest struct {
	Version       string `json:"version"`
	Acepta        *bool  `json:"acepta"`
	DispositivoID string `json:"dispositivoId"`
}

// Decidir maneja POST /me/consentimiento {version, acepta, dispositivoId}.
func (h *PrivacidadHandler) Decidir(c echo.Context) error {
	claims, ok := middleware.GetClaims(c)
	if !ok {
		return shared.NewPermissionError()
	}
	var req decisionConsentimientoRequest
	if err := c.Bind(&req); err != nil || req.Version == "" || req.Acepta == nil {
		return shared.NewValidationError("Indique la versión de la política y si la acepta",
			shared.FieldError{Campo: "acepta", Error: "REQUERIDO"})
	}
	e, err := h.svc.Decidir(c.Request().Context(), privacidad.SolicitudDecision{
		UsuarioID: claims.UsuarioID, Version: req.Version, Acepta: *req.Acepta,
		DispositivoID: req.DispositivoID, IPOrigen: c.RealIP(),
	})
	if err != nil {
		return err
	}
	return c.JSON(http.StatusOK, e)
}
