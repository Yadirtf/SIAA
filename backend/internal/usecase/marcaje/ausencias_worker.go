// Package marcaje — worker para generación automática de ausencias docentes.
// Satisface US-MAR-07 (AC-01..AC-06), RN-003, RF-MAR-011, T-MAR-07.1..07.4 y ADR-09:
// corre como proceso aparte (cmd/worker) y revisa solo la ventana nueva desde la última
// marca de agua, no todas las sesiones pasadas.
package marcaje

import (
	"context"
	"fmt"
	"time"

	"github.com/siaa/backend/internal/domain/academico"
	domainMarcaje "github.com/siaa/backend/internal/domain/marcaje"
	"github.com/siaa/backend/internal/repository"
)

const (
	procesoAusencias = "ausencias"
	// solape vuelve a revisar el final de la ventana anterior por si una sesión se reprogramó
	// o un ciclo se interrumpió; la idempotencia evita duplicados.
	solapeAusencias = time.Hour
	// retrocesoInicial es cuánto revisa el primer ciclo cuando no hay marca de agua.
	retrocesoInicial = 7 * 24 * time.Hour
)

// AusenciasWorker ejecuta el barrido periódico de sesiones expiradas sin marcaje.
type AusenciasWorker struct {
	marcajeRepo repository.MarcajeRepository
	sesionRepo  repository.SesionRepository
	procesos    repository.ProcesoRepository
}

func NewAusenciasWorker(marcajeRepo repository.MarcajeRepository, sesionRepo repository.SesionRepository) *AusenciasWorker {
	return &AusenciasWorker{
		marcajeRepo: marcajeRepo,
		sesionRepo:  sesionRepo,
	}
}

// WithMarcaDeAgua habilita el procesamiento incremental entre ciclos (ADR-09).
func (w *AusenciasWorker) WithMarcaDeAgua(p repository.ProcesoRepository) *AusenciasWorker {
	w.procesos = p
	return w
}

// EjecutarCiclo procesa un ciclo de evaluación de ausencias para un instante dado (permite inyección de reloj - T-MAR-07.6).
func (w *AusenciasWorker) EjecutarCiclo(ctx context.Context, ahora time.Time) (int, error) {
	if ahora.IsZero() {
		ahora = time.Now().UTC()
	}
	desde, err := w.inicioVentana(ctx, ahora)
	if err != nil {
		return 0, err
	}

	// 1. Sesiones cuya ventana de entrada cerró en la ventana nueva sin entrada de algún docente (AC-01)
	sesiones, err := w.marcajeRepo.ObtenerSesionesExpiradasSinMarcaje(ctx, desde, ahora)
	if err != nil {
		return 0, fmt.Errorf("error consultando sesiones para ausencias: %w", err)
	}

	ausenciasGeneradas := 0
	for _, s := range sesiones {
		// AC-02: Excluir explícitamente canceladas o excluidas
		if s.Estado() == academico.EstadoSesionCancelada || s.Estado() == academico.EstadoSesionExcluida {
			continue
		}
		// AC-03: la ausencia se atribuye a cada docente responsable (titular o suplente asignado)
		for _, docenteID := range s.DocenteIDs() {
			// AC-04: Idempotencia — no duplicar si ya hay un registro consolidado
			previo, _ := w.marcajeRepo.ObtenerPrevio(ctx, s.ID(), docenteID, domainMarcaje.TipoEntrada)
			if previo != nil {
				continue
			}
			if err := w.marcajeRepo.Crear(ctx, nuevaAusencia(s.ID(), docenteID, ahora)); err == nil {
				ausenciasGeneradas++
			}
		}
	}

	if w.procesos != nil {
		if err := w.procesos.GuardarMarca(ctx, procesoAusencias, ahora); err != nil {
			return ausenciasGeneradas, err
		}
	}
	return ausenciasGeneradas, nil
}

// inicioVentana calcula desde dónde revisar: la última marca menos el solape, o el
// retroceso inicial si es el primer ciclo.
func (w *AusenciasWorker) inicioVentana(ctx context.Context, ahora time.Time) (time.Time, error) {
	if w.procesos != nil {
		marca, err := w.procesos.ObtenerMarca(ctx, procesoAusencias)
		if err != nil {
			return time.Time{}, err
		}
		if marca != nil && marca.Before(ahora) {
			return marca.Add(-solapeAusencias), nil
		}
	}
	return ahora.Add(-retrocesoInicial), nil
}

// nuevaAusencia crea el registro automático de inasistencia (RN-003).
func nuevaAusencia(sesionID, docenteID string, ahora time.Time) *domainMarcaje.Marcaje {
	return &domainMarcaje.Marcaje{
		SesionID:             sesionID,
		UsuarioID:            docenteID,
		DocenteID:            docenteID,
		RolMarcaje:           domainMarcaje.RolDocente,
		Tipo:                 domainMarcaje.TipoEntrada,
		Resultado:            domainMarcaje.ResultadoAusente,
		TimestampServidor:    ahora,
		TimestampDispositivo: ahora,
		Timestamp:            ahora,
		Origen:               domainMarcaje.OrigenSistemaAusencia,
		MotivoRechazo:        "Ventana de entrada expirada sin registro de asistencia",
		CreadoEn:             ahora,
	}
}
