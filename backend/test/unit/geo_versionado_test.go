package unit_test

import (
	"context"
	"testing"
	"time"

	"github.com/siaa/backend/internal/domain/geo"
	"github.com/siaa/backend/internal/domain/shared"
	applog "github.com/siaa/backend/internal/platform/log"
	usecaseGeo "github.com/siaa/backend/internal/usecase/geo"
)

// mockEspacioGeometriaHistRepo implementa EspacioGeometriaHistRepository en memoria para pruebas unitarias.
type mockEspacioGeometriaHistRepo struct {
	historial map[string][]*geo.EspacioGeometriaHist // espacioId -> lista de versiones
}

func newMockEspacioGeometriaHistRepo() *mockEspacioGeometriaHistRepo {
	return &mockEspacioGeometriaHistRepo{
		historial: make(map[string][]*geo.EspacioGeometriaHist),
	}
}

func (m *mockEspacioGeometriaHistRepo) Create(ctx context.Context, h *geo.EspacioGeometriaHist) error {
	m.historial[h.EspacioID] = append(m.historial[h.EspacioID], h)
	return nil
}

func (m *mockEspacioGeometriaHistRepo) ListByEspacioID(ctx context.Context, espacioID string) ([]*geo.EspacioGeometriaHist, error) {
	versiones, ok := m.historial[espacioID]
	if !ok {
		return []*geo.EspacioGeometriaHist{}, nil
	}
	// Devolver en orden descendente de versión
	result := make([]*geo.EspacioGeometriaHist, len(versiones))
	for i, v := range versiones {
		result[len(versiones)-1-i] = v
	}
	return result, nil
}

func (m *mockEspacioGeometriaHistRepo) FindByEspacioIDAndVersion(ctx context.Context, espacioID string, version int) (*geo.EspacioGeometriaHist, error) {
	versiones, ok := m.historial[espacioID]
	if !ok {
		return nil, nil
	}
	for _, v := range versiones {
		if v.Version == version {
			return v, nil
		}
	}
	return nil, nil
}

func setupGeoVersionadoTest() (*usecaseGeo.Service, *mockEspacioGeometriaHistRepo, *mockEspacioRepo, string) {
	sedeRepo := newMockSedeRepo()
	bloqueRepo := newMockBloqueRepo()
	espacioRepo := newMockEspacioRepo()
	histRepo := newMockEspacioGeometriaHistRepo()
	sesionChecker := newMockSesionChecker()
	auditRepo := &mockGeoAuditoriaRepo{}
	clk := shared.NewFakeClock(time.Date(2026, 9, 22, 10, 0, 0, 0, time.UTC))
	logger := applog.New(applog.LevelDebug, nil)

	svc := usecaseGeo.NewService(sedeRepo, bloqueRepo, espacioRepo, histRepo, sesionChecker, auditRepo, clk, logger)
	ctx := context.Background()

	actor := usecaseGeo.ContextoActor{
		ActorID:       "admin-geo-01",
		RolActivo:     "ADMIN_INSTITUCIONAL",
		CorrelationID: "corr-geo-ver-001",
	}

	sede, _ := svc.CrearSede(ctx, usecaseGeo.CrearSedeCmd{
		Codigo: "SEDE-NORTE",
		Nombre: "Sede Norte",
		Actor:  actor,
	})

	bloque, _ := svc.CrearBloque(ctx, usecaseGeo.CrearBloqueCmd{
		SedeID: sede.ID,
		Codigo: "BLOQUE-A",
		Nombre: "Bloque Aulas",
		Actor:  actor,
	})

	espacio, _ := svc.CrearEspacio(ctx, usecaseGeo.CrearEspacioCmd{
		SedeID:    sede.ID,
		BloqueID:  &bloque.ID,
		Codigo:    "AULA-101",
		Nombre:    "Aula 101 Teórica",
		Tipo:      geo.TipoAula,
		Capacidad: 35,
		Actor:     actor,
	})

	return svc, histRepo, espacioRepo, espacio.ID
}

