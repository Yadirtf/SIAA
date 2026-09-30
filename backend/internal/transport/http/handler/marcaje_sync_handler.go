// Package handler — manejador HTTP para sincronización de cola offline.
// Satisface US-MAR-11 (AC-01..AC-07) y contrato POST /api/v1/marcajes/sync.
package handler

import (
	"net/http"
	"time"

	"github.com/labstack/echo/v4"

	domainMarcaje "github.com/siaa/backend/internal/domain/marcaje"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/transport/http/dto"
	"github.com/siaa/backend/internal/transport/http/middleware"
	usecaseMarcaje "github.com/siaa/backend/internal/usecase/marcaje"
)

// MarcajeSyncHandler expone el endpoint de sincronización en lote para clientes móviles.
type MarcajeSyncHandler struct {
	syncUC *usecaseMarcaje.SyncOfflineUseCase
}

func NewMarcajeSyncHandler(syncUC *usecaseMarcaje.SyncOfflineUseCase) *MarcajeSyncHandler {
	return &MarcajeSyncHandler{
		syncUC: syncUC,
	}
}

// SyncOffline procesa la sincronización por lotes de marcajes guardados sin conexión (US-MAR-11).
// POST /api/v1/marcajes/sync
func (h *MarcajeSyncHandler) SyncOffline(c echo.Context) error {
	claims, ok := middleware.GetClaims(c)
	if !ok {
		return shared.NewAuthError(shared.ErrTokenExpirado, "Autenticación requerida")
	}

	var req dto.SyncMarcajesRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Lote offline inválido")
	}

	if len(req.Items) == 0 {
		return c.JSON(http.StatusOK, map[string]interface{}{
			"sincronizados": 0,
			"fallidos":      0,
			"resultados":    []interface{}{},
		})
	}

	itemsDominio := make([]domainMarcaje.SolicitudMarcaje, len(req.Items))
	for i, item := range req.Items {
		itemsDominio[i] = item.ToDomain(claims.UsuarioID)
	}

	ahoraServidor := time.Now().UTC()
	resp, err := h.syncUC.Sincronizar(c.Request().Context(), itemsDominio, claims.UsuarioID, ahoraServidor)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}

	return c.JSON(http.StatusOK, resp)
}
