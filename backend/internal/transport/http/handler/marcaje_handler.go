// Package handler — manejador HTTP para endpoints de marcaje y consultas del docente.
// Satisface US-MAR-01, US-MAR-03..US-MAR-06, US-MAR-08 y contratos §9.4, §9.5.
package handler

import (
	"errors"
	"net/http"
	"strconv"
	"time"

	"github.com/labstack/echo/v4"

	domainMarcaje "github.com/siaa/backend/internal/domain/marcaje"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/transport/http/dto"
	"github.com/siaa/backend/internal/transport/http/middleware"
	usecaseMarcaje "github.com/siaa/backend/internal/usecase/marcaje"
)

// MarcajeHandler expone los endpoints de marcaje para la aplicación móvil y web.
type MarcajeHandler struct {
	crearUC     *usecaseMarcaje.CrearMarcajeUseCase
	activaUC    *usecaseMarcaje.SesionActivaUseCase
	historialUC *usecaseMarcaje.HistorialUseCase
}

func NewMarcajeHandler(
	crearUC *usecaseMarcaje.CrearMarcajeUseCase,
	activaUC *usecaseMarcaje.SesionActivaUseCase,
	historialUC *usecaseMarcaje.HistorialUseCase,
) *MarcajeHandler {
	return &MarcajeHandler{
		crearUC:     crearUC,
		activaUC:    activaUC,
		historialUC: historialUC,
	}
}

// Crear procesa un intento de marcaje con evaluación pura en servidor (§9.4).
// POST /api/v1/marcajes
func (h *MarcajeHandler) Crear(c echo.Context) error {
	claims, ok := middleware.GetClaims(c)
	if !ok {
		return shared.NewAuthError(shared.ErrTokenExpirado, "Autenticación requerida")
	}

	var req dto.CrearMarcajeRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Cuerpo de solicitud inválido")
	}

	// Soporte de cabecera Idempotency-Key
	if req.IdempotencyKey == "" {
		req.IdempotencyKey = c.Request().Header.Get("Idempotency-Key")
	}

	solicitud := req.ToDomain(claims.UsuarioID)
	ahoraServidor := time.Now().UTC()

	evalRes, m, err := h.crearUC.Ejecutar(c.Request().Context(), solicitud, ahoraServidor)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}

	// Caso de reintento permitido sin persistir: HTTP 200 (§9.4)
	if evalRes.Resultado == domainMarcaje.ResultadoPrecisionInsuficiente {
		precRec := evalRes.PrecisionRecibida
		precReq := evalRes.PrecisionRequerida
		return c.JSON(http.StatusOK, dto.MarcajeResponse{
			Resultado:          string(evalRes.Resultado),
			Mensaje:            evalRes.Mensaje,
			PrecisionRecibida:  &precRec,
			PrecisionRequerida: &precReq,
			PermiteReintento:   true,
			PuedeJustificar:    false,
		})
	}

	// Marcaje evaluado y persistido (aceptado o rechazado): HTTP 201 (§9.4)
	marcajeID := ""
	if m != nil {
		marcajeID = m.ID
	}

	var distPtr *float64
	if evalRes.DistanciaMetros > 0 {
		d := evalRes.DistanciaMetros
		distPtr = &d
	}

	return c.JSON(http.StatusCreated, dto.MarcajeResponse{
		MarcajeID:             marcajeID,
		Resultado:             string(evalRes.Resultado),
		MotivoRechazo:         string(evalRes.MotivoRechazo),
		Mensaje:               evalRes.Mensaje,
		DistanciaMetros:       distPtr,
		MinutosRespectoInicio: evalRes.MinutosRespectoInicio,
		TimestampServidor:     ahoraServidor.Format(time.RFC3339),
		PasoFallido:           int(evalRes.PasoFallido),
		PermiteReintento:      evalRes.PermiteReintento,
		PuedeJustificar:       evalRes.PuedeJustificar,
	})
}

// SesionActiva devuelve la sesión marcable en la ventana actual con parámetros y geometría (§9.5).
// GET /api/v1/me/sesiones/activa
func (h *MarcajeHandler) SesionActiva(c echo.Context) error {
	claims, ok := middleware.GetClaims(c)
	if !ok {
		return shared.NewAuthError(shared.ErrTokenExpirado, "Autenticación requerida")
	}

	ahora := time.Now().UTC()
	detalle, err := h.activaUC.ObtenerSesionActiva(c.Request().Context(), claims.UsuarioID, ahora)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}

	return c.JSON(http.StatusOK, detalle)
}

// SesionesHoy lista todas las sesiones programadas para el docente en el día en curso (T-MAR-01.2).
// GET /api/v1/me/sesiones/hoy
func (h *MarcajeHandler) SesionesHoy(c echo.Context) error {
	claims, ok := middleware.GetClaims(c)
	if !ok {
		return shared.NewAuthError(shared.ErrTokenExpirado, "Autenticación requerida")
	}

	ahora := time.Now().UTC()
	sesiones, err := h.activaUC.ListarSesionesHoy(c.Request().Context(), claims.UsuarioID, ahora)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}

	return c.JSON(http.StatusOK, map[string]interface{}{
		"sesiones": sesiones,
		"total":    len(sesiones),
	})
}

// Historial retorna la cronología propia de marcajes paginada con filtro mensual (US-MAR-08).
// GET /api/v1/me/historial
func (h *MarcajeHandler) Historial(c echo.Context) error {
	claims, ok := middleware.GetClaims(c)
	if !ok {
		return shared.NewAuthError(shared.ErrTokenExpirado, "Autenticación requerida")
	}

	mes := c.QueryParam("mes")
	pagina, _ := strconv.ParseInt(c.QueryParam("pagina"), 10, 64)
	limite, _ := strconv.ParseInt(c.QueryParam("limite"), 10, 64)

	resp, err := h.historialUC.ConsultarHistorialPropio(c.Request().Context(), claims.UsuarioID, claims.UsuarioID, mes, pagina, limite)
	if err != nil {
		if errors.Is(err, usecaseMarcaje.ErrAccesoHistorialAjeno) {
			return echo.NewHTTPError(http.StatusForbidden, err.Error())
		}
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}

	return c.JSON(http.StatusOK, resp)
}
