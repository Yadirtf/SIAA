// Package handler — ParametroHandler: endpoints REST para la parametrización jerárquica.
// US-PAR-01: GET/PUT /parametros
// US-PAR-03: GET /parametros/efectivos
// ADR-02: handler solo traduce HTTP ↔ usecase, sin lógica de negocio.
package handler

import (
	"net/http"
	"time"

	"github.com/labstack/echo/v4"

	dompar "github.com/siaa/backend/internal/domain/parametro"
	"github.com/siaa/backend/internal/transport/http/dto"
	mw "github.com/siaa/backend/internal/transport/http/middleware"
	ucpar "github.com/siaa/backend/internal/usecase/parametro"
)

// ParametroHandler gestiona los endpoints de configuración de parámetros.
type ParametroHandler struct {
	uc *ucpar.UseCase
}

// NewParametroHandler construye el handler con su caso de uso.
func NewParametroHandler(uc *ucpar.UseCase) *ParametroHandler {
	return &ParametroHandler{uc: uc}
}

// GuardarParametro maneja PUT /parametros.
// Inserta o actualiza un parámetro para el ámbito indicado (US-PAR-01 AC-03).
func (h *ParametroHandler) GuardarParametro(c echo.Context) error {
	var req dto.GuardarParametroRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "cuerpo de solicitud inválido")
	}
	if err := c.Validate(&req); err != nil {
		return echo.NewHTTPError(http.StatusUnprocessableEntity, err.Error())
	}

	claims, ok := mw.GetClaims(c)
	autorID := ""
	if ok && claims != nil {
		autorID = claims.UsuarioID
	}

	p := &dompar.Parametro{
		Ambito:   dompar.Ambito(req.Ambito),
		AmbitoID: req.AmbitoID,
		Clave:    dompar.Clave(req.Clave),
		Valor:    req.Valor,
		AutorID:  autorID,
	}
	if req.VigenteDesde != nil {
		p.VigenteDesde = req.VigenteDesde.UTC()
	} else {
		p.VigenteDesde = time.Now().UTC()
	}

	if err := h.uc.GuardarParametro(c.Request().Context(), p); err != nil {
		switch err {
		case dompar.ErrFueraDeRango:
			return echo.NewHTTPError(http.StatusUnprocessableEntity, "valor fuera del rango permitido para este parámetro")
		case dompar.ErrClaveInvalida:
			return echo.NewHTTPError(http.StatusUnprocessableEntity, "clave de parámetro no reconocida")
		default:
			return echo.NewHTTPError(http.StatusInternalServerError, "error al guardar parámetro")
		}
	}

	return c.JSON(http.StatusOK, map[string]string{"mensaje": "parámetro guardado"})
}

// ListarPorAmbito maneja GET /parametros.
// Devuelve los parámetros configurados para el nivel indicado por query params.
func (h *ParametroHandler) ListarPorAmbito(c echo.Context) error {
	ambito := dompar.Ambito(c.QueryParam("ambito"))
	ambitoID := c.QueryParam("ambito_id")

	if ambito == "" {
		ambito = dompar.AmbitoGlobal
	}

	params, err := h.uc.ListarPorAmbito(c.Request().Context(), ambito, ambitoID)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "error al listar parámetros")
	}

	respuestas := make([]dto.ParametroResponse, 0, len(params))
	for _, p := range params {
		respuestas = append(respuestas, dto.ToParametroResponse(p))
	}
	return c.JSON(http.StatusOK, map[string]interface{}{"datos": respuestas})
}

// ObtenerEfectivos maneja GET /parametros/efectivos (US-PAR-03).
// Resuelve la cascada completa y devuelve cada clave con su valor y nivel de origen.
// Query params: sede_id, facultad_id, bloque_id, espacio_id, asignacion_id.
func (h *ParametroHandler) ObtenerEfectivos(c echo.Context) error {
	spec := ucpar.EspecCascada{
		SedeID:       c.QueryParam("sede_id"),
		FacultadID:   c.QueryParam("facultad_id"),
		BloqueID:     c.QueryParam("bloque_id"),
		EspacioID:    c.QueryParam("espacio_id"),
		AsignacionID: c.QueryParam("asignacion_id"),
	}

	snap, err := h.uc.ResolverEfectivos(c.Request().Context(), spec)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "error al resolver parámetros efectivos")
	}

	return c.JSON(http.StatusOK, dto.ToSnapshotResponse(snap))
}
