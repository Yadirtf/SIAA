// Package handler — manejador HTTP para administración, ajustes, ventana estudiantil y lista manual.
// Satisface US-MAR-09, US-MAR-13, US-MAR-14 y contratos de la API.
package handler

import (
	"errors"
	"net/http"
	"strconv"
	"time"

	"github.com/labstack/echo/v4"

	domainMarcaje "github.com/siaa/backend/internal/domain/marcaje"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/repository"
	"github.com/siaa/backend/internal/transport/http/dto"
	"github.com/siaa/backend/internal/transport/http/middleware"
	usecaseMarcaje "github.com/siaa/backend/internal/usecase/marcaje"
)

// MarcajeAdminHandler gestiona operaciones administrativas, correcciones y contingencias.
type MarcajeAdminHandler struct {
	ajustarUC     *usecaseMarcaje.AjustarMarcajeUseCase
	estudianteUC  *usecaseMarcaje.VentanaEstudiantilUseCase
	listaManualUC *usecaseMarcaje.ListaManualUseCase
}

func NewMarcajeAdminHandler(
	ajustarUC *usecaseMarcaje.AjustarMarcajeUseCase,
	estudianteUC *usecaseMarcaje.VentanaEstudiantilUseCase,
	listaManualUC *usecaseMarcaje.ListaManualUseCase,
) *MarcajeAdminHandler {
	return &MarcajeAdminHandler{
		ajustarUC:     ajustarUC,
		estudianteUC:  estudianteUC,
		listaManualUC: listaManualUC,
	}
}

// ListarMarcajes consulta marcajes con filtros administrativos avanzados.
// GET /api/v1/marcajes
func (h *MarcajeAdminHandler) ListarMarcajes(c echo.Context) error {
	pagina, _ := strconv.ParseInt(c.QueryParam("pagina"), 10, 64)
	limite, _ := strconv.ParseInt(c.QueryParam("limite"), 10, 64)

	filtros := repository.FiltrosMarcaje{
		SesionID:  c.QueryParam("sesionId"),
		UsuarioID: c.QueryParam("usuarioId"),
		EspacioID: c.QueryParam("espacioId"),
		Resultado: domainMarcaje.ResultadoMarcaje(c.QueryParam("resultado")),
		Tipo:      domainMarcaje.TipoMarcaje(c.QueryParam("tipo")),
		Origen:    domainMarcaje.OrigenMarcaje(c.QueryParam("origen")),
	}

	if desdeStr := c.QueryParam("desde"); desdeStr != "" {
		if t, err := time.Parse(time.RFC3339, desdeStr); err == nil {
			filtros.Desde = &t
		}
	}
	if hastaStr := c.QueryParam("hasta"); hastaStr != "" {
		if t, err := time.Parse(time.RFC3339, hastaStr); err == nil {
			filtros.Hasta = &t
		}
	}

	resp, err := h.ajustarUC.ListarAdministrativo(c.Request().Context(), filtros, pagina, limite)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}

	return c.JSON(http.StatusOK, resp)
}

// AjustarMarcaje aplica anulación o corrección técnica con motivo obligatorio (US-MAR-09).
// PATCH /api/v1/marcajes/:id
func (h *MarcajeAdminHandler) AjustarMarcaje(c echo.Context) error {
	claims, ok := middleware.GetClaims(c)
	if !ok {
		return shared.NewAuthError(shared.ErrTokenExpirado, "Autenticación requerida")
	}

	id := c.Param("id")
	if id == "" {
		return echo.NewHTTPError(http.StatusBadRequest, "ID de marcaje requerido")
	}

	var req dto.AjusteMarcajeRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Cuerpo inválido")
	}

	sol := usecaseMarcaje.SolicitudAjuste{
		MarcajeID:      id,
		NuevoResultado: domainMarcaje.ResultadoMarcaje(req.NuevoResultado),
		Anulado:        req.Anulado,
		Motivo:         req.Motivo,
	}

	m, err := h.ajustarUC.Ajustar(c.Request().Context(), sol, claims.UsuarioID)
	if err != nil {
		if errors.Is(err, domainMarcaje.ErrMotivoInsuficiente) {
			return echo.NewHTTPError(http.StatusBadRequest, err.Error())
		}
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}

	return c.JSON(http.StatusOK, m)
}

