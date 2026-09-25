package unit_test

import (
	"context"
	"strings"
	"testing"
	"time"

	domainAca "github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/domain/geo"
	"github.com/siaa/backend/internal/domain/parametro"
	"github.com/siaa/backend/internal/domain/shared"
	applog "github.com/siaa/backend/internal/platform/log"
	usecaseAca "github.com/siaa/backend/internal/usecase/academico"
)

func Test_US_ACA_05_GeneracionSesiones_Idempotente(t *testing.T) {
	now := time.Date(2026, 9, 25, 8, 0, 0, 0, time.UTC)
	clk := shared.NewFakeClock(now)
	logger := applog.New(applog.LevelDebug, nil)

	pRepo := newMockPeriodoRepo()
	asigRepo := newMockAsignacionRepo()
	excRepo := newMockExcepcionRepo()
	espRepo := newMockEspacioRepo()
	sesRepo := newMockSesionRepo()
	auditRepo := &mockAuditoriaRepo{}

	svc := usecaseAca.NewService(pRepo, nil, asigRepo, excRepo, nil, espRepo, auditRepo, clk, logger).
		WithSesiones(sesRepo)

	// Periodo: 2 semanas: del Lunes 2026-10-05 al Domingo 2026-10-18
	pInicio := time.Date(2026, 10, 5, 0, 0, 0, 0, time.UTC)
	pFin := time.Date(2026, 10, 18, 23, 59, 59, 0, time.UTC)
	periodo, _ := domainAca.NuevoPeriodo("PER-2026-2", "2026-2", "Periodo 2", pInicio, pFin, domainAca.EstadoActivo, "SEDE-1", nil, now)
	_ = pRepo.Create(context.Background(), periodo)

	// Espacio con versión de geometría
	pt1, _ := geo.NewGeoPoint(-74.0650, 4.6500)
	pt2, _ := geo.NewGeoPoint(-74.0649, 4.6500)
	pt3, _ := geo.NewGeoPoint(-74.0649, 4.6501)
	pt4, _ := geo.NewGeoPoint(-74.0650, 4.6501)
	pol, _ := geo.NewGeoPolygon([]geo.GeoPoint{pt1, pt2, pt3, pt4, pt1})

	esp := &geo.Espacio{
		ID:               "ESP-101",
		Nombre:           "Aula 101",
		VersionGeometria: 2,
		Geometria:        &pol,
		GeometriaBuffer:  &pol,
	}
	_ = espRepo.Create(context.Background(), esp)

	// Asignación: Lunes (DiaSemana=1) de 08:00 a 10:00
	franja, _, _ := domainAca.NuevaFranjaHoraria(1, "08:00", "10:00", "America/Bogota")
	asig, errAsig := domainAca.NuevaAsignacion(
		"ASIG-01", periodo.ID(), []string{"DOC-1"}, "Profesor Uno", "GRP-1",
		"ASIG-1", "FAC-1", esp.ID, esp.Nombre, franja,
		domainAca.ModalidadPresencial, nil,
		pInicio, pFin, nil, now,
	)
	if errAsig != nil {
		t.Fatalf("error creando asignacion: %v", errAsig)
	}
	_ = asigRepo.Create(context.Background(), asig)

	// Excepción de calendario: Lunes festivo 2026-10-12
	excFecha := time.Date(2026, 10, 12, 0, 0, 0, 0, time.UTC)
	exc, _ := domainAca.NuevaCalendarioExcepcion(
		"exc-1", "Festivo Nacional", domainAca.ExcepcionFestivo, domainAca.AmbitoGlobal, "",
		excFecha, excFecha.Add(23*time.Hour+59*time.Minute+59*time.Second), now,
	)
	_ = excRepo.Create(context.Background(), exc)

	actor := usecaseAca.ContextoActor{UsuarioID: "ADMIN-1", Rol: "ADMINISTRADOR"}

	// Primera ejecución: debe generar exactamente 1 sesión (2026-10-05), omitiendo 2026-10-12 por festivo
	inf1, err := svc.GenerarSesiones(context.Background(), usecaseAca.GenerarSesionesCmd{
		PeriodoID: periodo.ID(),
		Actor:     actor,
	})
	if err != nil {
		t.Fatalf("error inesperado en 1ra generacion: %v", err)
	}
	if inf1.SesionesGeneradas != 1 {
		t.Errorf("esperaba 1 sesion generada, obtuvo %d", inf1.SesionesGeneradas)
	}
	if len(inf1.FechasExcluidas) != 1 {
		t.Errorf("esperaba 1 fecha excluida por festivo, obtuvo %d", len(inf1.FechasExcluidas))
	}

	// Segunda ejecución (IDEMPOTENCIA): no debe duplicar, 0 creadas, 1 omitida por idempotencia (AC-03)
	inf2, err := svc.GenerarSesiones(context.Background(), usecaseAca.GenerarSesionesCmd{
		PeriodoID: periodo.ID(),
		Actor:     actor,
	})
	if err != nil {
		t.Fatalf("error inesperado en 2da generacion: %v", err)
	}
	if inf2.SesionesGeneradas != 0 {
		t.Errorf("idempotencia violada: creo %d sesiones en 2da corrida", inf2.SesionesGeneradas)
	}
	if inf2.SesionesOmitidasIdempotencia != 1 {
		t.Errorf("esperaba 1 sesion omitida por idempotencia, obtuvo %d", inf2.SesionesOmitidasIdempotencia)
	}
}

