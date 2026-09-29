// Package handler — radicación y revisión de justificaciones (EP-07, RF-JUS-001..005).
package handler

import (
	"fmt"
	"io"
	"net/http"
	"strconv"

	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/domain/justificacion"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/transport/http/middleware"
	"github.com/siaa/backend/internal/usecase/justificaciones"
)

// JustificacionesHandler expone la radicación con soportes y la bandeja de revisión.
type JustificacionesHandler struct {
	svc *justificaciones.Service
}

// NewJustificacionesHandler crea el handler de justificaciones.
func NewJustificacionesHandler(svc *justificaciones.Service) *JustificacionesHandler {
	return &JustificacionesHandler{svc: svc}
}

func actorJustificaciones(c echo.Context) justificaciones.Actor {
	a := justificaciones.Actor{Alcance: middleware.AlcanceDe(c)}
	if claims, ok := middleware.GetClaims(c); ok {
		a.UsuarioID, a.RolActivo = claims.UsuarioID, claims.RolActivo
	}
	return a
}

// Radicar maneja POST /justificaciones (multipart: sesionId, tipo, descripcion, soportes).
func (h *JustificacionesHandler) Radicar(c echo.Context) error {
	form, err := c.MultipartForm()
	if err != nil {
		return shared.NewValidationError("Envíe el formulario como multipart/form-data con al menos un soporte")
	}
	req := justificaciones.SolicitudRadicar{
		SesionID:    c.FormValue("sesionId"),
		Tipo:        justificacion.Tipo(c.FormValue("tipo")),
		Descripcion: c.FormValue("descripcion"),
	}
	for _, fh := range form.File["soportes"] {
		if fh.Size > justificaciones.MaxBytesSoporte {
			return shared.NewValidationError(fmt.Sprintf("el soporte %q supera 10 MB", fh.Filename))
		}
		f, err := fh.Open()
		if err != nil {
			return shared.NewValidationError("No se pudo leer el soporte")
		}
		contenido, err := io.ReadAll(io.LimitReader(f, justificaciones.MaxBytesSoporte+1))
		_ = f.Close()
		if err != nil {
			return shared.NewValidationError("No se pudo leer el soporte")
		}
		req.Soportes = append(req.Soportes, justificaciones.Archivo{Nombre: fh.Filename, Contenido: contenido})
	}
	j, err := h.svc.Radicar(c.Request().Context(), actorJustificaciones(c), req)
	if err != nil {
		return err
	}
	return c.JSON(http.StatusCreated, j)
}

// Listar maneja GET /justificaciones?estado=&tipo=&docenteId=&desde=&hasta=&pagina=&limite=.
// Devuelve la lista y el total en X-Total-Count.
func (h *JustificacionesHandler) Listar(c echo.Context) error {
	f := justificaciones.FiltroListado{
		DocenteID:  c.QueryParam("docenteId"),
		Estado:     justificacion.Estado(c.QueryParam("estado")),
		Tipo:       justificacion.Tipo(c.QueryParam("tipo")),
		FechaDesde: c.QueryParam("desde"),
		FechaHasta: c.QueryParam("hasta"),
	}
	f.Pagina, _ = strconv.ParseInt(c.QueryParam("pagina"), 10, 64)
	f.Limite, _ = strconv.ParseInt(c.QueryParam("limite"), 10, 64)
	lista, total, err := h.svc.Listar(c.Request().Context(), actorJustificaciones(c), f)
	if err != nil {
		return err
	}
	c.Response().Header().Set("X-Total-Count", strconv.FormatInt(total, 10))
	return c.JSON(http.StatusOK, lista)
}

// Obtener maneja GET /justificaciones/:id.
func (h *JustificacionesHandler) Obtener(c echo.Context) error {
	j, err := h.svc.Obtener(c.Request().Context(), actorJustificaciones(c), c.Param("id"))
	if err != nil {
		return err
	}
	return c.JSON(http.StatusOK, j)
}

// DescargarSoporte maneja GET /justificaciones/:id/soportes/:soporteId.
func (h *JustificacionesHandler) DescargarSoporte(c echo.Context) error {
	s, err := h.svc.ObtenerSoporte(c.Request().Context(), actorJustificaciones(c), c.Param("id"), c.Param("soporteId"))
	if err != nil {
		return err
	}
	c.Response().Header().Set("Content-Disposition", fmt.Sprintf("inline; filename=%q", s.Adjunto.Nombre))
	c.Response().Header().Set("X-Content-Type-Options", "nosniff")
	return c.Blob(http.StatusOK, s.Adjunto.Mime, s.Contenido)
}

type revisionRequest struct {
	Estado        string `json:"estado"`
	Observaciones string `json:"observaciones"`
}

// Revisar maneja PATCH /justificaciones/:id con {estado, observaciones} (RF-JUS-002).
func (h *JustificacionesHandler) Revisar(c echo.Context) error {
	var req revisionRequest
	if err := c.Bind(&req); err != nil {
		return shared.NewValidationError("Cuerpo de la solicitud inválido")
	}
	j, err := h.svc.Revisar(c.Request().Context(), actorJustificaciones(c), c.Param("id"), justificacion.Estado(req.Estado), req.Observaciones)
	if err != nil {
		return err
	}
	return c.JSON(http.StatusOK, j)
}
