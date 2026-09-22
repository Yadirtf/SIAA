// Package unit_test — pruebas unitarias para US-GEO-01: Jerarquía física de espacios.
// Valida AC-01..AC-06, T-GEO-01.1..T-GEO-01.6, RF-GEO-001, RF-GEO-014, RF-AUD-005.
package unit_test

import (
	"context"
	"encoding/json"
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

// ─────────────────────────────────────────────────────────────
// MOCKS EN MEMORIA
// ─────────────────────────────────────────────────────────────

type mockSedeRepo struct {
	sedes map[string]*geo.Sede
}

func newMockSedeRepo() *mockSedeRepo {
	return &mockSedeRepo{sedes: make(map[string]*geo.Sede)}
}

func (m *mockSedeRepo) Create(ctx context.Context, s *geo.Sede) error {
	if s.ID == "" {
		s.ID = shared.NewID()
	}
	m.sedes[s.ID] = s
	return nil
}

func (m *mockSedeRepo) FindByID(ctx context.Context, id string) (*geo.Sede, error) {
	s, ok := m.sedes[id]
	if !ok || s.Eliminado {
		return nil, nil
	}
	return s, nil
}

func (m *mockSedeRepo) FindByCodigo(ctx context.Context, codigo string) (*geo.Sede, error) {
	for _, s := range m.sedes {
		if s.Codigo == codigo && !s.Eliminado {
			return s, nil
		}
	}
	return nil, nil
}

func (m *mockSedeRepo) List(ctx context.Context) ([]*geo.Sede, error) {
	var list []*geo.Sede
	for _, s := range m.sedes {
		if !s.Eliminado {
			list = append(list, s)
		}
	}
	return list, nil
}

func (m *mockSedeRepo) Update(ctx context.Context, s *geo.Sede) error {
	m.sedes[s.ID] = s
	return nil
}

func (m *mockSedeRepo) SoftDelete(ctx context.Context, id string) error {
	if s, ok := m.sedes[id]; ok {
		s.Eliminado = true
		s.Activo = false
	}
	return nil
}

// Bloque Mock
type mockBloqueRepo struct {
	bloques map[string]*geo.Bloque
}

func newMockBloqueRepo() *mockBloqueRepo {
	return &mockBloqueRepo{bloques: make(map[string]*geo.Bloque)}
}

func (m *mockBloqueRepo) Create(ctx context.Context, b *geo.Bloque) error {
	if b.ID == "" {
		b.ID = shared.NewID()
	}
	m.bloques[b.ID] = b
	return nil
}

func (m *mockBloqueRepo) FindByID(ctx context.Context, id string) (*geo.Bloque, error) {
	b, ok := m.bloques[id]
	if !ok || b.Eliminado {
		return nil, nil
	}
	return b, nil
}

func (m *mockBloqueRepo) FindByCodigo(ctx context.Context, sedeID, codigo string) (*geo.Bloque, error) {
	for _, b := range m.bloques {
		if b.SedeID == sedeID && b.Codigo == codigo && !b.Eliminado {
			return b, nil
		}
	}
	return nil, nil
}

func (m *mockBloqueRepo) ListBySede(ctx context.Context, sedeID string) ([]*geo.Bloque, error) {
	var list []*geo.Bloque
	for _, b := range m.bloques {
		if b.SedeID == sedeID && !b.Eliminado {
			list = append(list, b)
		}
	}
	return list, nil
}

func (m *mockBloqueRepo) List(ctx context.Context) ([]*geo.Bloque, error) {
	var list []*geo.Bloque
	for _, b := range m.bloques {
		if !b.Eliminado {
			list = append(list, b)
		}
	}
	return list, nil
}

func (m *mockBloqueRepo) Update(ctx context.Context, b *geo.Bloque) error {
	m.bloques[b.ID] = b
	return nil
}

func (m *mockBloqueRepo) SoftDelete(ctx context.Context, id string) error {
	if b, ok := m.bloques[id]; ok {
		b.Eliminado = true
		b.Activo = false
	}
	return nil
}

// Espacio Mock
type mockEspacioRepo struct {
	espacios map[string]*geo.Espacio
}

func newMockEspacioRepo() *mockEspacioRepo {
	return &mockEspacioRepo{espacios: make(map[string]*geo.Espacio)}
}

func (m *mockEspacioRepo) Create(ctx context.Context, e *geo.Espacio) error {
	if e.ID == "" {
		e.ID = shared.NewID()
	}
	m.espacios[e.ID] = e
	return nil
}

func (m *mockEspacioRepo) FindByID(ctx context.Context, id string) (*geo.Espacio, error) {
	e, ok := m.espacios[id]
	if !ok || e.Eliminado {
		return nil, nil
	}
	return e, nil
}

func (m *mockEspacioRepo) FindByCodigo(ctx context.Context, codigo string) (*geo.Espacio, error) {
	for _, e := range m.espacios {
		if e.Codigo == codigo && !e.Eliminado {
			return e, nil
		}
	}
	return nil, nil
}

func (m *mockEspacioRepo) List(ctx context.Context, f repository.EspacioFilter) ([]*geo.Espacio, error) {
	var list []*geo.Espacio
	for _, e := range m.espacios {
		if e.Eliminado {
			continue
		}
		if f.SedeID != "" && e.SedeID != f.SedeID {
			continue
		}
		if f.BloqueID != "" && (e.BloqueID == nil || *e.BloqueID != f.BloqueID) {
			continue
		}
		if f.Piso != nil && (e.Piso == nil || *e.Piso != *f.Piso) {
			continue
		}
		if f.Tipo != nil && e.Tipo != *f.Tipo {
			continue
		}
		if f.Estado != nil && e.Estado != *f.Estado {
			continue
		}
		list = append(list, e)
	}
	return list, nil
}

func (m *mockEspacioRepo) Update(ctx context.Context, e *geo.Espacio) error {
	m.espacios[e.ID] = e
	return nil
}

func (m *mockEspacioRepo) SoftDelete(ctx context.Context, id string) error {
	if e, ok := m.espacios[id]; ok {
		e.Eliminado = true
		e.Activo = false
	}
	return nil
}

func (m *mockEspacioRepo) BuscarIntersecciones(ctx context.Context, espacioID string, bloqueID *string, piso *int, geom geo.GeoPolygon) ([]*geo.Espacio, error) {
	var matches []*geo.Espacio
	for _, e := range m.espacios {
		if e.ID == espacioID || e.Eliminado || !e.Activo || e.Geometria == nil {
			continue
		}
		if bloqueID != nil && *bloqueID != "" {
			if e.BloqueID == nil || *e.BloqueID != *bloqueID {
				continue
			}
		}
		if piso != nil {
			if e.Piso == nil || *e.Piso != *piso {
				continue
			}
		}
		area, pct := geo.CalcularAreaSolapadaGeodesica(geom, *e.Geometria)
		if pct > 0.01 || area > 0.01 {
			matches = append(matches, e)
		}
	}
	return matches, nil
}


// Sesion Future Checker Mock
type mockSesionChecker struct {
	conteoPorEspacio map[string]int64
}

func newMockSesionChecker() *mockSesionChecker {
	return &mockSesionChecker{conteoPorEspacio: make(map[string]int64)}
}

func (m *mockSesionChecker) CountSesionesFuturasPorEspacio(ctx context.Context, espacioID string, desde time.Time) (int64, error) {
	return m.conteoPorEspacio[espacioID], nil
}

// Auditoria Mock
type mockGeoAuditoriaRepo struct {
	entries []*repository.AuditEntry
}

func (m *mockGeoAuditoriaRepo) Create(ctx context.Context, e *repository.AuditEntry) error {
	m.entries = append(m.entries, e)
	return nil
}

// ─────────────────────────────────────────────────────────────
// TESTS DE CRITERIOS DE ACEPTACIÓN
// ─────────────────────────────────────────────────────────────

func setupGeoService() (*usecaseGeo.Service, *mockSedeRepo, *mockBloqueRepo, *mockEspacioRepo, *mockSesionChecker, *mockGeoAuditoriaRepo) {
	sedeRepo := newMockSedeRepo()
	bloqueRepo := newMockBloqueRepo()
	espacioRepo := newMockEspacioRepo()
	sesionChecker := newMockSesionChecker()
	auditoriaRepo := &mockGeoAuditoriaRepo{}
	clk := shared.NewFakeClock(time.Date(2026, 9, 21, 10, 0, 0, 0, time.UTC))
	log := applog.New(applog.LevelDebug, nil)

	svc := usecaseGeo.NewService(
		sedeRepo,
		bloqueRepo,
		espacioRepo,
		sesionChecker,
		auditoriaRepo,
		clk,
		log,
	)
	return svc, sedeRepo, bloqueRepo, espacioRepo, sesionChecker, auditoriaRepo
}

// ─── AC-01: Jerarquía Persistida y Navegable ──────────────────

func TestGeo_AC01_JerarquiaPersistidaYNavegable(t *testing.T) {
	svc, _, _, _, _, _ := setupGeoService()
	ctx := context.Background()

	// 1. Crear Sede
	sede, err := svc.CrearSede(ctx, usecaseGeo.CrearSedeCmd{
		Codigo:    "SEDE-CENTRAL",
		Nombre:    "Campus Central",
		Direccion: "Carrera 1 # 10-20",
	})
	if err != nil {
		t.Fatalf("falla al crear sede: %v", err)
	}

	// 2. Crear Bloque en la Sede
	bloque, err := svc.CrearBloque(ctx, usecaseGeo.CrearBloqueCmd{
		SedeID: sede.ID,
		Codigo: "B-ING",
		Nombre: "Bloque de Ingeniería",
		Pisos:  []int{1, 2, 3},
	})
	if err != nil {
		t.Fatalf("falla al crear bloque: %v", err)
	}

	// 3. Crear Aula asociada a Sede y Bloque
	piso := 2
	torre := "Torre Norte"
	aula, err := svc.CrearEspacio(ctx, usecaseGeo.CrearEspacioCmd{
		SedeID:              sede.ID,
		BloqueID:            &bloque.ID,
		Torre:               &torre,
		Piso:                &piso,
		Codigo:              "A-201",
		Nombre:              "Aula de Algoritmos 201",
		Capacidad:           35,
		Tipo:                geo.TipoAula,
		FacultadResponsable: "Ingeniería",
	})
	if err != nil {
		t.Fatalf("falla al crear espacio: %v", err)
	}

	// 4. Navegar la jerarquía: listar espacios de la sede y bloque
	espacios, err := svc.ListarEspacios(ctx, repository.EspacioFilter{
		SedeID:   sede.ID,
		BloqueID: bloque.ID,
		Piso:     &piso,
	})
	if err != nil {
		t.Fatalf("falla al navegar jerarquia: %v", err)
	}
	if len(espacios) != 1 || espacios[0].ID != aula.ID {
		t.Fatalf("se esperaba 1 espacio en la jerarquía, se obtuvo %d", len(espacios))
	}
}

// ─── AC-02: Sede y espacio obligatorios; torre, bloque y piso opcionales ──────

func TestGeo_AC02_SedeEspacioObligatorios_TorreBloquePisoOpcionales(t *testing.T) {
	svc, _, _, _, _, _ := setupGeoService()
	ctx := context.Background()

	sede, err := svc.CrearSede(ctx, usecaseGeo.CrearSedeCmd{
		Codigo: "SEDE-NORTE",
		Nombre: "Sede Norte",
	})
	if err != nil {
		t.Fatalf("crear sede: %v", err)
	}

	// Caso Válido: Espacio sin torre, sin bloque y sin piso (solo sede + aula)
	espacioSoloSede, err := svc.CrearEspacio(ctx, usecaseGeo.CrearEspacioCmd{
		SedeID:    sede.ID,
		Codigo:    "AUD-GRANDE",
		Nombre:    "Auditorio al aire libre",
		Capacidad: 200,
		Tipo:      geo.TipoAuditorio,
	})
	if err != nil {
		t.Fatalf("espacio solo con sede debe ser válido (AC-02): %v", err)
	}
	if espacioSoloSede.BloqueID != nil || espacioSoloSede.Piso != nil || espacioSoloSede.Torre != nil {
		t.Fatalf("los campos opcionales no deben estar poblados")
	}

	// Caso Inválido: Sin SedeID
	_, err = svc.CrearEspacio(ctx, usecaseGeo.CrearEspacioCmd{
		SedeID: "",
		Codigo: "A-ERROR",
		Nombre: "Aula sin sede",
		Tipo:   geo.TipoAula,
	})
	if err == nil {
		t.Fatal("debe fallar si falta sedeId (AC-02)")
	}

	// Caso Inválido: Sede no existe
	_, err = svc.CrearEspacio(ctx, usecaseGeo.CrearEspacioCmd{
		SedeID: "sede-fantasma",
		Codigo: "A-ERROR-2",
		Nombre: "Aula con sede inexistente",
		Tipo:   geo.TipoAula,
	})
	if err == nil {
		t.Fatal("debe fallar si la sede no existe")
	}

	// Caso Inválido: Bloque de otra sede
	otraSede, _ := svc.CrearSede(ctx, usecaseGeo.CrearSedeCmd{Codigo: "SEDE-SUR", Nombre: "Sede Sur"})
	bloqueDeOtraSede, _ := svc.CrearBloque(ctx, usecaseGeo.CrearBloqueCmd{SedeID: otraSede.ID, Codigo: "B-SUR", Nombre: "Bloque Sur"})

	_, err = svc.CrearEspacio(ctx, usecaseGeo.CrearEspacioCmd{
		SedeID:   sede.ID,
		BloqueID: &bloqueDeOtraSede.ID,
		Codigo:   "A-CRUZADO",
		Nombre:   "Aula cruzada",
		Tipo:     geo.TipoAula,
	})
	if err == nil {
		t.Fatal("debe rechazar bloque que no pertenezca a la sede indicada")
	}
}

// ─── AC-03: Unicidad de Código de Espacio ───────────────────────

func TestGeo_AC03_UnicidadCodigoEspacio_RechazaConConflicto(t *testing.T) {
	svc, _, _, _, _, _ := setupGeoService()
	ctx := context.Background()

	sede, _ := svc.CrearSede(ctx, usecaseGeo.CrearSedeCmd{Codigo: "SEDE-1", Nombre: "Sede 1"})

	_, err := svc.CrearEspacio(ctx, usecaseGeo.CrearEspacioCmd{
		SedeID: sede.ID,
		Codigo: "LAB-QUIM-101",
		Nombre: "Laboratorio de Química 1",
		Tipo:   geo.TipoLaboratorio,
	})
	if err != nil {
		t.Fatalf("primer registro: %v", err)
	}

	// Segundo registro con el mismo código
	_, err = svc.CrearEspacio(ctx, usecaseGeo.CrearEspacioCmd{
		SedeID: sede.ID,
		Codigo: "LAB-QUIM-101",
		Nombre: "Otro laboratorio con mismo código",
		Tipo:   geo.TipoLaboratorio,
	})
	if err == nil {
		t.Fatal("se esperaba error de unicidad por código duplicado (AC-03)")
	}

	de, ok := shared.AsDomainError(err)
	if !ok || de.Code != shared.ErrConflictoUnicidad {
		t.Fatalf("se esperaba ErrConflictoUnicidad (409), se obtuvo: %v", err)
	}
}

// ─── AC-04: Metadatos Completos y Tipos Válidos ─────────────────

func TestGeo_AC04_MetadatosCompletos_TiposYEstados(t *testing.T) {
	svc, _, _, _, _, _ := setupGeoService()
	ctx := context.Background()

	sede, _ := svc.CrearSede(ctx, usecaseGeo.CrearSedeCmd{Codigo: "SEDE-TEST", Nombre: "Sede Test"})

	tiposValidos := []geo.TipoEspacio{
		geo.TipoAula,
		geo.TipoLaboratorio,
		geo.TipoAuditorio,
		geo.TipoTaller,
	}

	for i, tipo := range tiposValidos {
		codigo := string(tipo) + "-01"
		esp, err := svc.CrearEspacio(ctx, usecaseGeo.CrearEspacioCmd{
			SedeID:              sede.ID,
			Codigo:              codigo,
			Nombre:              "Espacio " + codigo,
			Capacidad:           20 + i*10,
			Tipo:                tipo,
			FacultadResponsable: "Ciencias Básicas",
			Estado:              geo.EstadoActivo,
			NivelValidacion:     geo.NivelAula,
			BufferMetros:        12.5,
		})
		if err != nil {
			t.Fatalf("tipo %s debe ser válido: %v", tipo, err)
		}
		if esp.Tipo != tipo || esp.Capacidad != 20+i*10 || esp.BufferMetros != 12.5 {
			t.Fatalf("los metadatos no coinciden para %s", tipo)
		}
	}

	// Tipo inválido
	_, err := svc.CrearEspacio(ctx, usecaseGeo.CrearEspacioCmd{
		SedeID:    sede.ID,
		Codigo:    "INV-01",
		Nombre:    "Tipo invalido",
		Capacidad: 10,
		Tipo:      geo.TipoEspacio("OFICINA_ADMINISTRATIVA"),
	})
	if err == nil {
		t.Fatal("se esperaba rechazo ante tipo no permitido por SRS")
	}
}

// ─── AC-05: Advertencia de Impacto ante Sesiones Futuras ────────

func TestGeo_AC05_InactivarEspacio_ConSesionesFuturas_ExigeConfirmacion(t *testing.T) {
	svc, _, _, _, sesionChecker, aud := setupGeoService()
	ctx := context.Background()

	sede, _ := svc.CrearSede(ctx, usecaseGeo.CrearSedeCmd{Codigo: "SEDE-SES", Nombre: "Sede Sesiones"})
	esp, err := svc.CrearEspacio(ctx, usecaseGeo.CrearEspacioCmd{
		SedeID: sede.ID,
		Codigo: "A-501",
		Nombre: "Aula con Sesiones",
		Tipo:   geo.TipoAula,
	})
	if err != nil {
		t.Fatalf("crear espacio: %v", err)
	}

	// Simular que el espacio tiene 4 sesiones futuras programadas
	sesionChecker.conteoPorEspacio[esp.ID] = 4

	// Intento 1: Inactivar SIN confirmar impacto
	inactivo := geo.EstadoInactivo
	_, err = svc.ActualizarEspacio(ctx, esp.ID, usecaseGeo.ActualizarEspacioCmd{
		Estado:           &inactivo,
		ConfirmarImpacto: false,
	})
	if err == nil {
		t.Fatal("se esperaba advertencia/error de impacto al inactivar aula con sesiones futuras (AC-05)")
	}

	de, ok := shared.AsDomainError(err)
	if !ok || de.Code != shared.ErrValidacion {
		t.Fatalf("se esperaba ErrValidacion con detalle de impacto, se obtuvo: %v", err)
	}
	if !strings.Contains(de.Message, "4 sesiones futuras") {
		t.Fatalf("mensaje debe advertir el conteo exacto de 4 sesiones afectadas: %s", de.Message)
	}

	// Intento 2: Inactivar CON confirmación explícita
	actualizado, err := svc.ActualizarEspacio(ctx, esp.ID, usecaseGeo.ActualizarEspacioCmd{
		Estado:           &inactivo,
		ConfirmarImpacto: true,
	})
	if err != nil {
		t.Fatalf("al confirmar impacto debe permitir inactivar: %v", err)
	}
	if actualizado.Estado != geo.EstadoInactivo || actualizado.Activo != false {
		t.Fatalf("estado no actualizado correctamente")
	}

	// Verificar auditoría de la actualización
	encontrado := false
	for _, entry := range aud.entries {
		if entry.EntidadID == esp.ID && entry.Accion == "ESPACIO_ACTUALIZADO" {
			encontrado = true
			break
		}
	}
	if !encontrado {
		t.Fatal("la inactivación debe quedar auditada (RF-AUD-005)")
	}
}

// ─── AC-06: Borrado Lógico con Trazabilidad ────────────────────

func TestGeo_AC06_BorradoLogico_ConservaHistoriaYAuditoria(t *testing.T) {
	svc, _, _, espacioRepo, _, aud := setupGeoService()
	ctx := context.Background()

	sede, _ := svc.CrearSede(ctx, usecaseGeo.CrearSedeCmd{Codigo: "SEDE-DEL", Nombre: "Sede Delete"})
	esp, _ := svc.CrearEspacio(ctx, usecaseGeo.CrearEspacioCmd{
		SedeID: sede.ID,
		Codigo: "A-DEL-01",
		Nombre: "Aula a eliminar",
		Tipo:   geo.TipoAula,
	})

	actor := usecaseGeo.ContextoActor{
		ActorID:       "admin-123",
		RolActivo:     "ADMIN_INSTITUCIONAL",
		CorrelationID: "corr-delete-test",
	}

	// Ejecutar borrado lógico
	err := svc.EliminarEspacio(ctx, esp.ID, actor)
	if err != nil {
		t.Fatalf("error en borrado logico: %v", err)
	}

	// A nivel de consulta normal, no debe encontrarse
	consultado, err := svc.ObtenerEspacioPorID(ctx, esp.ID)
	if err == nil || consultado != nil {
		t.Fatal("el espacio eliminado no debe ser retornado en consultas activas")
	}

	// A nivel de almacenamiento físico, el documento existe con Eliminado: true (AC-06 / RF-AUD-005)
	rawDoc := espacioRepo.espacios[esp.ID]
	if rawDoc == nil {
		t.Fatal("el registro no debe destruirse físicamente de la base de datos")
	}
	if !rawDoc.Eliminado || rawDoc.Activo {
		t.Fatalf("debe quedar marcado como Eliminado=true y Activo=false")
	}

	// Verificar evento en bitácora de auditoría
	var deleteAudit *repository.AuditEntry
	for _, entry := range aud.entries {
		if entry.EntidadID == esp.ID && entry.Accion == "ESPACIO_ELIMINADO" {
			deleteAudit = entry
			break
		}
	}
	if deleteAudit == nil {
		t.Fatal("el borrado lógico debe generar una entrada de auditoría (AC-06)")
	}
	if deleteAudit.ActorID != "admin-123" {
		t.Fatalf("el actor auditado debe ser admin-123")
	}
}

// ─── HTTP Endpoints y Verificación de Rutas al Arranque ─────────

func TestGeo_HTTP_Endpoints_Y_VerificacionRutas(t *testing.T) {
	svc, _, _, _, _, _ := setupGeoService()
	geoH := handler.NewGeoHandler(svc)

	e := echo.New()
	e.Validator = apphttp.NewValidator()
	e.HTTPErrorHandler = middleware.ErrorHandler(applog.New(applog.LevelDebug, nil))
	registry := apphttp.NewRouteRegistry()

	api := e.Group("/api/v1")
	// Registrar sedes
	api.GET("/sedes", geoH.ListarSedes)
	registry.RegisterPermission(http.MethodGet, "/api/v1/sedes", "aula:leer")
	api.POST("/sedes", geoH.CrearSede)
	registry.RegisterPermission(http.MethodPost, "/api/v1/sedes", "sede:administrar")
	api.GET("/sedes/:id", geoH.ObtenerSede)
	registry.RegisterPermission(http.MethodGet, "/api/v1/sedes/:id", "aula:leer")

	// Registrar bloques
	api.GET("/bloques", geoH.ListarBloques)
	registry.RegisterPermission(http.MethodGet, "/api/v1/bloques", "aula:leer")
	api.POST("/bloques", geoH.CrearBloque)
	registry.RegisterPermission(http.MethodPost, "/api/v1/bloques", "bloque:administrar")
	api.GET("/bloques/:id", geoH.ObtenerBloque)
	registry.RegisterPermission(http.MethodGet, "/api/v1/bloques/:id", "aula:leer")

	// Registrar espacios
	api.GET("/espacios", geoH.ListarEspacios)
	registry.RegisterPermission(http.MethodGet, "/api/v1/espacios", "aula:leer")
	api.GET("/espacios/solapamientos", geoH.InformeSolapamientos)
	registry.RegisterPermission(http.MethodGet, "/api/v1/espacios/solapamientos", "aula:leer")
	api.POST("/espacios", geoH.CrearEspacio)
	registry.RegisterPermission(http.MethodPost, "/api/v1/espacios", "aula:crear")
	api.GET("/espacios/:id", geoH.ObtenerEspacio)
	registry.RegisterPermission(http.MethodGet, "/api/v1/espacios/:id", "aula:leer")
	api.PATCH("/espacios/:id", geoH.ActualizarEspacio)
	registry.RegisterPermission(http.MethodPatch, "/api/v1/espacios/:id", "aula:editar")
	api.PUT("/espacios/:id/geometria", geoH.ActualizarGeometria)
	registry.RegisterPermission(http.MethodPut, "/api/v1/espacios/:id/geometria", "aula:editar-geometria")
	api.DELETE("/espacios/:id", geoH.EliminarEspacio)
	registry.RegisterPermission(http.MethodDelete, "/api/v1/espacios/:id", "aula:eliminar")

	// Verificación al arranque (T-ROL-01.4)
	if err := registry.VerifyAllRoutes(e); err != nil {
		t.Fatalf("fallo al verificar rutas de cartografía en registry: %v", err)
	}

	// Prueba HTTP POST /sedes -> 201
	sedeBody := `{"codigo":"SEDE-HTTP","nombre":"Sede de Pruebas HTTP"}`
	req := httptest.NewRequest(http.MethodPost, "/api/v1/sedes", strings.NewReader(sedeBody))
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusCreated {
		t.Fatalf("POST /sedes retorno status %d, esperado 201. Body: %s", rec.Code, rec.Body.String())
	}

	var sedeResp dto.SedeResponse
	if err := json.Unmarshal(rec.Body.Bytes(), &sedeResp); err != nil {
		t.Fatalf("error al deserializar respuesta de sede: %v", err)
	}
	if sedeResp.Codigo != "SEDE-HTTP" {
		t.Fatalf("codigo inesperado: %s", sedeResp.Codigo)
	}

	// Prueba HTTP POST /espacios -> 201
	espacioBody := `{"sedeId":"` + sedeResp.ID + `","codigo":"A-HTTP-101","nombre":"Aula HTTP","tipo":"AULA","capacidad":30}`
	reqEsp := httptest.NewRequest(http.MethodPost, "/api/v1/espacios", strings.NewReader(espacioBody))
	reqEsp.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	recEsp := httptest.NewRecorder()
	e.ServeHTTP(recEsp, reqEsp)

	if recEsp.Code != http.StatusCreated {
		t.Fatalf("POST /espacios retorno status %d, esperado 201. Body: %s", recEsp.Code, recEsp.Body.String())
	}

	var espResp dto.EspacioResponse
	if err := json.Unmarshal(recEsp.Body.Bytes(), &espResp); err != nil {
		t.Fatalf("error al deserializar espacio: %v", err)
	}

	// Prueba HTTP GET /espacios -> 200
	reqListEsp := httptest.NewRequest(http.MethodGet, "/api/v1/espacios?sedeId="+sedeResp.ID, nil)
	recListEsp := httptest.NewRecorder()
	e.ServeHTTP(recListEsp, reqListEsp)
	if recListEsp.Code != http.StatusOK {
		t.Fatalf("GET /espacios retorno status %d, esperado 200", recListEsp.Code)
	}

	// Prueba HTTP GET /espacios/:id -> 200
	reqGetEsp := httptest.NewRequest(http.MethodGet, "/api/v1/espacios/"+espResp.ID, nil)
	recGetEsp := httptest.NewRecorder()
	e.ServeHTTP(recGetEsp, reqGetEsp)
	if recGetEsp.Code != http.StatusOK {
		t.Fatalf("GET /espacios/:id retorno status %d, esperado 200", recGetEsp.Code)
	}

	// Prueba HTTP PATCH /espacios/:id -> 200
	patchBody := `{"nombre":"Aula HTTP Actualizada","capacidad":45}`
	reqPatch := httptest.NewRequest(http.MethodPatch, "/api/v1/espacios/"+espResp.ID, strings.NewReader(patchBody))
	reqPatch.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	recPatch := httptest.NewRecorder()
	e.ServeHTTP(recPatch, reqPatch)
	if recPatch.Code != http.StatusOK {
		t.Fatalf("PATCH /espacios/:id retorno status %d, esperado 200", recPatch.Code)
	}

	// Prueba HTTP PUT /espacios/:id/geometria -> 200 (US-GEO-02 AC-06, AC-07, T-GEO-02.7)
	geomBody := `{"metodoCaptura":"RECORRIDO_PERIMETRAL","coordenadas":[[-74.08175,4.60971],[-74.08165,4.60971],[-74.08165,4.60981],[-74.08175,4.60981]],"precisionPromedioMetros":3.5}`
	reqGeom := httptest.NewRequest(http.MethodPut, "/api/v1/espacios/"+espResp.ID+"/geometria", strings.NewReader(geomBody))
	reqGeom.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	recGeom := httptest.NewRecorder()
	e.ServeHTTP(recGeom, reqGeom)
	if recGeom.Code != http.StatusOK {
		t.Fatalf("PUT /espacios/:id/geometria retorno status %d, esperado 200. Body: %s", recGeom.Code, recGeom.Body.String())
	}
	var espGeomResp dto.EspacioResponse
	if err := json.Unmarshal(recGeom.Body.Bytes(), &espGeomResp); err != nil {
		t.Fatalf("error deserializar espacio con geometria: %v", err)
	}
	if espGeomResp.Geometria == nil {
		t.Fatal("se esperaba campo geometria en la respuesta")
	}
	if espGeomResp.AreaMetrosCuadrados <= 0 {
		t.Errorf("area esperada > 0, obtenido %f", espGeomResp.AreaMetrosCuadrados)
	}
	if espGeomResp.Centroide == nil {
		t.Fatal("se esperaba centroide calculado en la respuesta")
	}
	if espGeomResp.VersionGeometria != 1 {
		t.Errorf("versionGeometria esperada 1, obtenido %d", espGeomResp.VersionGeometria)
	}

	// Prueba HTTP PUT /espacios/:id/geometria con polígono inválido (< 3 vértices) -> 422
	geomInvalido := `{"metodoCaptura":"RECORRIDO_PERIMETRAL","coordenadas":[[-74.08175,4.60971],[-74.08165,4.60971]]}`
	reqInvalido := httptest.NewRequest(http.MethodPut, "/api/v1/espacios/"+espResp.ID+"/geometria", strings.NewReader(geomInvalido))
	reqInvalido.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	recInvalido := httptest.NewRecorder()
	e.ServeHTTP(recInvalido, reqInvalido)
	if recInvalido.Code != http.StatusUnprocessableEntity {
		t.Fatalf("esperado status 422 para polígono con vértices insuficientes, obtenido %d", recInvalido.Code)
	}

	// Prueba HTTP PUT /espacios/:id/geometria con TOQUE_MAPA (US-GEO-03 AC-02)
	geomToqueBody := `{"metodoCaptura":"TOQUE_MAPA","coordenadas":[[-74.08175,4.60971],[-74.08165,4.60971],[-74.08165,4.60981],[-74.08175,4.60981]],"precisionPromedioMetros":5.0}`
	reqToque := httptest.NewRequest(http.MethodPut, "/api/v1/espacios/"+espResp.ID+"/geometria", strings.NewReader(geomToqueBody))
	reqToque.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	recToque := httptest.NewRecorder()
	e.ServeHTTP(recToque, reqToque)
	if recToque.Code != http.StatusOK {
		t.Fatalf("PUT /espacios/:id/geometria (TOQUE_MAPA) retorno %d, esperado 200", recToque.Code)
	}
	var espToqueResp dto.EspacioResponse
	if err := json.Unmarshal(recToque.Body.Bytes(), &espToqueResp); err != nil {
		t.Fatalf("error deserializar espacio toque: %v", err)
	}
	if espToqueResp.MetodoCaptura == nil || *espToqueResp.MetodoCaptura != "TOQUE_MAPA" {
		t.Fatalf("metodoCaptura esperado TOQUE_MAPA, obtenido %v", espToqueResp.MetodoCaptura)
	}
	if espToqueResp.PrecisionPromedioMetros != nil {
		t.Fatalf("AC-02: TOQUE_MAPA no debe registrar precisionPromedioMetros, obtenido %v", *espToqueResp.PrecisionPromedioMetros)
	}
	if espToqueResp.VersionGeometria != 2 {
		t.Fatalf("versionGeometria esperada 2 tras segunda actualizacion, obtenido %d", espToqueResp.VersionGeometria)
	}

	// Prueba HTTP PUT /espacios/:id/geometria con MIXTO (US-GEO-03 AC-03)
	geomMixtoBody := `{"metodoCaptura":"MIXTO","coordenadas":[[-74.08175,4.60971],[-74.08165,4.60971],[-74.08165,4.60981],[-74.08175,4.60981]],"precisionPromedioMetros":4.2}`
	reqMixto := httptest.NewRequest(http.MethodPut, "/api/v1/espacios/"+espResp.ID+"/geometria", strings.NewReader(geomMixtoBody))
	reqMixto.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	recMixto := httptest.NewRecorder()
	e.ServeHTTP(recMixto, reqMixto)
	if recMixto.Code != http.StatusOK {
		t.Fatalf("PUT /espacios/:id/geometria (MIXTO) retorno %d, esperado 200", recMixto.Code)
	}
	var espMixtoResp dto.EspacioResponse
	if err := json.Unmarshal(recMixto.Body.Bytes(), &espMixtoResp); err != nil {
		t.Fatalf("error deserializar espacio mixto: %v", err)
	}
	if espMixtoResp.MetodoCaptura == nil || *espMixtoResp.MetodoCaptura != "MIXTO" {
		t.Fatalf("metodoCaptura esperado MIXTO, obtenido %v", espMixtoResp.MetodoCaptura)
	}
	if espMixtoResp.PrecisionPromedioMetros == nil || *espMixtoResp.PrecisionPromedioMetros != 4.2 {
		t.Fatalf("AC-03: MIXTO debe conservar precisionPromedioMetros, obtenido %v", espMixtoResp.PrecisionPromedioMetros)
	}
	if espMixtoResp.VersionGeometria != 3 {
		t.Fatalf("versionGeometria esperada 3 tras tercera actualizacion, obtenido %d", espMixtoResp.VersionGeometria)
	}

	// Prueba HTTP DELETE /espacios/:id -> 204
	reqDel := httptest.NewRequest(http.MethodDelete, "/api/v1/espacios/"+espResp.ID, nil)
	recDel := httptest.NewRecorder()
	e.ServeHTTP(recDel, reqDel)
	if recDel.Code != http.StatusNoContent {
		t.Fatalf("DELETE /espacios/:id retorno status %d, esperado 204", recDel.Code)
	}

	// Prueba HTTP GET /sedes -> 200
	reqListSedes := httptest.NewRequest(http.MethodGet, "/api/v1/sedes", nil)
	recListSedes := httptest.NewRecorder()
	e.ServeHTTP(recListSedes, reqListSedes)
	if recListSedes.Code != http.StatusOK {
		t.Fatalf("GET /sedes retorno status %d, esperado 200", recListSedes.Code)
	}

	// Prueba HTTP GET /sedes/:id -> 200
	reqGetSede := httptest.NewRequest(http.MethodGet, "/api/v1/sedes/"+sedeResp.ID, nil)
	recGetSede := httptest.NewRecorder()
	e.ServeHTTP(recGetSede, reqGetSede)
	if recGetSede.Code != http.StatusOK {
		t.Fatalf("GET /sedes/:id retorno status %d, esperado 200", recGetSede.Code)
	}

	// Prueba HTTP POST /bloques -> 201
	bloqueBody := `{"sedeId":"` + sedeResp.ID + `","codigo":"B-HTTP","nombre":"Bloque HTTP","pisos":[1,2]}`
	reqBloque := httptest.NewRequest(http.MethodPost, "/api/v1/bloques", strings.NewReader(bloqueBody))
	reqBloque.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	recBloque := httptest.NewRecorder()
	e.ServeHTTP(recBloque, reqBloque)
	if recBloque.Code != http.StatusCreated {
		t.Fatalf("POST /bloques retorno status %d, esperado 201", recBloque.Code)
	}

	var bloqueResp dto.BloqueResponse
	if err := json.Unmarshal(recBloque.Body.Bytes(), &bloqueResp); err != nil {
		t.Fatalf("error deserializar bloque: %v", err)
	}

	// Prueba HTTP GET /bloques -> 200
	reqListBloques := httptest.NewRequest(http.MethodGet, "/api/v1/bloques?sedeId="+sedeResp.ID, nil)
	recListBloques := httptest.NewRecorder()
	e.ServeHTTP(recListBloques, reqListBloques)
	if recListBloques.Code != http.StatusOK {
		t.Fatalf("GET /bloques retorno status %d, esperado 200", recListBloques.Code)
	}

	// Prueba HTTP GET /bloques/:id -> 200
	reqGetBloque := httptest.NewRequest(http.MethodGet, "/api/v1/bloques/"+bloqueResp.ID, nil)
	recGetBloque := httptest.NewRecorder()
	e.ServeHTTP(recGetBloque, reqGetBloque)
	if recGetBloque.Code != http.StatusOK {
		t.Fatalf("GET /bloques/:id retorno status %d, esperado 200", recGetBloque.Code)
	}
}