func Test_US_ACA_05_ParametrosCongelados_Inmutabilidad(t *testing.T) {
	now := time.Date(2026, 9, 25, 8, 0, 0, 0, time.UTC)
	clk := shared.NewFakeClock(now)
	logger := applog.New(applog.LevelDebug, nil)

	pRepo := newMockPeriodoRepo()
	asigRepo := newMockAsignacionRepo()
	sesRepo := newMockSesionRepo()

	svc := usecaseAca.NewService(pRepo, nil, asigRepo, newMockExcepcionRepo(), nil, newMockEspacioRepo(), &mockAuditoriaRepo{}, clk, logger).
		WithSesiones(sesRepo)

	pInicio := time.Date(2026, 10, 5, 0, 0, 0, 0, time.UTC)
	pFin := time.Date(2026, 10, 11, 23, 59, 59, 0, time.UTC)
	periodo, _ := domainAca.NuevoPeriodo("PER-2026-PARAM", "2026-PARAM", "Periodo Param", pInicio, pFin, domainAca.EstadoActivo, "SEDE-1", nil, now)
	_ = pRepo.Create(context.Background(), periodo)

	// Asignación con override específico de parámetro
	franja, _, _ := domainAca.NuevaFranjaHoraria(1, "14:00", "16:00", "America/Bogota")
	overrides := map[string]interface{}{
		string(parametro.ClaveHolguraEntradaAntes):    25,
		string(parametro.ClaveBufferPerimetralMetros): 35,
	}
	asig, errAsig := domainAca.NuevaAsignacion(
		"ASIG-02", periodo.ID(), []string{"DOC-1"}, "Profesor", "GRP-1",
		"ASIG-1", "FAC-1", "ESP-101", "Aula 101", franja,
		domainAca.ModalidadPresencial, overrides,
		pInicio, pFin, nil, now,
	)
	if errAsig != nil {
		t.Fatalf("error creando asignacion con overrides: %v", errAsig)
	}
	_ = asigRepo.Create(context.Background(), asig)

	_, err := svc.GenerarSesiones(context.Background(), usecaseAca.GenerarSesionesCmd{
		PeriodoID: periodo.ID(),
		Actor:     usecaseAca.ContextoActor{UsuarioID: "ADM", Rol: "ADMINISTRADOR"},
	})
	if err != nil {
		t.Fatalf("fallo al generar sesiones: %v", err)
	}

	sesiones, _ := sesRepo.ListByPeriodo(context.Background(), periodo.ID())
	if len(sesiones) != 1 {
		t.Fatalf("esperaba 1 sesion, obtuvo %d", len(sesiones))
	}

	ses := sesiones[0]
	// Comprobar parámetros congelados (AC-02, AC-06)
	congelados := ses.ParametrosCongelados()
	if congelados[string(parametro.ClaveHolguraEntradaAntes)] != 25 {
		t.Errorf("parametro congelado incorrecto: %v", congelados[string(parametro.ClaveHolguraEntradaAntes)])
	}
	if congelados[string(parametro.ClaveBufferPerimetralMetros)] != 35 {
		t.Errorf("parametro buffer incorrecto: %v", congelados[string(parametro.ClaveBufferPerimetralMetros)])
	}
	// Estado inicial PROGRAMADA (AC-07)
	if ses.Estado() != domainAca.EstadoSesionProgramada {
		t.Errorf("estado inicial esperado PROGRAMADA, obtenido: %s", ses.Estado())
	}
}

