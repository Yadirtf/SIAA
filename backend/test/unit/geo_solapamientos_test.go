// Package unit_test — pruebas unitarias e integración HTTP para US-GEO-05: Detección de solapamientos.
// Valida AC-01..AC-05, T-GEO-05.1..T-GEO-05.5, RF-GEO-007, CA-007, R-01.
package unit_test

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/domain/geo"
	"github.com/siaa/backend/internal/domain/shared"
	applog "github.com/siaa/backend/internal/platform/log"
	"github.com/siaa/backend/internal/repository"
	apphttp "github.com/siaa/backend/internal/transport/http"
	"github.com/siaa/backend/internal/transport/http/dto"
	"github.com/siaa/backend/internal/transport/http/handler"
	"github.com/siaa/backend/internal/transport/http/middleware"
	usecaseGeo "github.com/siaa/backend/internal/usecase/geo"
)

func mustPt(lon, lat float64) geo.GeoPoint {
	pt, err := geo.NewGeoPoint(lon, lat)
	if err != nil {
		panic(err)
	}
	return pt
}

func setupGeoSolapamientosSuite(t *testing.T) (*usecaseGeo.Service, *mockEspacioRepo, *mockGeoAuditoriaRepo, *echo.Echo, string, string) {
	t.Helper()

	sedeRepo := newMockSedeRepo()
	bloqueRepo := newMockBloqueRepo()
	espacioRepo := newMockEspacioRepo()
	sesionChecker := newMockSesionChecker()
	auditRepo := &mockGeoAuditoriaRepo{}
	clk := shared.NewFakeClock(time.Date(2026, 9, 22, 10, 0, 0, 0, time.UTC))
	logger := applog.New(applog.LevelDebug, nil)

	svc := usecaseGeo.NewService(sedeRepo, bloqueRepo, espacioRepo, nil, sesionChecker, auditRepo, clk, logger)

	ctx := context.Background()
	actor := usecaseGeo.ContextoActor{
		ActorID:       "usr-admin-01",
		RolActivo:     "ADMIN_CAMPUS",
		CorrelationID: "corr-solap-001",
		IPOrigen:      "127.0.0.1",
		AgenteUsuario: "TestAgent/1.0",
	}

	sede, err := svc.CrearSede(ctx, usecaseGeo.CrearSedeCmd{
		Codigo:    "SEDE-CENTRAL",
		Nombre:    "Sede Central",
		Direccion: "Carrera 30 # 45-03",
		Actor:     actor,
	})
	if err != nil {
		t.Fatalf("error creando sede de prueba: %v", err)
	}

	bloque, err := svc.CrearBloque(ctx, usecaseGeo.CrearBloqueCmd{
		SedeID: sede.ID,
		Codigo: "BLQ-A",
		Nombre: "Bloque A - Ingenierías",
		Pisos:  []int{1, 2, 3},
		Actor:  actor,
	})
	if err != nil {
		t.Fatalf("error creando bloque de prueba: %v", err)
	}

	// Servidor HTTP Echo para pruebas de capa de transporte
	e := echo.New()
	e.Validator = apphttp.NewValidator()
	e.HTTPErrorHandler = middleware.ErrorHandler(logger)
	geoH := handler.NewGeoHandler(svc)

	api := e.Group("/api/v1")
	api.GET("/espacios/solapamientos", geoH.InformeSolapamientos)
	api.PUT("/espacios/:id/geometria", geoH.ActualizarGeometria)

	return svc, espacioRepo, auditRepo, e, sede.ID, bloque.ID
}