// CrearManual registra un marcaje manual de contingencia (US-MAR-09 AC-04).
// POST /api/v1/marcajes/manual
func (h *MarcajeAdminHandler) CrearManual(c echo.Context) error {
	claims, ok := middleware.GetClaims(c)
	if !ok {
		return shared.NewAuthError(shared.ErrTokenExpirado, "Autenticación requerida")
	}

	var req dto.MarcajeManualRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Cuerpo inválido")
	}

	sol := usecaseMarcaje.SolicitudMarcajeManual{
		SesionID:  req.SesionID,
		UsuarioID: req.UsuarioID,
		Tipo:      domainMarcaje.TipoMarcaje(req.Tipo),
		Resultado: domainMarcaje.ResultadoMarcaje(req.Resultado),
		Motivo:    req.Motivo,
	}

	m, err := h.ajustarUC.CrearManual(c.Request().Context(), sol, claims.UsuarioID)
	if err != nil {
		if errors.Is(err, domainMarcaje.ErrMotivoInsuficiente) {
			return echo.NewHTTPError(http.StatusBadRequest, err.Error())
		}
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}

	return c.JSON(http.StatusCreated, m)
}

// VentanaEstudiantil abre la ventana de marcaje para los estudiantes del grupo (US-MAR-13).
// POST /api/v1/sesiones/:id/ventana-estudiantil
func (h *MarcajeAdminHandler) VentanaEstudiantil(c echo.Context) error {
	claims, ok := middleware.GetClaims(c)
	if !ok {
		return shared.NewAuthError(shared.ErrTokenExpirado, "Autenticación requerida")
	}

	sesionID := c.Param("id")
	var req dto.VentanaEstudiantilRequest
	_ = c.Bind(&req)

	cierraEn, err := h.estudianteUC.AbrirVentana(c.Request().Context(), sesionID, claims.UsuarioID, req.DuracionMinutos)
	if err != nil {
		if errors.Is(err, usecaseMarcaje.ErrDocenteNoAutorizado) {
			return echo.NewHTTPError(http.StatusForbidden, err.Error())
		}
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}

	return c.JSON(http.StatusOK, map[string]interface{}{
		"abierta":  true,
		"cierraEn": cierraEn.Format(time.RFC3339),
	})
}

// ListaManual procesa el pase de lista de contingencia por el docente (US-MAR-14).
// POST /api/v1/sesiones/:id/lista-manual
func (h *MarcajeAdminHandler) ListaManual(c echo.Context) error {
	claims, ok := middleware.GetClaims(c)
	if !ok {
		return shared.NewAuthError(shared.ErrTokenExpirado, "Autenticación requerida")
	}

	sesionID := c.Param("id")
	var req dto.ListaManualRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Cuerpo inválido")
	}

	items := make([]usecaseMarcaje.ItemListaEstudiante, len(req.Estudiantes))
	for i, est := range req.Estudiantes {
		items[i] = usecaseMarcaje.ItemListaEstudiante{
			EstudianteID: est.EstudianteID,
			Presente:     est.Presente,
		}
	}

	err := h.listaManualUC.Registrar(c.Request().Context(), sesionID, claims.UsuarioID, req.Motivo, items)
	if err != nil {
		if errors.Is(err, usecaseMarcaje.ErrDocenteNoAutorizado) {
			return echo.NewHTTPError(http.StatusForbidden, err.Error())
		}
		if errors.Is(err, usecaseMarcaje.ErrMotivoListaRequerido) {
			return echo.NewHTTPError(http.StatusBadRequest, err.Error())
		}
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}

	return c.JSON(http.StatusOK, map[string]interface{}{
		"mensaje":     "Lista manual registrada y auditada exitosamente",
		"estudiantes": len(items),
	})
}
