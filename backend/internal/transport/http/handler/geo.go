// Package handler — manejador HTTP para la jerarquía física de espacios (US-GEO-01).
package handler

import (
	"net/http"
	"strconv"

	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/domain/geo"
	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/repository"
	"github.com/siaa/backend/internal/transport/http/dto"
	"github.com/siaa/backend/internal/transport/http/middleware"
	usecaseGeo "github.com/siaa/backend/internal/usecase/geo"
)

// GeoHandler maneja las peticiones HTTP de sedes, bloques y espacios.
type GeoHandler struct {
	svc *usecaseGeo.Service
}

func NewGeoHandler(svc *usecaseGeo.Service) *GeoHandler {
	return &GeoHandler{svc: svc}
}

// ─────────────────────────────────────────────────────────────
// ESPACIOS
// ─────────────────────────────────────────────────────────────

func (h *GeoHandler) CrearEspacio(c echo.Context) error {
	var req dto.CrearEspacioRequest
	if err := c.Bind(&req); err != nil {
		return err
	}
	if err := c.Validate(&req); err != nil {
		return err
	}

	actor := extraerActor(c)
	espacio, err := h.svc.CrearEspacio(c.Request().Context(), usecaseGeo.CrearEspacioCmd{
		SedeID:              req.SedeID,
		Torre:               req.Torre,
		BloqueID:            req.BloqueID,
		Piso:                req.Piso,
		Codigo:              req.Codigo,
		Nombre:              req.Nombre,
		Capacidad:           req.Capacidad,
		Tipo:                req.Tipo,
		FacultadResponsable: req.FacultadResponsable,
		Estado:              req.Estado,
		NivelValidacion:     req.NivelValidacion,
		BufferMetros:        req.BufferMetros,
		Actor:               actor,
	})
	if err != nil {
		return err
	}

	return c.JSON(http.StatusCreated, dto.EspacioToResponse(espacio))
}

func (h *GeoHandler) ListarEspacios(c echo.Context) error {
	claims, _ := middleware.GetClaims(c)
	sedeID, err := middleware.EnforceScopeFilter(claims, rbac.ScopeSede, c.QueryParam("sedeId"))
	if err != nil {
		return err
	}

	filter := repository.EspacioFilter{
		SedeID:   sedeID,
		BloqueID: c.QueryParam("bloqueId"),
	}
	if pStr := c.QueryParam("piso"); pStr != "" {
		if p, err := strconv.Atoi(pStr); err == nil {
			filter.Piso = &p
		}
	}
	if tStr := c.QueryParam("tipo"); tStr != "" {
		t := geo.TipoEspacio(tStr)
		filter.Tipo = &t
	}
	if eStr := c.QueryParam("estado"); eStr != "" {
		e := geo.EstadoEspacio(eStr)
		filter.Estado = &e
	}

	espacios, err := h.svc.ListarEspacios(c.Request().Context(), filter)
	if err != nil {
		return err
	}

	res := make([]dto.EspacioResponse, 0, len(espacios))
	for _, e := range espacios {
		res = append(res, dto.EspacioToResponse(e))
	}
	return c.JSON(http.StatusOK, res)
}

func (h *GeoHandler) ObtenerEspacio(c echo.Context) error {
	id := c.Param("id")
	espacio, err := h.svc.ObtenerEspacioPorID(c.Request().Context(), id)
	if err != nil {
		return err
	}

	claims, _ := middleware.GetClaims(c)
	if err := middleware.ValidateResourceScope(claims, rbac.ScopeSede, espacio.SedeID); err != nil {
		return err
	}

	return c.JSON(http.StatusOK, dto.EspacioToResponse(espacio))
}

func (h *GeoHandler) ActualizarEspacio(c echo.Context) error {
	id := c.Param("id")
	var req dto.ActualizarEspacioRequest
	if err := c.Bind(&req); err != nil {
		return err
	}
	if err := c.Validate(&req); err != nil {
		return err
	}

	actor := extraerActor(c)
	espacio, err := h.svc.ActualizarEspacio(c.Request().Context(), id, usecaseGeo.ActualizarEspacioCmd{
		SedeID:              req.SedeID,
		Torre:               req.Torre,
		BloqueID:            req.BloqueID,
		Piso:                req.Piso,
		Codigo:              req.Codigo,
		Nombre:              req.Nombre,
		Capacidad:           req.Capacidad,
		Tipo:                req.Tipo,
		FacultadResponsable: req.FacultadResponsable,
		Estado:              req.Estado,
		NivelValidacion:     req.NivelValidacion,
		BufferMetros:        req.BufferMetros,
		ConfirmarImpacto:    req.ConfirmarImpacto,
		Actor:               actor,
	})
	if err != nil {
		return err
	}

	return c.JSON(http.StatusOK, dto.EspacioToResponse(espacio))
}

func (h *GeoHandler) EliminarEspacio(c echo.Context) error {
	id := c.Param("id")
	actor := extraerActor(c)

	if err := h.svc.EliminarEspacio(c.Request().Context(), id, actor); err != nil {
		return err
	}

	return c.NoContent(http.StatusNoContent)
}

