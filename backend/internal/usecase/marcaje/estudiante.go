// Package marcaje — caso de uso para gestión de ventana de marcaje estudiantil.
// Satisface US-MAR-13 (AC-01..AC-06) y RF-MAR-012.
package marcaje

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/repository"
)

var (
	ErrDocenteNoAutorizado = errors.New("el docente no está autorizado para gestionar esta sesión")
)

// duracionVentanaPorDefecto aplica cuando el docente no indica la duración.
const duracionVentanaPorDefecto = 15

// VentanaEstudiantilUseCase permite al docente habilitar y cerrar el marcaje a los alumnos del grupo.
type VentanaEstudiantilUseCase struct {
	sesionRepo    repository.SesionRepository
	marcajeRepo   repository.MarcajeRepository
	auditoriaRepo repository.AuditoriaRepository
	reloj         func() time.Time
}

func NewVentanaEstudiantilUseCase(sesionRepo repository.SesionRepository, marcajeRepo repository.MarcajeRepository) *VentanaEstudiantilUseCase {
	return &VentanaEstudiantilUseCase{
		sesionRepo:  sesionRepo,
		marcajeRepo: marcajeRepo,
		reloj:       func() time.Time { return time.Now().UTC() },
	}
}

// WithAuditoria registra la apertura y el cierre de la ventana.
func (uc *VentanaEstudiantilUseCase) WithAuditoria(r repository.AuditoriaRepository) *VentanaEstudiantilUseCase {
	uc.auditoriaRepo = r
	return uc
}

// WithReloj fija el reloj (pruebas).
func (uc *VentanaEstudiantilUseCase) WithReloj(reloj func() time.Time) *VentanaEstudiantilUseCase {
	uc.reloj = reloj
	return uc
}

// AbrirVentana abre la ventana temporal para que los estudiantes del grupo registren asistencia
// (AC-01) y la guarda en la sesión. Devuelve el instante de cierre.
func (uc *VentanaEstudiantilUseCase) AbrirVentana(ctx context.Context, sesionID, docenteID string, duracionMinutos int) (time.Time, error) {
	s, err := uc.sesionDelDocente(ctx, sesionID, docenteID)
	if err != nil {
		return time.Time{}, err
	}
	if duracionMinutos <= 0 {
		duracionMinutos = duracionVentanaPorDefecto
	}
	ahora := uc.reloj()
	if err := s.AbrirVentanaEstudiantil(ahora, time.Duration(duracionMinutos)*time.Minute); err != nil {
		return time.Time{}, err
	}
	if err := uc.sesionRepo.Update(ctx, s); err != nil {
		return time.Time{}, fmt.Errorf("guardar ventana estudiantil: %w", err)
	}
	uc.auditar(ctx, s, docenteID, "VENTANA_ESTUDIANTIL_ABIERTA", ahora)
	return s.VentanaEstudiantil().CierraEn, nil
}

// CerrarVentana termina la ventana antes de tiempo. Desde ese instante los estudiantes que
// intenten marcar son rechazados por horario (AC-04).
func (uc *VentanaEstudiantilUseCase) CerrarVentana(ctx context.Context, sesionID, docenteID string) (time.Time, error) {
	s, err := uc.sesionDelDocente(ctx, sesionID, docenteID)
	if err != nil {
		return time.Time{}, err
	}
	ahora := uc.reloj()
	if err := s.CerrarVentanaEstudiantil(ahora); err != nil {
		return time.Time{}, err
	}
	if err := uc.sesionRepo.Update(ctx, s); err != nil {
		return time.Time{}, fmt.Errorf("guardar ventana estudiantil: %w", err)
	}
	uc.auditar(ctx, s, docenteID, "VENTANA_ESTUDIANTIL_CERRADA", ahora)
	return s.VentanaEstudiantil().CierraEn, nil
}

func (uc *VentanaEstudiantilUseCase) sesionDelDocente(ctx context.Context, sesionID, docenteID string) (*academico.Sesion, error) {
	s, err := uc.sesionRepo.FindByID(ctx, sesionID)
	if err != nil {
		return nil, fmt.Errorf("buscar sesión: %w", err)
	}
	if s == nil {
		return nil, shared.NewNotFoundError("sesión", sesionID)
	}
	if !s.TieneDocente(docenteID) {
		return nil, ErrDocenteNoAutorizado
	}
	return s, nil
}

func (uc *VentanaEstudiantilUseCase) auditar(ctx context.Context, s *academico.Sesion, actorID, accion string, ahora time.Time) {
	if uc.auditoriaRepo == nil {
		return
	}
	v := s.VentanaEstudiantil()
	_ = uc.auditoriaRepo.Create(ctx, &repository.AuditEntry{
		Entidad: "sesiones", EntidadID: s.ID(), Accion: accion, ActorID: actorID,
		ValorNuevo: map[string]interface{}{"abierta": v.Abierta, "abiertaEn": v.AbiertaEn, "cierraEn": v.CierraEn},
		CreadoEn:   ahora,
	})
}
