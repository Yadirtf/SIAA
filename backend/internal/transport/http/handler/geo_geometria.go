// Package handler — guardado de la geometría de un espacio con control optimista de versión.
package handler

import (
	"net/http"
	"strconv"
	"strings"

	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/domain/geo"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/transport/http/dto"
	usecaseGeo "github.com/siaa/backend/internal/usecase/geo"
)

// ActualizarGeometria maneja PUT /api/v1/espacios/:id/geometria.
// RF-GEO-002, T-GEO-02.7, AC-06, AC-07, ADR-04. La precondición optimista (If-Match o
// versionEsperada) es opcional: sin ella se conserva el comportamiento previo.
func (h *GeoHandler) ActualizarGeometria(c echo.Context) error {
	id := c.Param("id")
	var req dto.ActualizarGeometriaRequest
	if err := c.Bind(&req); err != nil {
		return err
	}
	if err := c.Validate(&req); err != nil {
		return err
	}
	esperada, err := versionEsperada(c.Request().Header.Get("If-Match"), req.VersionEsperada)
	if err != nil {
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

	espacio, err := h.svc.GuardarGeometriaEspacio(c.Request().Context(), usecaseGeo.GuardarGeometriaCmd{
		EspacioID:               id,
		Vertices:                vertices,
		Centroide:               centroide,
		RadioMetros:             req.RadioMetros,
		MetodoCaptura:           req.MetodoCaptura,
		PrecisionPromedioMetros: req.PrecisionPromedioMetros,
		ConfirmarSolapamiento:   req.ConfirmarSolapamiento,
		MotivoSolapamiento:      req.MotivoSolapamiento,
		VersionEsperada:         esperada,
		Actor:                   extraerActor(c),
	})
	if err != nil {
		return err
	}

	c.Response().Header().Set("ETag", etagGeometria(espacio.VersionGeometria))
	return c.JSON(http.StatusOK, dto.EspacioToResponse(espacio))
}

// etagGeometria representa la versión de geometría como ETag fuerte: "3".
func etagGeometria(version int) string {
	return `"` + strconv.Itoa(version) + `"`
}

// versionEsperada combina la cabecera If-Match ("3", W/"3", 3 o *) con el campo del cuerpo.
// Si ambas vienen y difieren, la petición es ambigua y se rechaza con 422.
func versionEsperada(ifMatch string, cuerpo *int) (*int, error) {
	ifMatch = strings.TrimSpace(ifMatch)
	if ifMatch == "" || ifMatch == "*" {
		return cuerpo, nil
	}
	valor := strings.Trim(strings.TrimPrefix(ifMatch, "W/"), `"`)
	v, err := strconv.Atoi(valor)
	if err != nil || v < 0 {
		return nil, shared.NewValidationError("La cabecera If-Match debe contener la versionGeometria vigente",
			shared.FieldError{Campo: "If-Match", Error: "PRECONDICION_INVALIDA"})
	}
	if cuerpo != nil && *cuerpo != v {
		return nil, shared.NewValidationError("If-Match y versionEsperada no coinciden",
			shared.FieldError{Campo: "versionEsperada", Error: "PRECONDICION_AMBIGUA"})
	}
	return &v, nil
}