// ─────────────────────────────────────────────────────────────
// AC-01: Advertencia cuando solapamiento <= 50% y no confirmado
// ─────────────────────────────────────────────────────────────
func TestGeo_USGEO05_AC01_SolapamientoParcial_AdvertenciaRequiereConfirmacion(t *testing.T) {
	svc, _, _, _, sedeID, bloqueID := setupGeoSolapamientosSuite(t)
	ctx := context.Background()
	piso1 := 1
	actor := usecaseGeo.ContextoActor{ActorID: "usr-admin-01", RolActivo: "ADMIN_CAMPUS"}

	// 1. Crear espacio E1 (Aula 101) en Piso 1 con polígono de 10m x 20m
	e1, err := svc.CrearEspacio(ctx, usecaseGeo.CrearEspacioCmd{
		SedeID:   sedeID,
		BloqueID: &bloqueID,
		Piso:     &piso1,
		Codigo:   "AULA-101",
		Nombre:   "Aula 101",
		Tipo:     geo.TipoAula,
		Actor:    actor,
	})
	if err != nil {
		t.Fatalf("error creando aula 101: %v", err)
	}

	vE1 := []geo.GeoPoint{
		mustPt(-74.081750, 4.609710),
		mustPt(-74.081570, 4.609710),
		mustPt(-74.081570, 4.609800),
		mustPt(-74.081750, 4.609800),
		mustPt(-74.081750, 4.609710),
	}
	_, err = svc.GuardarGeometriaEspacio(ctx, usecaseGeo.GuardarGeometriaCmd{
		EspacioID:     e1.ID,
		Vertices:      vE1,
		MetodoCaptura: geo.MetodoRecorridoPerimetral,
		Actor:         actor,
	})
	if err != nil {
		t.Fatalf("error asignando geometria a e1: %v", err)
	}

	// 2. Crear espacio E2 (Aula 102) en el mismo piso 1 del mismo bloque
	e2, err := svc.CrearEspacio(ctx, usecaseGeo.CrearEspacioCmd{
		SedeID:   sedeID,
		BloqueID: &bloqueID,
		Piso:     &piso1,
		Codigo:   "AULA-102",
		Nombre:   "Aula 102",
		Tipo:     geo.TipoAula,
		Actor:    actor,
	})
	if err != nil {
		t.Fatalf("error creando aula 102: %v", err)
	}

	// Vértices de E2: solapa exactamente la mitad (50%) de E1 (de x=10 a x=30)
	vE2 := []geo.GeoPoint{
		mustPt(-74.081660, 4.609710),
		mustPt(-74.081480, 4.609710),
		mustPt(-74.081480, 4.609800),
		mustPt(-74.081660, 4.609800),
		mustPt(-74.081660, 4.609710),
	}

	// 3. Intentar guardar sin confirmar (ConfirmarSolapamiento: false)
	_, err = svc.GuardarGeometriaEspacio(ctx, usecaseGeo.GuardarGeometriaCmd{
		EspacioID:             e2.ID,
		Vertices:              vE2,
		MetodoCaptura:         geo.MetodoRecorridoPerimetral,
		ConfirmarSolapamiento: false,
		Actor:                 actor,
	})

	if err == nil {
		t.Fatal("esperaba advertencia/error de validacion ante solapamiento no confirmado, pero se guardó con éxito")
	}

	domErr, ok := shared.AsDomainError(err)
	if !ok {
		t.Fatalf("esperado DomainError, obtenido: %v", err)
	}
	if domErr.Code != shared.ErrValidacion {
		t.Fatalf("esperado codigo error VALIDACION para advertencia, obtenido: %s", domErr.Code)
	}

	// Verificar que el detalle del error contenga el nombre y porcentaje de área
	encontrado := false
	for _, f := range domErr.Fields {
		if f.Campo == "confirmarSolapamiento" && strings.Contains(f.Error, "Aula 101") {
			encontrado = true
			break
		}
	}
	if !encontrado {
		t.Fatalf("esperado detalle indicando solapamiento con 'Aula 101', obtenido campos: %+v", domErr.Fields)
	}
}

