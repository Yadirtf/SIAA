package handler

import (
	"net/http"

	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/usecase/usuarios"
)

// PerfilHandler expone GET /me/perfil.
type PerfilHandler struct {
	svc *usuarios.ServicioPerfil
}

// NewPerfilHandler crea el handler del perfil propio.
func NewPerfilHandler(svc *usuarios.ServicioPerfil) *PerfilHandler {
	return &PerfilHandler{svc: svc}
}

// Obtener maneja GET /me/perfil: datos de la cuenta y dispositivos vinculados.
func (h *PerfilHandler) Obtener(c echo.Context) error {
	usuario, err := usuarioActual(c)
	if err != nil {
		return err
	}
	p, err := h.svc.Obtener(c.Request().Context(), usuario)
	if err != nil {
		return err
	}
	return c.JSON(http.StatusOK, p)
}