// ActualizarGeometria maneja PUT /api/v1/espacios/:id/geometria.
// RF-GEO-002, T-GEO-02.7, AC-06, AC-07, ADR-04.
func (h *GeoHandler) ActualizarGeometria(c echo.Context) error {
	id := c.Param("id")
	var req dto.ActualizarGeometriaRequest
	if err := c.Bind(&req); err != nil {
		return err
	}
	if err := c.Validate(&req); err != nil {
		return err
	}

	vertices := make([]geo.GeoPoint, 0, len(req.Coordenadas))
	for _, coord := range req.Coordenadas {
		pt, err := geo.NewGeoPoint(coord[0], coord[1])
		if err != nil {
			return err
		}
		vertices = append(vertices, pt)
	}

	var centroide *geo.GeoPoint
	if req.Centroide != nil {
		if pt, errPt := geo.NewGeoPoint(req.Centroide[0], req.Centroide[1]); errPt == nil {
			centroide = &pt
		}
	}

	actor := extraerActor(c)
	espacio, err := h.svc.GuardarGeometriaEspacio(c.Request().Context(), usecaseGeo.GuardarGeometriaCmd{
		EspacioID:               id,
		Vertices:                vertices,
		Centroide:               centroide,
		RadioMetros:             req.RadioMetros,
		MetodoCaptura:           req.MetodoCaptura,
		PrecisionPromedioMetros: req.PrecisionPromedioMetros,
		ConfirmarSolapamiento:   req.ConfirmarSolapamiento,
		MotivoSolapamiento:      req.MotivoSolapamiento,
		Actor:                   actor,
	})
	if err != nil {
		return err
	}

	return c.JSON(http.StatusOK, dto.EspacioToResponse(espacio))
}

// InformeSolapamientos maneja GET /api/v1/espacios/solapamientos.
// AC-04, T-GEO-05.3.
func (h *GeoHandler) InformeSolapamientos(c echo.Context) error {
	sedeID := c.QueryParam("sedeId")
	bloqueID := c.QueryParam("bloqueId")

	informe, err := h.svc.GenerarInformeSolapamientos(c.Request().Context(), sedeID, bloqueID)
	if err != nil {
		return err
	}

	items := make([]dto.SolapamientoItemResponse, 0, len(informe))
	for _, it := range informe {
		items = append(items, dto.SolapamientoItemResponse{
			SedeID:             it.SedeID,
			BloqueID:           it.BloqueID,
			Piso:               it.Piso,
			Espacio1ID:         it.Espacio1ID,
			Espacio1Codigo:     it.Espacio1Codigo,
			Espacio1Nombre:     it.Espacio1Nombre,
			Espacio2ID:         it.Espacio2ID,
			Espacio2Codigo:     it.Espacio2Codigo,
			Espacio2Nombre:     it.Espacio2Nombre,
			AreaSolapadaM2:     it.AreaSolapadaM2,
			PorcentajeSolapado: it.PorcentajeSolapado,
			EsCritico:          it.EsCritico,
		})
	}

	return c.JSON(http.StatusOK, dto.InformeSolapamientosResponse{
		TotalConflictos: len(items),
		Conflictos:      items,
	})
}

// ListarVersionesGeometria maneja GET /api/v1/espacios/:id/geometria/versiones.
// US-GEO-06 AC-04, T-GEO-06.3.
func (h *GeoHandler) ListarVersionesGeometria(c echo.Context) error {
	id := c.Param("id")
	versiones, err := h.svc.ListarVersionesGeometria(c.Request().Context(), id)
	if err != nil {
		return err
	}

	res := make([]dto.EspacioGeometriaHistResponse, 0, len(versiones))
	for _, v := range versiones {
		res = append(res, dto.EspacioGeometriaHistToResponse(v))
	}
	return c.JSON(http.StatusOK, res)
}

// ObtenerVersionGeometria maneja GET /api/v1/espacios/:id/geometria/versiones/:version.
// US-GEO-06 AC-03, T-GEO-06.3.
func (h *GeoHandler) ObtenerVersionGeometria(c echo.Context) error {
	id := c.Param("id")
	versionStr := c.Param("version")
	version, err := strconv.Atoi(versionStr)
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "El número de versión debe ser un entero válido")
	}

	hist, err := h.svc.ObtenerVersionGeometria(c.Request().Context(), id, version)
	if err != nil {
		return err
	}
	return c.JSON(http.StatusOK, dto.EspacioGeometriaHistToResponse(hist))
}

// ─────────────────────────────────────────────────────────────
// HELPER EXTRAER ACTOR
// ─────────────────────────────────────────────────────────────

func extraerActor(c echo.Context) usecaseGeo.ContextoActor {
	correlationID, _ := c.Get(middleware.CtxCorrelationID).(string)
	actorID, _ := c.Get(middleware.CtxUsuarioID).(string)
	rolActivo := ""
	if claims, ok := middleware.GetClaims(c); ok {
		rolActivo = claims.RolActivo
	}
	return usecaseGeo.ContextoActor{
		ActorID:       actorID,
		RolActivo:     rolActivo,
		CorrelationID: correlationID,
		IPOrigen:      c.RealIP(),
		AgenteUsuario: c.Request().UserAgent(),
	}
}
