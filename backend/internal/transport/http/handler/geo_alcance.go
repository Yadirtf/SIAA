// Package handler — ámbito de sedes para la jerarquía física (US-ROL-02 AC-04, AC-06).
// Las sedes visibles salen de los ámbitos del token: una sede asignada, la sede de cada
// facultad asignada y la sede de cada bloque asignado. Solo los roles institucionales ven todo.
package handler

import (
	"context"
	"sort"

	"github.com/labstack/echo/v4"

	domainAca "github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/transport/http/middleware"
)

// LectorFacultades resuelve la sede de una facultad asignada como ámbito.
type LectorFacultades interface {
	GetFacultadByID(ctx context.Context, id string) (*domainAca.Facultad, error)
}

// WithFacultades habilita que un ámbito de facultad abra la sede a la que pertenece.
func (h *GeoHandler) WithFacultades(f LectorFacultades) *GeoHandler {
	h.facultades = f
	return h
}

// sedesVisibles devuelve (true, nil) si el usuario ve todas las sedes, o el conjunto de sedes
// que su ámbito le permite (vacío si no tiene ámbitos).
func (h *GeoHandler) sedesVisibles(c echo.Context) (bool, map[string]bool) {
	claims, ok := middleware.GetClaims(c)
	if !ok || middleware.AccesoTotal(claims) {
		return true, nil
	}
	ctx := c.Request().Context()
	sedes := map[string]bool{}
	for _, a := range claims.Ambitos {
		switch a.Tipo {
		case rbac.ScopeSede:
			sedes[a.ID] = true
		case rbac.ScopeFacultad:
			if h.facultades == nil {
				continue
			}
			if f, err := h.facultades.GetFacultadByID(ctx, a.ID); err == nil && f != nil && f.SedeID() != "" {
				sedes[f.SedeID()] = true
			}
		case rbac.ScopeBloque:
			if b, err := h.svc.ObtenerBloquePorID(ctx, a.ID); err == nil && b != nil && b.SedeID != "" {
				sedes[b.SedeID] = true
			}
		}
	}
	return false, sedes
}

// exigirSede responde 403 auditado si la sede del recurso está fuera del ámbito (AC-02).
func (h *GeoHandler) exigirSede(c echo.Context, sedeID string) error {
	if todas, sedes := h.sedesVisibles(c); todas || sedes[sedeID] {
		return nil
	}
	return middleware.ErrorAmbito(sedeID)
}

// sedesDeConsulta traduce el filtro sedeId del cliente a las sedes a consultar (AC-03): con
// acceso total se respeta tal cual (vacío = todas); si no, una sede pedida fuera del ámbito da
// 403 y sin filtro se consultan solo las sedes del ámbito.
func (h *GeoHandler) sedesDeConsulta(c echo.Context, solicitada string) (todas bool, ids []string, err error) {
	todas, sedes := h.sedesVisibles(c)
	if todas {
		if solicitada == "" {
			return true, nil, nil
		}
		return false, []string{solicitada}, nil
	}
	if solicitada != "" {
		if !sedes[solicitada] {
			return false, nil, middleware.ErrorAmbito(solicitada)
		}
		return false, []string{solicitada}, nil
	}
	for id := range sedes {
		ids = append(ids, id)
	}
	sort.Strings(ids)
	return false, ids, nil
}
