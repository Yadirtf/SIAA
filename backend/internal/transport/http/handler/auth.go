// Package handler contiene los handlers HTTP de autenticación.
// US-AUT-01, US-AUT-04
package handler

import (
	"net/http"
	"time"

	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/transport/http/dto"
	"github.com/siaa/backend/internal/transport/http/middleware"
	"github.com/siaa/backend/internal/usecase/auth"
)

// AuthHandler maneja las peticiones HTTP de autenticación.
type AuthHandler struct {
	svc *auth.Service
}

// NewAuthHandler crea un nuevo handler de autenticación.
func NewAuthHandler(svc *auth.Service) *AuthHandler {
	return &AuthHandler{svc: svc}
}

// Login godoc
// @Summary     Iniciar sesión
// @Description Autentica con correo y contraseña institucional
// @Tags        auth
// @Accept      json
// @Produce     json
// @Param       body body dto.LoginRequest true "Credenciales"
// @Success     200 {object} dto.TokenPairResponse
// @Failure     401 {object} middleware.errorResponse
// @Failure     423 {object} middleware.errorResponse
// @Router      /auth/login [post]
func (h *AuthHandler) Login(c echo.Context) error {
	var req dto.LoginRequest
	if err := c.Bind(&req); err != nil {
		return echo.ErrBadRequest
	}
	if err := c.Validate(&req); err != nil {
		return err
	}

	pair, err := h.svc.Login(c.Request().Context(), auth.LoginInput{
		Correo:       req.Correo,
		Password:     req.Password,
		DispositivoID: req.DispositivoID,
	})
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

// Refresh godoc
// @Summary     Renovar tokens
// @Description Rota el refresh token y emite un nuevo par
// @Tags        auth
// @Accept      json
// @Produce     json
// @Param       body body dto.RefreshRequest true "Refresh token"
// @Success     200 {object} dto.TokenPairResponse
// @Failure     401 {object} middleware.errorResponse
// @Router      /auth/refresh [post]
func (h *AuthHandler) Refresh(c echo.Context) error {
	var req dto.RefreshRequest
	if err := c.Bind(&req); err != nil {
		return echo.ErrBadRequest
	}
	if req.RefreshToken == "" {
		return echo.ErrBadRequest
	}

	pair, err := h.svc.Refresh(c.Request().Context(), req.RefreshToken, req.DispositivoID)
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

// Logout godoc
// @Summary     Cerrar sesión
// @Description Revoca el refresh token actual
// @Tags        auth
// @Accept      json
// @Produce     json
// @Security    BearerAuth
// @Param       body body dto.LogoutRequest true "Refresh token a revocar"
// @Success     200 {object} dto.MensajeResponse
// @Router      /auth/logout [post]
func (h *AuthHandler) Logout(c echo.Context) error {
	var req dto.LogoutRequest
	if err := c.Bind(&req); err != nil {
		return echo.ErrBadRequest
	}

	claims, _ := middleware.GetClaims(c)
	usuarioID := ""
	if claims != nil {
		usuarioID = claims.UsuarioID
	}

	if err := h.svc.Logout(c.Request().Context(), req.RefreshToken, usuarioID); err != nil {
		return err
	}

	return c.JSON(http.StatusOK, dto.MensajeResponse{Mensaje: "Sesión cerrada correctamente"})
}

// SolicitarRecuperacion godoc
// @Summary     Solicitar recuperación de contraseña
// @Description Envía enlace de recuperación de un solo uso (respuesta idéntica si el correo no existe)
// @Tags        auth
// @Accept      json
// @Produce     json
// @Param       body body dto.RecuperarRequest true "Correo electrónico"
// @Success     200 {object} dto.MensajeResponse
// @Router      /auth/recuperar [post]
func (h *AuthHandler) SolicitarRecuperacion(c echo.Context) error {
	var req dto.RecuperarRequest
	if err := c.Bind(&req); err != nil {
		return echo.ErrBadRequest
	}

	// Respuesta siempre igual independiente del resultado (AC-02 US-AUT-04)
	_ = h.svc.SolicitarRecuperacion(c.Request().Context(), req.Correo)

	return c.JSON(http.StatusOK, dto.MensajeResponse{
		Mensaje: "Si el correo está registrado, recibirás un enlace de recuperación en los próximos minutos",
	})
}

// ConfirmarRecuperacion godoc
// @Summary     Confirmar nueva contraseña
// @Description Establece la nueva contraseña usando el token de recuperación
// @Tags        auth
// @Accept      json
// @Produce     json
// @Param       body body dto.ConfirmarRecuperarRequest true "Token y nueva contraseña"
// @Success     200 {object} dto.MensajeResponse
// @Failure     401 {object} middleware.errorResponse
// @Failure     422 {object} middleware.errorResponse
// @Router      /auth/recuperar/confirmar [post]
func (h *AuthHandler) ConfirmarRecuperacion(c echo.Context) error {
	var req dto.ConfirmarRecuperarRequest
	if err := c.Bind(&req); err != nil {
		return echo.ErrBadRequest
	}
	if req.Token == "" || req.Password == "" {
		return echo.ErrBadRequest
	}

	if err := h.svc.ConfirmarRecuperacion(c.Request().Context(), req.Token, req.Password); err != nil {
		return err
	}

	return c.JSON(http.StatusOK, dto.MensajeResponse{
		Mensaje: "Contraseña actualizada correctamente. Todas tus sesiones han sido cerradas.",
	})
}
