package unit

import (
	"context"
	"testing"
	"time"

	"github.com/siaa/backend/internal/domain/academico"
	domainMarcaje "github.com/siaa/backend/internal/domain/marcaje"
	usecaseMarcaje "github.com/siaa/backend/internal/usecase/marcaje"
)

type fakeWorkerMarcajeRepo struct {
	*fakeMarcajeRepo
	sesionesExpiradas []*academico.Sesion
}

func (r *fakeWorkerMarcajeRepo) ObtenerSesionesExpiradasSinMarcaje(ctx context.Context, ahora time.Time) ([]*academico.Sesion, error) {
	return r.sesionesExpiradas, nil
}

func TestAusenciasWorker_EjecutarCiclo(t *testing.T) {
	// T-MAR-07.6: Pruebas con reloj inyectable
	ctx := context.Background()
	ahora := time.Date(2026, 9, 8, 9, 30, 0, 0, time.UTC)
	inicio := ahora.Add(-90 * time.Minute)
	fin := ahora.Add(30 * time.Minute)
	abre := inicio.Add(-15 * time.Minute)
	cierra := inicio.Add(15 * time.Minute)

	t.Run("Ventana expirada sin marcaje genera AUSENTE (US-MAR-07 AC-01)", func(t *testing.T) {
		mRepo := &fakeWorkerMarcajeRepo{
			fakeMarcajeRepo: newFakeMarcajeRepo(),
		}
		s1 := academico.ReconstituirSesion(
			"ses-1", "per-1", "asig-1", "MAT101", "G1", []string{"doc-1"}, "esp-1",
			"2026-09-08", "08:00", "10:00", inicio, fin, abre, cierra, nil, nil,
			academico.EstadoSesionProgramada, 1, nil, nil, nil, "", time.Now(), time.Now(),
		)
		mRepo.sesionesExpiradas = []*academico.Sesion{s1}

		worker := usecaseMarcaje.NewAusenciasWorker(mRepo, &fakeSesionRepo{})
		generadas, err := worker.EjecutarCiclo(ctx, ahora)
		if err != nil {
			t.Fatalf("error ejecutando ciclo: %v", err)
		}
		if generadas != 1 {
			t.Errorf("se esperaba 1 ausencia generada, obtuvo: %d", generadas)
		}

		previo, _ := mRepo.ObtenerPrevio(ctx, "ses-1", "doc-1", domainMarcaje.TipoEntrada)
		if previo == nil || previo.Resultado != domainMarcaje.ResultadoAusente {
			t.Errorf("se esperaba registro previo con resultado AUSENTE")
		}

		// Reejecución no duplica (AC-04 Idempotencia)
		generadas2, err2 := worker.EjecutarCiclo(ctx, ahora)
		if err2 != nil {
			t.Fatalf("error en reejecución: %v", err2)
		}
		if generadas2 != 0 {
			t.Errorf("reejecución no debe generar ausencias adicionales, obtuvo: %d", generadas2)
		}
	})

	t.Run("Sesión cancelada no genera ausencia (AC-02)", func(t *testing.T) {
		mRepo := &fakeWorkerMarcajeRepo{
			fakeMarcajeRepo: newFakeMarcajeRepo(),
		}
		sCancelada := academico.ReconstituirSesion(
			"ses-cancelada", "per-1", "asig-1", "MAT101", "G1", []string{"doc-1"}, "esp-1",
			"2026-09-08", "08:00", "10:00", inicio, fin, abre, cierra, nil, nil,
			academico.EstadoSesionCancelada, 1, nil, nil, nil, "Motivo paro", time.Now(), time.Now(),
		)
		mRepo.sesionesExpiradas = []*academico.Sesion{sCancelada}

		worker := usecaseMarcaje.NewAusenciasWorker(mRepo, &fakeSesionRepo{})
		generadas, err := worker.EjecutarCiclo(ctx, ahora)
		if err != nil {
			t.Fatalf("error: %v", err)
		}
		if generadas != 0 {
			t.Errorf("sesion cancelada no debe generar ausencia, obtuvo: %d", generadas)
		}
	})
}