func Test_US_ACA_06_ReasignarAulaSesion(t *testing.T) {
	now := time.Date(2026, 9, 25, 8, 0, 0, 0, time.UTC)
	clk := shared.NewFakeClock(now)
	logger := applog.New(applog.LevelDebug, nil)

	espRepo := newMockEspacioRepo()
	sesRepo := newMockSesionRepo()

	svc := usecaseAca.NewService(nil, nil, nil, nil, nil, espRepo, &mockAuditoriaRepo{}, clk, logger).
		WithSesiones(sesRepo)

	pt1, _ := geo.NewGeoPoint(-74.0650, 4.6500)
	pt2, _ := geo.NewGeoPoint(-74.0649, 4.6500)
	pt3, _ := geo.NewGeoPoint(-74.0649, 4.6501)
	pt4, _ := geo.NewGeoPoint(-74.0650, 4.6501)
	pol1, _ := geo.NewGeoPolygon([]geo.GeoPoint{pt1, pt2, pt3, pt4, pt1})

	pt5, _ := geo.NewGeoPoint(-74.0660, 4.6510)
	pt6, _ := geo.NewGeoPoint(-74.0659, 4.6510)
	pt7, _ := geo.NewGeoPoint(-74.0659, 4.6511)
	pt8, _ := geo.NewGeoPoint(-74.0660, 4.6511)
	pol2, _ := geo.NewGeoPolygon([]geo.GeoPoint{pt5, pt6, pt7, pt8, pt5})

	esp1 := &geo.Espacio{ID: "AULA-1", Nombre: "Aula 1", VersionGeometria: 1, Geometria: &pol1}
	esp2 := &geo.Espacio{ID: "AULA-2", Nombre: "Aula 2", VersionGeometria: 3, Geometria: &pol2}
	_ = espRepo.Create(context.Background(), esp1)
	_ = espRepo.Create(context.Background(), esp2)

	ses, _ := domainAca.NuevaSesion("SES-10", "PER-1", "ASIG-1", "MAT-1", "GRP-1", []string{"DOC-1"}, "AULA-1", "2026-10-05", "08:00", "10:00", now, now.Add(2*time.Hour), now, now.Add(15*time.Minute), nil, nil, 1, &pol1, nil, nil, now)
	_ = sesRepo.Create(context.Background(), ses)

	// Reasignar al aula 2 (AC-01..AC-04)
	_, err := svc.ReasignarAulaSesion(context.Background(), "SES-10", "AULA-2", "Cambio por capacidad", usecaseAca.ContextoActor{
		UsuarioID: "ADMIN", Rol: "ADMINISTRADOR",
	})
	if err != nil {
		t.Fatalf("error reasignando aula: %v", err)
	}

	actualizada, _ := sesRepo.FindByID(context.Background(), "SES-10")
	if actualizada.EspacioID() != "AULA-2" {
		t.Errorf("esperaba espacio AULA-2, obtuvo: %s", actualizada.EspacioID())
	}
	if actualizada.EspacioVersionGeometria() != 3 {
		t.Errorf("esperaba version de geometria 3, obtuvo: %d", actualizada.EspacioVersionGeometria())
	}
}

