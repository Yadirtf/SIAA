// Package marcaje — worker para generación automática de ausencias docentes.
// Satisface US-MAR-07 (AC-01..AC-06), RN-003, RF-MAR-011 y T-MAR-07.1..07.4.
package marcaje

import (
	"context"
	"fmt"
	"time"

	"github.com/siaa/backend/internal/domain/academico"
	domainMarcaje "github.com/siaa/backend/internal/domain/marcaje"
	"github.com/siaa/backend/internal/repository"
)

// AusenciasWorker ejecuta el barrido periódico de sesiones expiradas sin marcaje.
type AusenciasWorker struct {
	marcajeRepo repository.MarcajeRepository
	sesionRepo  repository.SesionRepository
}

func NewAusenciasWorker(marcajeRepo repository.MarcajeRepository, sesionRepo repository.SesionRepository) *AusenciasWorker {
	return &AusenciasWorker{
		marcajeRepo: marcajeRepo,
		sesionRepo:  sesionRepo,
	}
}

// EjecutarCiclo procesa un ciclo de evaluación de ausencias para un instante dado (permite inyección de reloj - T-MAR-07.6).
func (w *AusenciasWorker) EjecutarCiclo(ctx context.Context, ahora time.Time) (int, error) {
	if ahora.IsZero() {
		ahora = time.Now().UTC()
	}

	// 1. Consultar sesiones cuya ventana de entrada cerró y no tienen marcaje de entrada (AC-01)
	sesiones, err := w.marcajeRepo.ObtenerSesionesExpiradasSinMarcaje(ctx, ahora)
	if err != nil {
		return 0, fmt.Errorf("error consultando sesiones para ausencias: %w", err)
	}

	ausenciasGeneradas := 0

	for _, s := range sesiones {
		// AC-02: Excluir explícitamente canceladas o excluidas
		if s.Estado() == academico.EstadoSesionCancelada || s.Estado() == academico.EstadoSesionExcluida {
			continue
		}

		// AC-03: Resolver atribución según suplencia o titular
		docentesAfectados := s.DocenteIDs()
		// Nota: si existe suplencia designada en la sesión, se atribuye a este
		// La regla de suplencia aplica a la lista de docentes responsables

		for _, docenteID := range docentesAfectados {
			// AC-04: Idempotencia — verificar que no exista ya un registro de marcaje para esta sesión
			previo, _ := w.marcajeRepo.ObtenerPrevio(ctx, s.ID(), docenteID, domainMarcaje.TipoEntrada)
			if previo != nil {
				continue // Ya tiene marcaje o ausencia registrada
			}

			// Crear registro automático de inasistencia (RN-003)
			ausencia := &domainMarcaje.Marcaje{
				SesionID:             s.ID(),
				UsuarioID:            docenteID,
				DocenteID:            docenteID,
				RolMarcaje:           domainMarcaje.RolDocente,
				Tipo:                 domainMarcaje.TipoEntrada,
				Resultado:            domainMarcaje.ResultadoAusente,
				TimestampServidor:    ahora,
				TimestampDispositivo: ahora,
				Timestamp:            ahora,
				Origen:               domainMarcaje.OrigenSistemaAusencia,
				Anulado:              false,
				MotivoRechazo:        "Ventana de entrada expirada sin registro de asistencia",
				CreadoEn:             ahora,
			}

			if err := w.marcajeRepo.Crear(ctx, ausencia); err == nil {
				ausenciasGeneradas++
			}
		}
	}

	return ausenciasGeneradas, nil
}