// ─────────────────────────────────────────────────────────────
// US-GEO-06: PRUEBAS DE VERSIONADO DE GEOMETRÍA
// ─────────────────────────────────────────────────────────────

func TestUSGEO06_ArchivadoYContadorDeVersiones(t *testing.T) {
	svc, histRepo, _, espacioID := setupGeoVersionadoTest()
	ctx := context.Background()

	actor := usecaseGeo.ContextoActor{
		ActorID:   "admin-geo-01",
		RolActivo: "ADMIN_INSTITUCIONAL",
	}

	// 1. Guardar primera versión de geometría (v1)
	polyV1 := []geo.GeoPoint{
		mustPt(-74.081750, 4.638190),
		mustPt(-74.081650, 4.638190),
		mustPt(-74.081650, 4.638250),
		mustPt(-74.081750, 4.638250),
		mustPt(-74.081750, 4.638190),
	}
	metodoV1 := geo.MetodoRecorridoPerimetral
	precV1 := 2.5

	espacioV1, err := svc.GuardarGeometriaEspacio(ctx, usecaseGeo.GuardarGeometriaCmd{
		EspacioID:               espacioID,
		Vertices:                polyV1,
		MetodoCaptura:           metodoV1,
		PrecisionPromedioMetros: &precV1,
		Actor:                   actor,
	})
	if err != nil {
		t.Fatalf("error inesperado guardando v1: %v", err)
	}

	if espacioV1.VersionGeometria != 1 {
		t.Errorf("se esperaba VersionGeometria == 1, obtenido: %d", espacioV1.VersionGeometria)
	}

	// Como es la versión inicial, aún no debe haber registros en el histórico archivado
	histV1, err := histRepo.ListByEspacioID(ctx, espacioID)
	if err != nil {
		t.Fatalf("error consultando histórico: %v", err)
	}
	if len(histV1) != 0 {
		t.Errorf("se esperaban 0 versiones previas archivadas tras primera creación, obtenido: %d", len(histV1))
	}

	// 2. Modificar geometría para producir la versión 2 (v2)
	// US-GEO-06 AC-01: la versión v1 debe quedar archivada con fecha, autor y version == 1.
	polyV2 := []geo.GeoPoint{
		mustPt(-74.081760, 4.638180),
		mustPt(-74.081640, 4.638180),
		mustPt(-74.081640, 4.638260),
		mustPt(-74.081760, 4.638260),
		mustPt(-74.081760, 4.638180),
	}
	metodoV2 := geo.MetodoToqueMapa

	espacioV2, err := svc.GuardarGeometriaEspacio(ctx, usecaseGeo.GuardarGeometriaCmd{
		EspacioID:          espacioID,
		Vertices:           polyV2,
		MetodoCaptura:      metodoV2,
		MotivoSolapamiento: "Ajuste perimetral en campo",
		Actor:              actor,
	})
	if err != nil {
		t.Fatalf("error inesperado guardando v2: %v", err)
	}

	if espacioV2.VersionGeometria != 2 {
		t.Errorf("se esperaba VersionGeometria == 2, obtenido: %d", espacioV2.VersionGeometria)
	}

	// Verificar que v1 esté en el histórico inmutable (AC-01)
	histV2, err := svc.ListarVersionesGeometria(ctx, espacioID)
	if err != nil {
		t.Fatalf("error listando versiones: %v", err)
	}
	if len(histV2) != 1 {
		t.Fatalf("se esperaba 1 versión archivada en histórico, obtenido: %d", len(histV2))
	}

	archivada := histV2[0]
	if archivada.Version != 1 {
		t.Errorf("se esperaba versión archivada 1, obtenido: %d", archivada.Version)
	}
	if archivada.CreadoPor != actor.ActorID {
		t.Errorf("se esperaba CreadoPor == %s, obtenido: %s", actor.ActorID, archivada.CreadoPor)
	}
	if archivada.AreaMetrosCuadrados <= 0 {
		t.Errorf("el área histórica archivada debe ser positiva, obtenido: %f", archivada.AreaMetrosCuadrados)
	}

	// 3. Modificar geometría para producir la versión 3 (v3)
	polyV3 := []geo.GeoPoint{
		mustPt(-74.081770, 4.638170),
		mustPt(-74.081630, 4.638170),
		mustPt(-74.081630, 4.638270),
		mustPt(-74.081770, 4.638270),
		mustPt(-74.081770, 4.638170),
	}
	espacioV3, err := svc.GuardarGeometriaEspacio(ctx, usecaseGeo.GuardarGeometriaCmd{
		EspacioID:     espacioID,
		Vertices:      polyV3,
		MetodoCaptura: geo.MetodoMixto,
		Actor:         actor,
	})
	if err != nil {
		t.Fatalf("error inesperado guardando v3: %v", err)
	}
	if espacioV3.VersionGeometria != 3 {
		t.Errorf("se esperaba VersionGeometria == 3, obtenido: %d", espacioV3.VersionGeometria)
	}

	// Debe haber 2 versiones en el histórico (v2 y v1)
	histV3, err := svc.ListarVersionesGeometria(ctx, espacioID)
	if err != nil {
		t.Fatalf("error listando versiones v3: %v", err)
	}
	if len(histV3) != 2 {
		t.Fatalf("se esperaban 2 versiones en histórico (v2 y v1), obtenido: %d", len(histV3))
	}
	if histV3[0].Version != 2 || histV3[1].Version != 1 {
		t.Errorf("orden esperado [2, 1], obtenido [%d, %d]", histV3[0].Version, histV3[1].Version)
	}
}