func Test_US_ACA_08_CancelarSesion(t *testing.T) {
	now := time.Date(2026, 9, 25, 8, 0, 0, 0, time.UTC)
	clk := shared.NewFakeClock(now)
	logger := applog.New(applog.LevelDebug, nil)

	sesRepo := newMockSesionRepo()
	svc := usecaseAca.NewService(nil, nil, nil, nil, nil, nil, &mockAuditoriaRepo{}, clk, logger).
		WithSesiones(sesRepo)

	ses, _ := domainAca.NuevaSesion("SES-20", "PER-1", "ASIG-1", "MAT-1", "GRP-1", []string{"DOC-1"}, "AULA-1", "2026-10-05", "08:00", "10:00", now, now.Add(2*time.Hour), now, now.Add(15*time.Minute), nil, nil, 1, nil, nil, nil, now)
	_ = sesRepo.Create(context.Background(), ses)

	err := svc.CancelarSesion(context.Background(), "SES-20", "Falla en suministro electrico", usecaseAca.ContextoActor{
		UsuarioID: "DOC-1", Rol: "DOCENTE",
	})
	if err != nil {
		t.Fatalf("error cancelando sesion: %v", err)
	}

	cancelada, _ := sesRepo.FindByID(context.Background(), "SES-20")
	if cancelada.Estado() != domainAca.EstadoSesionCancelada {
		t.Errorf("esperaba estado CANCELADA, obtuvo: %s", cancelada.Estado())
	}
	if cancelada.MotivoCancelacion() != "Falla en suministro electrico" {
		t.Errorf("motivo no coincide: %s", cancelada.MotivoCancelacion())
	}
}

func Test_US_ACA_07_ImportacionMasivaCSV(t *testing.T) {
	now := time.Date(2026, 9, 25, 8, 0, 0, 0, time.UTC)
	clk := shared.NewFakeClock(now)
	logger := applog.New(applog.LevelDebug, nil)

	pRepo := newMockPeriodoRepo()
	estRepo := newMockEstructuraRepo()
	asigRepo := newMockAsignacionRepo()

	svc := usecaseAca.NewService(pRepo, estRepo, asigRepo, nil, nil, nil, &mockAuditoriaRepo{}, clk, logger)

	periodo, _ := domainAca.NuevoPeriodo("PER-2026-CSV", "2026-CSV", "Periodo CSV", now, now.AddDate(0, 4, 0), domainAca.EstadoActivo, "SEDE-1", nil, now)
	_ = pRepo.Create(context.Background(), periodo)

	csvContent := `periodoId,facultadId,programaId,asignaturaId,asignaturaNombre,grupoId,docenteId,aulaId,diaSemana,horaInicio,horaFin,modalidad
PER-2026-CSV,FAC-ING,PROG-SIS,MAT-101,Matematicas,GRP-1,DOC-1,AULA-101,1,08:00,10:00,PRESENCIAL
PER-2026-CSV,FAC-ING,PROG-SIS,FIS-201,Fisica,GRP-2,DOC-2,AULA-102,8,08:00,10:00,PRESENCIAL
`
	preview, err := svc.PreviewImportacionCSV(context.Background(), strings.NewReader(csvContent))
	if err != nil {
		t.Fatalf("error en preview csv: %v", err)
	}

	if preview.TotalFilas != 2 {
		t.Errorf("esperaba 2 filas, obtuvo %d", preview.TotalFilas)
	}
	if preview.FilasValidas != 1 {
		t.Errorf("esperaba 1 fila valida, obtuvo %d", preview.FilasValidas)
	}
	if preview.FilasConError != 1 {
		t.Errorf("esperaba 1 fila invalida (diaSemana=8), obtuvo %d", preview.FilasConError)
	}

	// Confirmar importación
	res, err := svc.ConfirmarImportacionCSV(context.Background(), strings.NewReader(csvContent), usecaseAca.ContextoActor{
		UsuarioID: "ADM", Rol: "ADMINISTRADOR", Scopes: nil,
	})
	if err != nil {
		t.Fatalf("error en confirmacion csv: %v", err)
	}
	if res.AsignacionesCreadas != 1 {
		t.Errorf("esperaba 1 asignacion creada, obtuvo %d", res.AsignacionesCreadas)
	}
}