// ─────────────────────────────────────────────────────────────
// AC-02: Confirmación explícita y registro en auditoría
// ─────────────────────────────────────────────────────────────
func TestGeo_USGEO05_AC02_SolapamientoParcial_ConfirmadoYAuditado(t *testing.T) {
	svc, _, auditRepo, _, sedeID, bloqueID := setupGeoSolapamientosSuite(t)
	ctx := context.Background()
	piso1 := 1
	actor := usecaseGeo.ContextoActor{ActorID: "usr-admin-01", RolActivo: "ADMIN_CAMPUS"}

	// E1
	e1, _ := svc.CrearEspacio(ctx, usecaseGeo.CrearEspacioCmd{
		SedeID:   sedeID,
		BloqueID: &bloqueID,
		Piso:     &piso1,
		Codigo:   "AULA-101",
		Nombre:   "Aula 101",
		Tipo:     geo.TipoAula,
		Actor:    actor,
	})
	vE1 := []geo.GeoPoint{
		mustPt(-74.081750, 4.609710),
		mustPt(-74.081570, 4.609710),
		mustPt(-74.081570, 4.609800),
		mustPt(-74.081750, 4.609800),
		mustPt(-74.081750, 4.609710),
	}
	_, _ = svc.GuardarGeometriaEspacio(ctx, usecaseGeo.GuardarGeometriaCmd{
		EspacioID:     e1.ID,
		Vertices:      vE1,
		MetodoCaptura: geo.MetodoRecorridoPerimetral,
		Actor:         actor,
	})

	// E2
	e2, _ := svc.CrearEspacio(ctx, usecaseGeo.CrearEspacioCmd{
		SedeID:   sedeID,
		BloqueID: &bloqueID,
		Piso:     &piso1,
		Codigo:   "AULA-102",
		Nombre:   "Aula 102",
		Tipo:     geo.TipoAula,
		Actor:    actor,
	})
	vE2 := []geo.GeoPoint{
		mustPt(-74.081660, 4.609710),
		mustPt(-74.081480, 4.609710),
		mustPt(-74.081480, 4.609800),
		mustPt(-74.081660, 4.609800),
		mustPt(-74.081660, 4.609710),
	}

	// Guardar confirmando explícitamente con motivo
	motivo := "Tolerancia por muro divisorio compartido en remodelación"
	resE2, err := svc.GuardarGeometriaEspacio(ctx, usecaseGeo.GuardarGeometriaCmd{
		EspacioID:             e2.ID,
		Vertices:              vE2,
		MetodoCaptura:         geo.MetodoRecorridoPerimetral,
		ConfirmarSolapamiento: true,
		MotivoSolapamiento:    motivo,
		Actor:                 actor,
	})
	if err != nil {
		t.Fatalf("error inesperado al guardar con confirmacion: %v", err)
	}

	if resE2.Geometria == nil {
		t.Fatal("la geometria debio haberse guardado exitosamente")
	}

	// Verificar auditoría de confirmación
	var auditEntry *repository.AuditEntry
	for _, a := range auditRepo.entries {
		if a.EntidadID == e2.ID && a.Accion == "GEOMETRIA_SOLAPADA_CONFIRMADA" {
			auditEntry = a
			break
		}
	}
	if auditEntry == nil {
		t.Fatal("no se encontro registro en auditoria con accion GEOMETRIA_SOLAPADA_CONFIRMADA")
	}
	if auditEntry.ActorID != actor.ActorID {
		t.Errorf("esperado actor %s, obtenido %s", actor.ActorID, auditEntry.ActorID)
	}
}

// ─────────────────────────────────────────────────────────────
// AC-03: Bloqueo irremovible para solapamiento superior al 50%
// ─────────────────────────────────────────────────────────────
func TestGeo_USGEO05_AC03_SolapamientoMayor50Porciento_BloqueaGuardado(t *testing.T) {
	svc, _, _, _, sedeID, bloqueID := setupGeoSolapamientosSuite(t)
	ctx := context.Background()
	piso1 := 1
	actor := usecaseGeo.ContextoActor{ActorID: "usr-admin-01", RolActivo: "ADMIN_CAMPUS"}

	// E1
	e1, _ := svc.CrearEspacio(ctx, usecaseGeo.CrearEspacioCmd{
		SedeID:   sedeID,
		BloqueID: &bloqueID,
		Piso:     &piso1,
		Codigo:   "AULA-101",
		Nombre:   "Aula 101",
		Tipo:     geo.TipoAula,
		Actor:    actor,
	})
	vE1 := []geo.GeoPoint{
		mustPt(-74.081750, 4.609710),
		mustPt(-74.081570, 4.609710),
		mustPt(-74.081570, 4.609800),
		mustPt(-74.081750, 4.609800),
		mustPt(-74.081750, 4.609710),
	}
	_, _ = svc.GuardarGeometriaEspacio(ctx, usecaseGeo.GuardarGeometriaCmd{
		EspacioID:     e1.ID,
		Vertices:      vE1,
		MetodoCaptura: geo.MetodoRecorridoPerimetral,
		Actor:         actor,
	})

	// E3 solapa al 80% con E1
	e3, _ := svc.CrearEspacio(ctx, usecaseGeo.CrearEspacioCmd{
		SedeID:   sedeID,
		BloqueID: &bloqueID,
		Piso:     &piso1,
		Codigo:   "AULA-103",
		Nombre:   "Aula 103",
		Tipo:     geo.TipoAula,
		Actor:    actor,
	})
	vE3 := []geo.GeoPoint{
		mustPt(-74.081750, 4.609710),
		mustPt(-74.081606, 4.609710), // 80% de ancho
		mustPt(-74.081606, 4.609800),
		mustPt(-74.081750, 4.609800),
		mustPt(-74.081750, 4.609710),
	}

	// Incluso si el usuario pasa ConfirmarSolapamiento: true, debe ser bloqueado
	_, err := svc.GuardarGeometriaEspacio(ctx, usecaseGeo.GuardarGeometriaCmd{
		EspacioID:             e3.ID,
		Vertices:              vE3,
		MetodoCaptura:         geo.MetodoRecorridoPerimetral,
		ConfirmarSolapamiento: true,
		MotivoSolapamiento:    "Intento forzado",
		Actor:                 actor,
	})

	if err == nil {
		t.Fatal("esperaba bloqueo irremovible para solapamiento > 50%, pero se guardó")
	}

	domErr, ok := shared.AsDomainError(err)
	if !ok {
		t.Fatalf("esperado DomainError, obtenido: %v", err)
	}
	if domErr.Code != shared.ErrGeometriaSolapada {
		t.Fatalf("AC-03: esperado codigo de error GEOMETRIA_SOLAPADA, obtenido: %s", domErr.Code)
	}
}

