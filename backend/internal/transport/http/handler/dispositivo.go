// Package handler — endpoints para vinculación y administración de dispositivos confiables (US-AUT-03).
package handler

import (
	"net/http"

	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/transport/http/dto"
	"github.com/siaa/backend/internal/transport/http/middleware"
	usecaseAuth "github.com/siaa/backend/internal/usecase/auth"
)

// RegistrarDispositivo vincula un dispositivo o solicita cambio (AC-01, AC-03).
// POST /api/v1/auth/devices
func (h *AuthHandler) RegistrarDispositivo(c echo.Context) error {
	claims, ok := middleware.GetClaims(c)
	if !ok {
		return shared.NewAuthError(shared.ErrTokenExpirado, "Autenticación requerida")
	}

	var req dto.RegistrarDispositivoRequest
	if err := c.Bind(&req); err != nil {
		return echo.ErrBadRequest
	}
	if err := c.Validate(&req); err != nil {
		return err
	}

	input := usecaseAuth.RegistrarDispositivoInput{
		UsuarioID:     claims.UsuarioID,
		InstalacionID: req.InstalacionID,
		Modelo:        req.Modelo,
		SO:            req.SO,
		VersionApp:    req.VersionApp,
	}

	disp, err := h.svc.RegistrarDispositivo(c.Request().Context(), input)
	if err != nil {
		return err
	}

	return c.JSON(http.StatusCreated, dto.DispositivoToResponse(disp))
}

// ListarDispositivosUsuario devuelve los dispositivos vinculados al usuario indicado (AC-06).
// GET /api/v1/usuarios/:id/dispositivos
func (h *AuthHandler) ListarDispositivosUsuario(c echo.Context) error {
	usuarioID := c.Param("id")
	if usuarioID == "" {
		return shared.NewValidationError("El ID del usuario es obligatorio")
	}

	lista, err := h.svc.ListarDispositivosUsuario(c.Request().Context(), usuarioID)
	if err != nil {
		return err
	}

	resp := make([]dto.DispositivoResponse, len(lista))
	for i, d := range lista {
		resp[i] = dto.DispositivoToResponse(d)
	}

	return c.JSON(http.StatusOK, resp)
}

// AprobarDispositivo autoriza un dispositivo en estado pendiente (AC-03).
// POST /api/v1/dispositivos/:id/aprobar
func (h *AuthHandler) AprobarDispositivo(c echo.Context) error {
	claims, ok := middleware.GetClaims(c)
	if !ok {
		return shared.NewAuthError(shared.ErrTokenExpirado, "Autenticación requerida")
	}

	dispositivoID := c.Param("id")
	if dispositivoID == "" {
		return shared.NewValidationError("El ID del dispositivo es obligatorio")
	}

	if err := h.svc.AprobarDispositivo(c.Request().Context(), claims.UsuarioID, dispositivoID); err != nil {
		return err
	}

	return c.JSON(http.StatusOK, dto.MensajeResponse{
		Mensaje: "Dispositivo aprobado como confiable correctamente.",
	})
}

// RevocarDispositivo revoca un dispositivo confiable (AC-06).
// POST /api/v1/dispositivos/:id/revocar
func (h *AuthHandler) RevocarDispositivo(c echo.Context) error {
	claims, ok := middleware.GetClaims(c)
	if !ok {
		return shared.NewAuthError(shared.ErrTokenExpirado, "Autenticación requerida")
	}

	dispositivoID := c.Param("id")
	if dispositivoID == "" {
		return shared.NewValidationError("El ID del dispositivo es obligatorio")
	}

	if err := h.svc.RevocarDispositivo(c.Request().Context(), claims.UsuarioID, dispositivoID); err != nil {
		return err
	}

	return c.JSON(http.StatusOK, dto.MensajeResponse{
		Mensaje: "Dispositivo revocado correctamente.",
	})
}
