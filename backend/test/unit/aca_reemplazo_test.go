package unit_test

import (
	"context"
	"testing"
	"time"

	domainAca "github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/domain/shared"
	applog "github.com/siaa/backend/internal/platform/log"
	usecaseAca "github.com/siaa/backend/internal/usecase/academico"
)

// Test_US_ACA_09_ReemplazoDocenteSesion verifica la designación de un suplente puntual (US-ACA-09).
func Test_US_ACA_09_ReemplazoDocenteSesion(t *testing.T) {
	now := time.Date(2026, 9, 25, 8, 0, 0, 0, time.UTC)
	clk := shared.NewFakeClock(now)
	logger := applog.New(applog.LevelDebug, nil)

	sesRepo := newMockSesionRepo()
	svc := usecaseAca.NewService(nil, nil, nil, nil, nil, nil, &mockAuditoriaRepo{}, clk, logger).
		WithSesiones(sesRepo)

	ses, _ := domainAca.NuevaSesion(
		"SES-30", "PER-1", "ASIG-1", "MAT-1", "GRP-1",
		[]string{"DOC-TITULAR"}, "AULA-1", "2026-10-05", "08:00", "10:00",
		now, now.Add(2*time.Hour), now, now.Add(15*time.Minute),
		nil, nil, 1, nil, nil, nil, now,
	)
	_ = sesRepo.Create(context.Background(), ses)

	// Designar docente suplente para esta sesión puntual
	actualizada, err := svc.AsignarDocenteReemplazo(
		context.Background(), "SES-30", "DOC-SUPLENTE", "Licencia médica del titular",
		usecaseAca.ContextoActor{
			UsuarioID: "COORD-1", Rol: "COORDINADOR_ACADEMICO",
		},
	)
	if err != nil {
		t.Fatalf("error asignando suplente: %v", err)
	}

	if len(actualizada.DocenteIDs()) != 1 || actualizada.DocenteIDs()[0] != "DOC-SUPLENTE" {
		t.Errorf("esperaba docente DOC-SUPLENTE, obtuvo: %v", actualizada.DocenteIDs())
	}
	if !actualizada.TieneDocente("DOC-SUPLENTE") {
		t.Errorf("la sesion deberia tener asignado a DOC-SUPLENTE")
	}
}