// ─────────────────────────────────────────────────────────────
// AC-04: Informe completo de conflictos GET /espacios/solapamientos
// ─────────────────────────────────────────────────────────────
func TestGeo_USGEO05_AC04_InformeSolapamientosGlobal(t *testing.T) {
	svc, _, _, eEcho, sedeID, bloqueID := setupGeoSolapamientosSuite(t)
	ctx := context.Background()
	piso1 := 1
	actor := usecaseGeo.ContextoActor{ActorID: "usr-admin-01", RolActivo: "ADMIN_CAMPUS"}

	// Dos espacios que se solapan 50%
	e1, _ := svc.CrearEspacio(ctx, usecaseGeo.CrearEspacioCmd{
		SedeID:   sedeID,
		BloqueID: &bloqueID,
		Piso:     &piso1,
		Codigo:   "AULA-101",
		Nombre:   "Aula 101",
		Tipo:     geo.TipoAula,
		Actor:    actor,
	})
	vE1 := []geo.GeoPoint{
		mustPt(-74.081750, 4.609710),
		mustPt(-74.081570, 4.609710),
		mustPt(-74.081570, 4.609800),
		mustPt(-74.081750, 4.609800),
		mustPt(-74.081750, 4.609710),
	}
	_, _ = svc.GuardarGeometriaEspacio(ctx, usecaseGeo.GuardarGeometriaCmd{
		EspacioID:     e1.ID,
		Vertices:      vE1,
		MetodoCaptura: geo.MetodoRecorridoPerimetral,
		Actor:         actor,
	})

	e2, _ := svc.CrearEspacio(ctx, usecaseGeo.CrearEspacioCmd{
		SedeID:   sedeID,
		BloqueID: &bloqueID,
		Piso:     &piso1,
		Codigo:   "AULA-102",
		Nombre:   "Aula 102",
		Tipo:     geo.TipoAula,
		Actor:    actor,
	})
	vE2 := []geo.GeoPoint{
		mustPt(-74.081660, 4.609710),
		mustPt(-74.081480, 4.609710),
		mustPt(-74.081480, 4.609800),
		mustPt(-74.081660, 4.609800),
		mustPt(-74.081660, 4.609710),
	}
	_, _ = svc.GuardarGeometriaEspacio(ctx, usecaseGeo.GuardarGeometriaCmd{
		EspacioID:             e2.ID,
		Vertices:              vE2,
		MetodoCaptura:         geo.MetodoRecorridoPerimetral,
		ConfirmarSolapamiento: true,
		MotivoSolapamiento:    "Permitido",
		Actor:                 actor,
	})

	// 1. Validar a nivel servicio
	informe, err := svc.GenerarInformeSolapamientos(ctx, sedeID, bloqueID)
	if err != nil {
		t.Fatalf("error generando informe: %v", err)
	}
	if len(informe) != 1 {
		t.Fatalf("esperado exactamente 1 conflicto en el informe, obtenido: %d", len(informe))
	}
	if informe[0].Espacio1Codigo != "AULA-101" || informe[0].Espacio2Codigo != "AULA-102" {
		t.Errorf("conflictos esperados entre AULA-101 y AULA-102, obtenido: %s y %s", informe[0].Espacio1Codigo, informe[0].Espacio2Codigo)
	}

	// 2. Validar a nivel HTTP GET /api/v1/espacios/solapamientos
	req := httptest.NewRequest(http.MethodGet, fmt.Sprintf("/api/v1/espacios/solapamientos?sedeId=%s&bloqueId=%s", sedeID, bloqueID), nil)
	rec := httptest.NewRecorder()
	eEcho.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("GET /espacios/solapamientos retorno %d, esperado 200", rec.Code)
	}

	var resp dto.InformeSolapamientosResponse
	if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
		t.Fatalf("error deserializando respuesta del informe: %v", err)
	}
	if resp.TotalConflictos != 1 {
		t.Fatalf("totalConflictos esperado 1, obtenido %d", resp.TotalConflictos)
	}
	if resp.Conflictos[0].PorcentajeSolapado <= 0 {
		t.Errorf("porcentaje solapado esperado > 0, obtenido %f", resp.Conflictos[0].PorcentajeSolapado)
	}
}