func TestUSGEO06_RecuperacionHistoricaPorVersion(t *testing.T) {
	svc, _, _, espacioID := setupGeoVersionadoTest()
	ctx := context.Background()

	actor := usecaseGeo.ContextoActor{
		ActorID:   "admin-geo-01",
		RolActivo: "ADMIN_INSTITUCIONAL",
	}

	// Guardar v1
	polyV1 := []geo.GeoPoint{
		mustPt(-74.081750, 4.638190),
		mustPt(-74.081650, 4.638190),
		mustPt(-74.081650, 4.638250),
		mustPt(-74.081750, 4.638250),
		mustPt(-74.081750, 4.638190),
	}
	svc.GuardarGeometriaEspacio(ctx, usecaseGeo.GuardarGeometriaCmd{
		EspacioID:     espacioID,
		Vertices:      polyV1,
		MetodoCaptura: geo.MetodoRecorridoPerimetral,
		Actor:         actor,
	})

	// Guardar v2
	polyV2 := []geo.GeoPoint{
		mustPt(-74.081760, 4.638180),
		mustPt(-74.081640, 4.638180),
		mustPt(-74.081640, 4.638260),
		mustPt(-74.081760, 4.638260),
		mustPt(-74.081760, 4.638180),
	}
	svc.GuardarGeometriaEspacio(ctx, usecaseGeo.GuardarGeometriaCmd{
		EspacioID:     espacioID,
		Vertices:      polyV2,
		MetodoCaptura: geo.MetodoToqueMapa,
		Actor:         actor,
	})

	// T-GEO-06.3, AC-03: Recuperar versión histórica 1
	ver1, err := svc.ObtenerVersionGeometria(ctx, espacioID, 1)
	if err != nil {
		t.Fatalf("error recuperando v1 histórica: %v", err)
	}
	if ver1.Version != 1 {
		t.Errorf("se esperaba versión 1, obtenido: %d", ver1.Version)
	}
	if len(ver1.Geometria.Vertices()) != len(polyV1) {
		t.Errorf("la geometría histórica de v1 no coincide en vértices")
	}

	// Recuperar versión actual activa (v2)
	ver2, err := svc.ObtenerVersionGeometria(ctx, espacioID, 2)
	if err != nil {
		t.Fatalf("error recuperando v2: %v", err)
	}
	if ver2.Version != 2 {
		t.Errorf("se esperaba versión 2, obtenido: %d", ver2.Version)
	}

	// Solicitar versión inexistente
	verInexistente, err := svc.ObtenerVersionGeometria(ctx, espacioID, 99)
	if err == nil && verInexistente != nil {
		t.Errorf("se esperaba error not found para versión 99")
	}
}
