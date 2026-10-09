// Package handler — derechos del titular: copia de datos, rectificación y supresión (US-LEG-02).
package handler

import (
	"encoding/json"
	"net/http"

	"github.com/labstack/echo/v4"

	domain "github.com/siaa/backend/internal/domain/privacidad"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/repository"
	"github.com/siaa/backend/internal/transport/http/middleware"
	"github.com/siaa/backend/internal/usecase/privacidad"
)

// DerechosHandler expone el canal de derechos al titular y la bandeja de atención.
type DerechosHandler struct {
	svc *privacidad.DerechosService
}

// NewDerechosHandler crea el handler de derechos del titular.
func NewDerechosHandler(svc *privacidad.DerechosService) *DerechosHandler {
	return &DerechosHandler{svc: svc}
}

// Canal maneja GET /privacidad/derechos (público): canal y plazos legales (AC-04).
func (h *DerechosHandler) Canal(c echo.Context) error {
	return c.JSON(http.StatusOK, h.svc.Canal())
}

// MisDatos maneja GET /me/datos: copia estructurada de los datos personales (AC-01).
func (h *DerechosHandler) MisDatos(c echo.Context) error {
	claims, ok := middleware.GetClaims(c)
	if !ok {
		return shared.NewPermissionError()
	}
	copia, err := h.svc.ExportarDatos(c.Request().Context(), claims.UsuarioID, c.RealIP())
	if err != nil {
		return err
	}
	cuerpo, err := json.MarshalIndent(copia, "", "  ")
	if err != nil {
		return err
	}
	c.Response().Header().Set(echo.HeaderContentDisposition, `attachment; filename="mis-datos-siaa.json"`)
	c.Response().Header().Set(echo.HeaderCacheControl, "no-store")
	return c.Blob(http.StatusOK, echo.MIMEApplicationJSONCharsetUTF8, cuerpo)
}

// MisSolicitudes maneja GET /me/derechos/solicitudes.
func (h *DerechosHandler) MisSolicitudes(c echo.Context) error {
	claims, ok := middleware.GetClaims(c)
	if !ok {
		return shared.NewPermissionError()
	}
	lista, err := h.svc.MisSolicitudes(c.Request().Context(), claims.UsuarioID)
	if err != nil {
		return err
	}
	return c.JSON(http.StatusOK, lista)
}

type radicarDerechoRequest struct {
	Tipo        string            `json:"tipo"`
	Descripcion string            `json:"descripcion"`
	Cambios     map[string]string `json:"cambios"`
}

// Radicar maneja POST /me/derechos/solicitudes {tipo, descripcion, cambios} (AC-02, AC-03).
func (h *DerechosHandler) Radicar(c echo.Context) error {
	claims, ok := middleware.GetClaims(c)
	if !ok {
		return shared.NewPermissionError()
	}
	var req radicarDerechoRequest
	if err := c.Bind(&req); err != nil {
		return shared.NewValidationError("Cuerpo de la solicitud inválido")
	}
	sol, err := h.svc.Radicar(c.Request().Context(), privacidad.SolicitudRadicacion{
		TitularID: claims.UsuarioID, Tipo: domain.TipoSolicitud(req.Tipo), Descripcion: req.Descripcion,
		Cambios: req.Cambios, IPOrigen: c.RealIP(),
	})
	if err != nil {
		return err
	}
	return c.JSON(http.StatusCreated, sol)
}

// EvaluarSupresion maneja GET /me/derechos/supresion: qué se elimina y qué se conserva (AC-03).
func (h *DerechosHandler) EvaluarSupresion(c echo.Context) error {
	claims, ok := middleware.GetClaims(c)
	if !ok {
		return shared.NewPermissionError()
	}
	return c.JSON(http.StatusOK, map[string]interface{}{
		"elementos": h.svc.EvaluarSupresion(c.Request().Context(), claims.UsuarioID),
	})
}

// Bandeja maneja GET /privacidad/solicitudes?estado=&tipo=&abiertas=true.
func (h *DerechosHandler) Bandeja(c echo.Context) error {
	lista, err := h.svc.Listar(c.Request().Context(), repository.FiltroSolicitudesDerechos{
		Estado:       domain.EstadoSolicitud(c.QueryParam("estado")),
		Tipo:         domain.TipoSolicitud(c.QueryParam("tipo")),
		SoloAbiertas: c.QueryParam("abiertas") == "true",
	})
	if err != nil {
		return err
	}
	return c.JSON(http.StatusOK, lista)
}

// Asumir maneja POST /privacidad/solicitudes/:id/asumir.
func (h *DerechosHandler) Asumir(c echo.Context) error {
	sol, err := h.svc.Asumir(c.Request().Context(), actorDerechos(c), c.Param("id"))
	if err != nil {
		return err
	}
	return c.JSON(http.StatusOK, sol)
}

type resolverDerechoRequest struct {
	Atendida  *bool  `json:"atendida"`
	Respuesta string `json:"respuesta"`
}

// Resolver maneja POST /privacidad/solicitudes/:id/resolver {atendida, respuesta}.
func (h *DerechosHandler) Resolver(c echo.Context) error {
	var req resolverDerechoRequest
	if err := c.Bind(&req); err != nil || req.Atendida == nil {
		return shared.NewValidationError("Indique si la solicitud se atiende y la respuesta al titular",
			shared.FieldError{Campo: "atendida", Error: "REQUERIDO"})
	}
	sol, err := h.svc.Resolver(c.Request().Context(), actorDerechos(c), c.Param("id"), *req.Atendida, req.Respuesta)
	if err != nil {
		return err
	}
	return c.JSON(http.StatusOK, sol)
}

func actorDerechos(c echo.Context) privacidad.ActorDerechos {
	a := privacidad.ActorDerechos{IPOrigen: c.RealIP()}
	if claims, ok := middleware.GetClaims(c); ok {
		a.UsuarioID, a.RolActivo = claims.UsuarioID, claims.RolActivo
	}
	return a
}