// ─────────────────────────────────────────────────────────────
// AC-05: Espacios en pisos distintos no se reportan (R-01)
// ─────────────────────────────────────────────────────────────
func TestGeo_USGEO05_AC05_PisosDistintos_NoReportanSolapamiento_R01(t *testing.T) {
	svc, _, _, _, sedeID, bloqueID := setupGeoSolapamientosSuite(t)
	ctx := context.Background()
	piso1 := 1
	piso2 := 2
	actor := usecaseGeo.ContextoActor{ActorID: "usr-admin-01", RolActivo: "ADMIN_CAMPUS"}

	// Coordenadas idénticas para ambos espacios (huella vertical superpuesta)
	vPoligono := []geo.GeoPoint{
		mustPt(-74.081750, 4.609710),
		mustPt(-74.081570, 4.609710),
		mustPt(-74.081570, 4.609800),
		mustPt(-74.081750, 4.609800),
		mustPt(-74.081750, 4.609710),
	}

	// 1. E1: Aula 101 en Piso 1
	e1, err := svc.CrearEspacio(ctx, usecaseGeo.CrearEspacioCmd{
		SedeID:   sedeID,
		BloqueID: &bloqueID,
		Piso:     &piso1,
		Codigo:   "AULA-101",
		Nombre:   "Aula 101",
		Tipo:     geo.TipoAula,
		Actor:    actor,
	})
	if err != nil {
		t.Fatalf("error creando aula 101: %v", err)
	}
	_, err = svc.GuardarGeometriaEspacio(ctx, usecaseGeo.GuardarGeometriaCmd{
		EspacioID:     e1.ID,
		Vertices:      vPoligono,
		MetodoCaptura: geo.MetodoRecorridoPerimetral,
		Actor:         actor,
	})
	if err != nil {
		t.Fatalf("error asignando geometria a e1: %v", err)
	}

	// 2. E2: Aula 201 en Piso 2 (mismo bloque, huella 100% idéntica)
	e2, err := svc.CrearEspacio(ctx, usecaseGeo.CrearEspacioCmd{
		SedeID:   sedeID,
		BloqueID: &bloqueID,
		Piso:     &piso2,
		Codigo:   "AULA-201",
		Nombre:   "Aula 201",
		Tipo:     geo.TipoAula,
		Actor:    actor,
	})
	if err != nil {
		t.Fatalf("error creando aula 201: %v", err)
	}

	// AC-05 / R-01: NO debe reportar solapamiento ni requerir confirmación
	resE2, err := svc.GuardarGeometriaEspacio(ctx, usecaseGeo.GuardarGeometriaCmd{
		EspacioID:             e2.ID,
		Vertices:              vPoligono,
		MetodoCaptura:         geo.MetodoRecorridoPerimetral,
		ConfirmarSolapamiento: false, // sin confirmación, debe pasar directo
		Actor:                 actor,
	})
	if err != nil {
		t.Fatalf("AC-05 fallo: no debio fallar ni reportar solapamiento para pisos distintos: %v", err)
	}
	if resE2.Geometria == nil {
		t.Fatal("la geometria de Aula 201 en piso 2 debio guardarse exitosamente")
	}

	// Verificar que el informe tampoco reporte conflicto
	informe, err := svc.GenerarInformeSolapamientos(ctx, sedeID, bloqueID)
	if err != nil {
		t.Fatalf("error generando informe: %v", err)
	}
	if len(informe) != 0 {
		t.Fatalf("AC-05 fallo: no debe haber conflictos en informe entre pisos distintos, obtenido: %d", len(informe))
	}
}

