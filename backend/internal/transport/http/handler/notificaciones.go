// Package handler — tokens push, preferencias y bandeja de avisos (EP-10).
package handler

import (
	"net/http"
	"strconv"

	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/domain/notificacion"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/transport/http/middleware"
	"github.com/siaa/backend/internal/usecase/notificaciones"
)

// NotificacionesHandler expone /me/notificaciones.
type NotificacionesHandler struct {
	svc *notificaciones.Service
}

// NewNotificacionesHandler crea el handler de notificaciones del usuario.
func NewNotificacionesHandler(svc *notificaciones.Service) *NotificacionesHandler {
	return &NotificacionesHandler{svc: svc}
}

func usuarioActual(c echo.Context) (string, error) {
	claims, ok := middleware.GetClaims(c)
	if !ok || claims.UsuarioID == "" {
		return "", shared.NewPermissionError()
	}
	return claims.UsuarioID, nil
}

type tokenPushRequest struct {
	Token         string `json:"token"`
	Plataforma    string `json:"plataforma"`
	DispositivoID string `json:"dispositivoId"`
}

// RegistrarToken maneja POST /me/notificaciones/tokens (US-NOT-01 AC-01).
func (h *NotificacionesHandler) RegistrarToken(c echo.Context) error {
	usuario, err := usuarioActual(c)
	if err != nil {
		return err
	}
	var req tokenPushRequest
	if err := c.Bind(&req); err != nil {
		return shared.NewValidationError("Cuerpo inválido")
	}
	if err := h.svc.RegistrarToken(c.Request().Context(), usuario, req.Token, req.Plataforma, req.DispositivoID); err != nil {
		return err
	}
	return c.NoContent(http.StatusNoContent)
}

// EliminarToken maneja DELETE /me/notificaciones/tokens {token} al cerrar sesión.
func (h *NotificacionesHandler) EliminarToken(c echo.Context) error {
	usuario, err := usuarioActual(c)
	if err != nil {
		return err
	}
	var req tokenPushRequest
	if err := c.Bind(&req); err != nil || req.Token == "" {
		return shared.NewValidationError("Indique el token a eliminar")
	}
	if err := h.svc.EliminarToken(c.Request().Context(), usuario, req.Token); err != nil {
		return err
	}
	return c.NoContent(http.StatusNoContent)
}

// Preferencias maneja GET /me/notificaciones/preferencias.
func (h *NotificacionesHandler) Preferencias(c echo.Context) error {
	usuario, err := usuarioActual(c)
	if err != nil {
		return err
	}
	p, err := h.svc.Preferencias(c.Request().Context(), usuario)
	if err != nil {
		return err
	}
	return c.JSON(http.StatusOK, p)
}

// GuardarPreferencias maneja PUT /me/notificaciones/preferencias (RF-NOT-003).
func (h *NotificacionesHandler) GuardarPreferencias(c echo.Context) error {
	usuario, err := usuarioActual(c)
	if err != nil {
		return err
	}
	var req notificacion.Preferencias
	if err := c.Bind(&req); err != nil {
		return shared.NewValidationError("Cuerpo inválido")
	}
	p, err := h.svc.GuardarPreferencias(c.Request().Context(), usuario, req)
	if err != nil {
		return err
	}
	return c.JSON(http.StatusOK, p)
}

// Bandeja maneja GET /me/notificaciones?limite=30.
func (h *NotificacionesHandler) Bandeja(c echo.Context) error {
	usuario, err := usuarioActual(c)
	if err != nil {
		return err
	}
	limite, _ := strconv.Atoi(c.QueryParam("limite"))
	items, err := h.svc.Bandeja(c.Request().Context(), usuario, limite)
	if err != nil {
		return err
	}
	return c.JSON(http.StatusOK, items)
}

// MarcarLeida maneja POST /me/notificaciones/:id/leida.
func (h *NotificacionesHandler) MarcarLeida(c echo.Context) error {
	usuario, err := usuarioActual(c)
	if err != nil {
		return err
	}
	if err := h.svc.MarcarLeida(c.Request().Context(), usuario, c.Param("id")); err != nil {
		return err
	}
	return c.NoContent(http.StatusNoContent)
}
