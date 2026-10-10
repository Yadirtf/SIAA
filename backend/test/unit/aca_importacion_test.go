// Prueba unitaria de la carga masiva académica (US-ACA-07).
package unit_test

import (
	"context"
	"strings"
	"testing"
	"time"

	domainAca "github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/domain/user"
	applog "github.com/siaa/backend/internal/platform/log"
	usecaseAca "github.com/siaa/backend/internal/usecase/academico"
)

func Test_US_ACA_07_ImportacionMasivaCSV(t *testing.T) {
	now := time.Date(2026, 9, 25, 8, 0, 0, 0, time.UTC)
	clk := shared.NewFakeClock(now)
	logger := applog.New(applog.LevelDebug, nil)
	ctx := context.Background()

	pRepo := newMockPeriodoRepo()
	estRepo := newMockEstructuraRepo()
	asigRepo := newMockAsignacionRepo()
	docente := &user.Usuario{ID: "DOC-1", Correo: "docente@siaa.edu.co", Nombre: "Ana", Activo: true,
		Roles: []user.RolAsignado{{Nombre: rbac.RolDocente}}}
	svc := usecaseAca.NewService(pRepo, estRepo, asigRepo, nil, &mockUsuarioRepo{usuario: docente}, nil, &mockAuditoriaRepo{}, clk, logger)

	periodo, _ := domainAca.NuevoPeriodo("PER-2026-CSV", "2026-CSV", "Periodo CSV", now, now.AddDate(0, 4, 0), domainAca.EstadoActivo, "SEDE-1", nil, now)
	_ = pRepo.Create(ctx, periodo)
	fac, _ := domainAca.NuevaFacultad("FAC-1", "ING", "Ingeniería", "SEDE-1", nil, now)
	prog, _ := domainAca.NuevoPrograma("PROG-1", "SIS", "Sistemas", fac.ID(), nil, now)
	mat, _ := domainAca.NuevaAsignatura("ASIG-1", "MAT-101", "Matemáticas", prog.ID(), 3, nil, now)
	_ = estRepo.CreateFacultad(ctx, fac)
	_ = estRepo.CreatePrograma(ctx, prog)
	_ = estRepo.CreateAsignatura(ctx, mat)

	// Separador punto y coma con BOM (Excel en español), día por nombre y hora sin cero inicial.
	csvContent := "\xef\xbb\xbfperiodo;programa;asignatura;grupo;docente;aula;dia;horaInicio;horaFin;modalidad\n" +
		"2026-CSV;SIS;MAT-101;01;docente@siaa.edu.co;;lunes;7:00;09:00;VIRTUAL\n" +
		"2026-CSV;SIS;MAT-101;02;docente@siaa.edu.co;;8;08:00;10:00;VIRTUAL\n" +
		"2026-CSV;SIS;FIS-999;03;docente@siaa.edu.co;;2;08:00;10:00;VIRTUAL\n" +
		"2026-CSV;SIS;MAT-101;04;docente@siaa.edu.co;;1;08:00;10:00;VIRTUAL\n"
	actor := usecaseAca.ContextoActor{UsuarioID: "ADM", Rol: "ADMIN_INSTITUCIONAL"}
	preview, err := svc.PreviewImportacion(ctx, actor, []byte(csvContent))
	if err != nil {
		t.Fatalf("error en preview csv: %v", err)
	}
	if preview.TotalFilas != 4 || preview.FilasValidas != 1 || preview.FilasConError != 3 || !preview.SuperaUmbral {
		t.Fatalf("informe inesperado: %+v", preview)
	}
	esperados := map[int]string{3: "Día de la semana", 4: "La asignatura 'FIS-999' no existe", 5: "Choque de docente con la fila 2"}
	for _, f := range preview.Filas {
		if want, ok := esperados[f.NumeroFila]; ok && (len(f.Errores) == 0 || !strings.Contains(strings.Join(f.Errores, "|"), want)) {
			t.Errorf("fila %d: se esperaba %q en %v", f.NumeroFila, want, f.Errores)
		}
	}

	// AC-03: por encima del umbral no se aplica nada.
	res, err := svc.ConfirmarImportacion(ctx, actor, "carga.csv", []byte(csvContent))
	if err != nil || res.Aplicada || len(asigRepo.asignaciones) != 0 {
		t.Fatalf("con errores sobre el umbral no se debe aplicar nada: %+v, %v", res, err)
	}

	// Con un umbral permisivo se aplican solo las filas válidas y se crea el grupo faltante.
	svc.WithCargasMasivas(nil, 100)
	res, err = svc.ConfirmarImportacion(ctx, actor, "carga.csv", []byte(csvContent))
	if err != nil || !res.Aplicada || res.AsignacionesCreadas != 1 || res.GruposCreados != 1 || res.FilasOmitidas != 3 {
		t.Fatalf("aplicación parcial inesperada: %+v, %v", res, err)
	}
	for _, a := range asigRepo.asignaciones {
		if a.AsignaturaID() != mat.ID() || a.FacultadID() != fac.ID() || a.DocenteIDs()[0] != "DOC-1" {
			t.Errorf("la asignación debe guardar IDs resueltos, no códigos: %+v", a)
		}
	}
}
