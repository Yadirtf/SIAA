// Package handler — Handlers para alternancia de rol y revocación remota de sesiones.
// Satisface US-ROL-04 (cambio de contexto) y US-AUT-07 (revocación remota).
package handler

import (
	"net/http"
	"time"

	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/transport/http/dto"
	"github.com/siaa/backend/internal/transport/http/middleware"
)

// CambiarContexto procesa POST /auth/contexto.
// Emite un nuevo par de tokens con el rol solicitado si el usuario lo posee y está vigente.
func (h *AuthHandler) CambiarContexto(c echo.Context) error {
	usuarioID := c.Get(middleware.CtxUsuarioID).(string)

	var req dto.CambiarContextoRequest
	if err := c.Bind(&req); err != nil {
		return echo.ErrBadRequest
	}
	if err := c.Validate(&req); err != nil {
		return err
	}

	pair, err := h.svc.CambiarContextoRol(c.Request().Context(), usuarioID, req.Rol)
	if err != nil {
		return err
	}

	return c.JSON(http.StatusOK, dto.TokenPairResponse{
		AccessToken:  pair.AccessToken,
		RefreshToken: pair.RefreshToken,
		ExpiraEn:     pair.ExpiraEn.UTC().Format(time.RFC3339),
		TipoToken:    "Bearer",
		Usuario:      pair.Usuario,
	})
}

// RevocarSesiones procesa POST /usuarios/:id/revocar-sesiones.
// Invalida inmediatamente todos los refresh tokens y registra el usuario en el gestor de revocación en memoria.
func (h *AuthHandler) RevocarSesiones(c echo.Context) error {
	actorID := c.Get(middleware.CtxUsuarioID).(string)
	targetID := c.Param("id")

	var req dto.RevocarSesionesRequest
	if err := c.Bind(&req); err != nil {
		return echo.ErrBadRequest
	}
	if err := c.Validate(&req); err != nil {
		return err
	}

	if err := h.svc.RevocarSesionesUsuario(c.Request().Context(), actorID, targetID, req.Motivo); err != nil {
		return err
	}

	return c.JSON(http.StatusOK, dto.MensajeResponse{
		Mensaje: "Sesiones revocadas exitosamente",
	})
}