// ─────────────────────────────────────────────────────────────
// Test HTTP PUT /espacios/:id/geometria con códigos de error
// ─────────────────────────────────────────────────────────────
func TestGeo_USGEO05_HTTP_GeometriaSolapadaCodigos(t *testing.T) {
	svc, _, _, eEcho, sedeID, bloqueID := setupGeoSolapamientosSuite(t)
	ctx := context.Background()
	piso1 := 1
	actor := usecaseGeo.ContextoActor{ActorID: "usr-admin-01", RolActivo: "ADMIN_CAMPUS"}

	// E1
	e1, _ := svc.CrearEspacio(ctx, usecaseGeo.CrearEspacioCmd{
		SedeID:   sedeID,
		BloqueID: &bloqueID,
		Piso:     &piso1,
		Codigo:   "AULA-101",
		Nombre:   "Aula 101",
		Tipo:     geo.TipoAula,
		Actor:    actor,
	})
	vE1 := []geo.GeoPoint{
		mustPt(-74.081750, 4.609710),
		mustPt(-74.081570, 4.609710),
		mustPt(-74.081570, 4.609800),
		mustPt(-74.081750, 4.609800),
		mustPt(-74.081750, 4.609710),
	}
	_, _ = svc.GuardarGeometriaEspacio(ctx, usecaseGeo.GuardarGeometriaCmd{
		EspacioID:     e1.ID,
		Vertices:      vE1,
		MetodoCaptura: geo.MetodoRecorridoPerimetral,
		Actor:         actor,
	})

	// E2
	e2, _ := svc.CrearEspacio(ctx, usecaseGeo.CrearEspacioCmd{
		SedeID:   sedeID,
		BloqueID: &bloqueID,
		Piso:     &piso1,
		Codigo:   "AULA-102",
		Nombre:   "Aula 102",
		Tipo:     geo.TipoAula,
		Actor:    actor,
	})

	// Caso 1: Solapamiento > 50% vía HTTP PUT -> debe retornar HTTP 409 Conflict (GEOMETRIA_SOLAPADA)
	body80 := `{"metodoCaptura":"RECORRIDO_PERIMETRAL","coordenadas":[[-74.08175,4.60971],[-74.081606,4.60971],[-74.081606,4.60980],[-74.08175,4.60980]]}`
	req409 := httptest.NewRequest(http.MethodPut, "/api/v1/espacios/"+e2.ID+"/geometria", strings.NewReader(body80))
	req409.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	rec409 := httptest.NewRecorder()
	eEcho.ServeHTTP(rec409, req409)

	if rec409.Code != http.StatusConflict {
		t.Fatalf("esperado status 409 Conflict para solapamiento > 50%%, obtenido %d: %s", rec409.Code, rec409.Body.String())
	}
	if !strings.Contains(rec409.Body.String(), "GEOMETRIA_SOLAPADA") {
		t.Fatalf("esperado codigo GEOMETRIA_SOLAPADA en respuesta JSON, obtenido: %s", rec409.Body.String())
	}

	// Caso 2: Solapamiento 50% no confirmado -> debe retornar HTTP 422 Unprocessable Entity
	body50NoConf := `{"metodoCaptura":"RECORRIDO_PERIMETRAL","confirmarSolapamiento":false,"coordenadas":[[-74.08166,4.60971],[-74.08148,4.60971],[-74.08148,4.60980],[-74.08166,4.60980]]}`
	req422 := httptest.NewRequest(http.MethodPut, "/api/v1/espacios/"+e2.ID+"/geometria", strings.NewReader(body50NoConf))
	req422.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	rec422 := httptest.NewRecorder()
	eEcho.ServeHTTP(rec422, req422)

	if rec422.Code != http.StatusUnprocessableEntity {
		t.Fatalf("esperado status 422 para advertencia sin confirmacion, obtenido %d: %s", rec422.Code, rec422.Body.String())
	}

	// Caso 3: Solapamiento 50% confirmado con motivo -> debe retornar HTTP 200 OK
	body50Conf := `{"metodoCaptura":"RECORRIDO_PERIMETRAL","confirmarSolapamiento":true,"motivoSolapamiento":"Aceptado","coordenadas":[[-74.08166,4.60971],[-74.08148,4.60971],[-74.08148,4.60980],[-74.08166,4.60980]]}`
	req200 := httptest.NewRequest(http.MethodPut, "/api/v1/espacios/"+e2.ID+"/geometria", strings.NewReader(body50Conf))
	req200.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	rec200 := httptest.NewRecorder()
	eEcho.ServeHTTP(rec200, req200)

	if rec200.Code != http.StatusOK {
		t.Fatalf("esperado status 200 OK tras confirmacion explícita, obtenido %d: %s", rec200.Code, rec200.Body.String())
	}
}
