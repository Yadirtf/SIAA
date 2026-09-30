package unit

import (
	"context"
	"sync"
	"testing"
	"time"

	"github.com/siaa/backend/internal/domain/academico"
	domainMarcaje "github.com/siaa/backend/internal/domain/marcaje"
	usecaseMarcaje "github.com/siaa/backend/internal/usecase/marcaje"
)

func TestMarcaje_Concurrencia_20Peticiones(t *testing.T) {
	// T-MAR-04.7, US-MAR-05 AC-01, CA-012
	// 20 peticiones simultáneas para la misma sesión y usuario producen exactamente un marcaje lógico
	mRepo := newFakeMarcajeRepo()
	sesionRepo := &fakeSesionRepo{
		sesiones: make(map[string]*academico.Sesion),
	}
	_ = sesionRepo
	espacioRepo := &fakeEspacioRepo{}
	dispRepo := &fakeDispositivoRepo{}
	audRepo := &fakeAuditoriaRepo{}

	uc := usecaseMarcaje.NewCrearMarcajeUseCase(mRepo, &fakeSesionRepo{}, espacioRepo, dispRepo, audRepo, nil)

	ctx := context.Background()
	ahora := time.Date(2026, 9, 8, 8, 4, 0, 0, time.UTC)

	const numGoroutines = 20
	var wg sync.WaitGroup
	wg.Add(numGoroutines)

	resultados := make([]*domainMarcaje.Marcaje, numGoroutines)
	errores := make([]error, numGoroutines)

	for i := 0; i < numGoroutines; i++ {
		idx := i
		go func() {
			defer wg.Done()
			req := domainMarcaje.SolicitudMarcaje{
				SesionID:             "ses-concurrente-1",
				UsuarioID:            "doc-1",
				RolMarcaje:           domainMarcaje.RolDocente,
				Tipo:                 domainMarcaje.TipoEntrada,
				Latitud:              4.6095,
				Longitud:             -74.0815,
				PrecisionMetros:      8.0,
				TimestampDispositivo: ahora,
				DispositivoID:        "disp-1",
			}
			_, m, err := uc.Ejecutar(ctx, req, ahora)
			resultados[idx] = m
			errores[idx] = err
		}()
	}

	wg.Wait()

	// 1. Ninguna de las 20 peticiones debe retornar error 500 / error de BD
	for i, err := range errores {
		if err != nil {
			t.Fatalf("goroutine %d falló con error: %v", i, err)
		}
	}

	// 2. Todas las peticiones deben devolver exactamente el mismo ID de marcaje lógico
	var primerID string
	for i, m := range resultados {
		if m == nil {
			t.Fatalf("goroutine %d retornó marcaje nulo", i)
		}
		if i == 0 {
			primerID = m.ID
		} else {
			if m.ID != primerID {
				t.Errorf("goroutine %d retornó ID distinto: %s (esperado: %s)", i, m.ID, primerID)
			}
		}
	}

	// 3. En la persistencia debe existir exactamente 1 único registro
	if len(mRepo.items) != 1 {
		t.Errorf("se esperaba exactamente 1 marcaje persistido bajo concurrencia, hay: %d", len(mRepo.items))
	}
}
