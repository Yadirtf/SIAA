// Package unit — pruebas unitarias para US-GEO-04 (Validación geométrica de polígono).
// AC-01..AC-05, T-GEO-04.1..T-GEO-04.6.
package unit

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/labstack/echo/v4"
	"github.com/stretchr/testify/assert"

	"github.com/siaa/backend/internal/domain/geo"
	"github.com/siaa/backend/internal/platform/clock"
	applog "github.com/siaa/backend/internal/platform/log"
	apphttp "github.com/siaa/backend/internal/transport/http"
	"github.com/siaa/backend/internal/transport/http/dto"
	"github.com/siaa/backend/internal/transport/http/handler"
	usecaseGeo "github.com/siaa/backend/internal/usecase/geo"
)

// AC-01: Rechazo si hay menos de 3 vértices distintos.
func TestValidarGeometria_VerticesInsuficientes(t *testing.T) {
	// Caso 1: Solo 2 coordenadas
	coords2 := [][2]float64{
		{-74.08, 4.63},
		{-74.07, 4.63},
	}
	res2 := geo.ValidarGeometriaPoligono(coords2, 6.0, 5000.0)
	assert.False(t, res2.Valido)
	assert.Equal(t, geo.MotivoVerticesInsuficientes, res2.Codigo)

	// Caso 2: 3 coordenadas pero dos repetidas (solo 2 únicas)
	coordsRep := [][2]float64{
		{-74.08, 4.63},
		{-74.08, 4.63},
		{-74.07, 4.63},
	}
	resRep := geo.ValidarGeometriaPoligono(coordsRep, 6.0, 5000.0)
	assert.False(t, resRep.Valido)
	assert.Equal(t, geo.MotivoVerticesInsuficientes, resRep.Codigo)
}

// AC-02: Rechazo si los lados se auto-intersectan (polígono no simple) y señalización de conflicto.
func TestValidarGeometria_PoligonoNoSimple_Autointerseccion(t *testing.T) {
	// Forma de reloj de arena / corbatín (auto-intersección en forma de X)
	coordsX := [][2]float64{
		{-74.080, 4.630},
		{-74.078, 4.632},
		{-74.080, 4.632},
		{-74.078, 4.630},
		{-74.080, 4.630},
	}
	res := geo.ValidarGeometriaPoligono(coordsX, 6.0, 5000.0)
	assert.False(t, res.Valido)
	assert.Equal(t, geo.MotivoPoligonoNoSimple, res.Codigo)
	assert.NotEmpty(t, res.SegmentosConflicto, "debe señalar los segmentos que cruzan (AC-02)")
	assert.GreaterOrEqual(t, len(res.SegmentosConflicto), 1)
}

// AC-03: Cierre automático si el primer y último vértice no coinciden.
func TestValidarGeometria_PoligonoNoCerrado_CierreAutomatico(t *testing.T) {
	// Aula rectangular sin vértice de cierre repetido
	coordsAbiertas := [][2]float64{
		{-74.08389, 4.63819},
		{-74.08379, 4.63819},
		{-74.08379, 4.63825},
		{-74.08389, 4.63825},
	}
	res := geo.ValidarGeometriaPoligono(coordsAbiertas, 6.0, 5000.0)
	assert.True(t, res.Valido)
	assert.True(t, res.PoligonoCerrado)
	assert.NotEmpty(t, res.Advertencias)
	assert.Contains(t, res.Advertencias[0], "AC-03")
}

// AC-04: Rechazo si el área calculada queda fuera del rango configurable.
func TestValidarGeometria_AreaFueraDeRango(t *testing.T) {
	// Caso 1: Área diminuta (< 6 m²)
	// Un triángulo minúsculo de ~0.05 m²
	coordsDiminutas := [][2]float64{
		{-74.0800000, 4.6300000},
		{-74.0800001, 4.6300000},
		{-74.0800001, 4.6300001},
		{-74.0800000, 4.6300000},
	}
	resDim := geo.ValidarGeometriaPoligono(coordsDiminutas, 6.0, 5000.0)
	assert.False(t, resDim.Valido)
	assert.Equal(t, geo.MotivoAreaFueraDeRango, resDim.Codigo)
	assert.Less(t, resDim.AreaMetrosCuadrados, 6.0)

	// Caso 2: Área enorme (> 5000 m²)
	// Cuadrado de ~0.01 grados (~1.1 km por lado -> > 1.000.000 m²)
	coordsEnormes := [][2]float64{
		{-74.08, 4.63},
		{-74.07, 4.63},
		{-74.07, 4.64},
		{-74.08, 4.64},
		{-74.08, 4.63},
	}
	resEnorme := geo.ValidarGeometriaPoligono(coordsEnormes, 6.0, 5000.0)
	assert.False(t, resEnorme.Valido)
	assert.Equal(t, geo.MotivoAreaFueraDeRango, resEnorme.Codigo)
	assert.Greater(t, resEnorme.AreaMetrosCuadrados, 5000.0)
}

// AC-05: Validación exitosa devuelve área, centroide, perímetro sin persistir nada.
func TestValidarGeometria_Exitoso(t *testing.T) {
	// Aula estándar (~65 m²)
	coordsAula := [][2]float64{
		{-74.08389, 4.63819},
		{-74.08379, 4.63819},
		{-74.08379, 4.63825},
		{-74.08389, 4.63825},
		{-74.08389, 4.63819},
	}
	res := geo.ValidarGeometriaPoligono(coordsAula, 6.0, 5000.0)
	assert.True(t, res.Valido)
	assert.Empty(t, res.Codigo)
	assert.Greater(t, res.AreaMetrosCuadrados, 40.0)
	assert.Less(t, res.AreaMetrosCuadrados, 100.0)
	assert.Greater(t, res.PerimetroMetros, 20.0)
	assert.NotNil(t, res.Centroide)
	assert.InDelta(t, -74.08384, res.Centroide.Longitud(), 0.0001)
	assert.InDelta(t, 4.63822, res.Centroide.Latitud(), 0.0001)
}

// AC-05: Prueba de integración HTTP para POST /api/v1/espacios/validar-geometria sin persistencia.
func TestHandler_ValidarGeometria_Endpoint(t *testing.T) {
	e := echo.New()
	e.Validator = apphttp.NewValidator()
	log := applog.New(applog.LevelDebug, nil)
	clk := clock.RealClock{}
	svc := usecaseGeo.NewService(nil, nil, nil, nil, nil, nil, clk, log)
	h := handler.NewGeoHandler(svc)

	bodyJSON := `{
		"coordenadas": [
			[-74.08389, 4.63819],
			[-74.08379, 4.63819],
			[-74.08379, 4.63825],
			[-74.08389, 4.63825]
		]
	}`

	req := httptest.NewRequest(http.MethodPost, "/api/v1/espacios/validar-geometria", strings.NewReader(bodyJSON))
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)

	err := h.ValidarGeometria(c)
	assert.NoError(t, err)
	assert.Equal(t, http.StatusOK, rec.Code)

	var resp dto.ValidarGeometriaResponse
	err = json.Unmarshal(rec.Body.Bytes(), &resp)
	assert.NoError(t, err)
	assert.True(t, resp.Valido)
	assert.True(t, resp.PoligonoCerrado)
	assert.Greater(t, resp.AreaMetrosCuadrados, 40.0)
	assert.NotNil(t, resp.Centroide)
	assert.NotEmpty(t, resp.Advertencias)
}
