// Package marcaje — caso de uso para registro de lista manual por el docente.
// Satisface US-MAR-14 (AC-01..AC-04) y RF-MAR-013.
package marcaje

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	domainMarcaje "github.com/siaa/backend/internal/domain/marcaje"
	"github.com/siaa/backend/internal/repository"
)

var (
	ErrMotivoListaRequerido = errors.New("el motivo del uso de la lista manual es obligatorio (US-MAR-14 AC-03)")
)

// ItemListaEstudiante representa el pase de lista para un alumno particular.
type ItemListaEstudiante struct {
	EstudianteID string `json:"estudianteId"`
	Presente     bool   `json:"presente"`
}

// ListaManualUseCase registra la asistencia manual como respaldo preservando los marcajes geolocalizados.
type ListaManualUseCase struct {
	sesionRepo    repository.SesionRepository
	marcajeRepo   repository.MarcajeRepository
	auditoriaRepo repository.AuditoriaRepository
}

func NewListaManualUseCase(
	sesionRepo repository.SesionRepository,
	marcajeRepo repository.MarcajeRepository,
	auditoriaRepo repository.AuditoriaRepository,
) *ListaManualUseCase {
	return &ListaManualUseCase{
		sesionRepo:    sesionRepo,
		marcajeRepo:   marcajeRepo,
		auditoriaRepo: auditoriaRepo,
	}
}

// Registrar guarda el pase de lista manual de los estudiantes verificando la precedencia geolocalizada (AC-04).
func (uc *ListaManualUseCase) Registrar(ctx context.Context, sesionID, docenteID string, motivo string, items []ItemListaEstudiante) error {
	motivo = strings.TrimSpace(motivo)
	if motivo == "" {
		return ErrMotivoListaRequerido
	}

	s, err := uc.sesionRepo.FindByID(ctx, sesionID)
	if err != nil || s == nil {
		return fmt.Errorf("sesión no encontrada: %s", sesionID)
	}

	if !s.TieneDocente(docenteID) {
		return ErrDocenteNoAutorizado
	}

	ahora := time.Now().UTC()
	registrados := 0

	for _, item := range items {
		// AC-04: Si el estudiante ya marcó por geolocalización, prevalece y no se sobrescribe
		previo, _ := uc.marcajeRepo.ObtenerPrevio(ctx, sesionID, item.EstudianteID, domainMarcaje.TipoEntrada)
		if previo != nil && previo.Origen == domainMarcaje.OrigenAppMovil && previo.EsExitoso() {
			continue // No sobrescribir marcaje geolocalizado existente
		}

		resultado := domainMarcaje.ResultadoPresente
		if !item.Presente {
			resultado = domainMarcaje.ResultadoAusente
		}

		m := &domainMarcaje.Marcaje{
			SesionID:             sesionID,
			UsuarioID:            item.EstudianteID,
			DocenteID:            item.EstudianteID,
			RolMarcaje:           domainMarcaje.RolEstudiante,
			Tipo:                 domainMarcaje.TipoEntrada,
			Resultado:            resultado,
			TimestampServidor:    ahora,
			TimestampDispositivo: ahora,
			Timestamp:            ahora,
			Origen:               domainMarcaje.OrigenManualDocente, // AC-02: origen MANUAL_DOCENTE
			Anulado:              false,
			MotivoAjuste:         motivo,
			AjustadoPor:          docenteID,
			AjustadoEn:           &ahora,
			CreadoEn:             ahora,
		}

		if err := uc.marcajeRepo.Crear(ctx, m); err == nil {
			registrados++
		}
	}

	// AC-03: Auditoría obligatoria del uso de la lista manual
	if uc.auditoriaRepo != nil {
		_ = uc.auditoriaRepo.Create(ctx, &repository.AuditEntry{
			Entidad:    "sesiones",
			EntidadID:  sesionID,
			Accion:     "LISTA_MANUAL_DOCENTE",
			ActorID:    docenteID,
			ValorNuevo: fmt.Sprintf("Motivo: %s. Alumnos procesados: %d", motivo, registrados),
			CreadoEn:   ahora,
		})
	}

	return nil
}
