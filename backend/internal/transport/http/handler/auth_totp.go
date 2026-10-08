// Package handler — Handlers HTTP para enrolamiento y verificación TOTP (2FA).
// Satisface US-AUT-05, AC-01..AC-05 y RF-AUT-003.
package handler

import (
	"net/http"
	"time"

	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/transport/http/dto"
	"github.com/siaa/backend/internal/transport/http/middleware"
	"github.com/siaa/backend/internal/usecase/auth"
)

// SetupTOTP procesa POST /auth/totp/setup.
// Genera clave secreta base32 y 8 códigos de respaldo para el usuario autenticado.
func (h *AuthHandler) SetupTOTP(c echo.Context) error {
	usuarioID := c.Get(middleware.CtxUsuarioID).(string)

	result, err := h.svc.SetupTOTP(c.Request().Context(), usuarioID)
	if err != nil {
		return err
	}

	return c.JSON(http.StatusOK, result)
}

// ActivarTOTP procesa POST /auth/totp/activar.
// Valida el código inicial de 6 dígitos para activar formalmente el segundo factor.
func (h *AuthHandler) ActivarTOTP(c echo.Context) error {
	usuarioID := c.Get(middleware.CtxUsuarioID).(string)

	var req dto.ActivarTOTPRequest
	if err := c.Bind(&req); err != nil {
		return echo.ErrBadRequest
	}
	if err := c.Validate(&req); err != nil {
		return err
	}

	if err := h.svc.ActivarTOTP(c.Request().Context(), usuarioID, req.Codigo); err != nil {
		return err
	}

	return c.JSON(http.StatusOK, dto.MensajeResponse{
		Mensaje: "Autenticación de dos factores activada exitosamente",
	})
}

// VerificarTOTP procesa POST /auth/totp/verificar.
// Valida el código del desafío emitido por /auth/login antes de entregar tokens definitivos.
func (h *AuthHandler) VerificarTOTP(c echo.Context) error {
	var req dto.VerificarTOTPRequest
	if err := c.Bind(&req); err != nil {
		return echo.ErrBadRequest
	}
	if err := c.Validate(&req); err != nil {
		return err
	}

	pair, err := h.svc.VerificarTOTP(c.Request().Context(), req.DesafioToken, req.Codigo, req.DispositivoID)
	if err != nil {
		return err
	}
	return c.JSON(http.StatusOK, tokenPairResponse(pair))
}

// EnrolarTOTP procesa POST /auth/totp/enrolar: configuración obligatoria del segundo
// factor para un rol administrativo que aún no lo tiene (AC-01, AC-03).
func (h *AuthHandler) EnrolarTOTP(c echo.Context) error {
	var req dto.EnrolarTOTPRequest
	if err := c.Bind(&req); err != nil {
		return echo.ErrBadRequest
	}
	if err := c.Validate(&req); err != nil {
		return err
	}
	result, err := h.svc.EnrolarTOTP(c.Request().Context(), req.DesafioToken)
	if err != nil {
		return err
	}
	return c.JSON(http.StatusOK, result)
}

// ConfirmarEnrolamientoTOTP procesa POST /auth/totp/enrolar/confirmar: activa el segundo
// factor con el primer código y completa el inicio de sesión.
func (h *AuthHandler) ConfirmarEnrolamientoTOTP(c echo.Context) error {
	var req dto.VerificarTOTPRequest
	if err := c.Bind(&req); err != nil {
		return echo.ErrBadRequest
	}
	if err := c.Validate(&req); err != nil {
		return err
	}
	pair, err := h.svc.ConfirmarEnrolamientoTOTP(c.Request().Context(), req.DesafioToken, req.Codigo, req.DispositivoID)
	if err != nil {
		return err
	}
	return c.JSON(http.StatusOK, tokenPairResponse(pair))
}

func tokenPairResponse(pair *auth.TokenPair) dto.TokenPairResponse {
	return dto.TokenPairResponse{
		AccessToken:  pair.AccessToken,
		RefreshToken: pair.RefreshToken,
		ExpiraEn:     pair.ExpiraEn.UTC().Format(time.RFC3339),
		TipoToken:    "Bearer",
		Usuario:      pair.Usuario,
	}
}

func desafioResponse(d *auth.DesafioTOTP) dto.DesafioTOTPResponse {
	return dto.DesafioTOTPResponse{
		RequiereTOTP:           d.Proposito == auth.DesafioVerificar,
		RequiereConfigurarTOTP: d.Proposito == auth.DesafioConfigurar,
		Proposito:              d.Proposito,
		DesafioToken:           d.Token,
		ExpiraEn:               d.ExpiraEn.UTC().Format(time.RFC3339),
	}
}
