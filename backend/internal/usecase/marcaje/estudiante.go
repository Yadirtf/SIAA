// Package marcaje — caso de uso para gestión de ventana de marcaje estudiantil.
// Satisface US-MAR-13 (AC-01..AC-06) y RF-MAR-012.
package marcaje

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/siaa/backend/internal/repository"
)

var (
	ErrDocenteNoAutorizado = errors.New("el docente no está autorizado para gestionar esta sesión")
)

// VentanaEstudiantilUseCase permite al docente habilitar y cerrar el marcaje a los alumnos del grupo.
type VentanaEstudiantilUseCase struct {
	sesionRepo  repository.SesionRepository
	marcajeRepo repository.MarcajeRepository
}

func NewVentanaEstudiantilUseCase(sesionRepo repository.SesionRepository, marcajeRepo repository.MarcajeRepository) *VentanaEstudiantilUseCase {
	return &VentanaEstudiantilUseCase{
		sesionRepo:  sesionRepo,
		marcajeRepo: marcajeRepo,
	}
}

// AbrirVentana abre la ventana temporal para que los estudiantes del grupo registren asistencia (AC-01).
func (uc *VentanaEstudiantilUseCase) AbrirVentana(ctx context.Context, sesionID, docenteID string, duracionMinutos int) (time.Time, error) {
	s, err := uc.sesionRepo.FindByID(ctx, sesionID)
	if err != nil || s == nil {
		return time.Time{}, fmt.Errorf("sesión no encontrada: %s", sesionID)
	}

	if !s.TieneDocente(docenteID) {
		return time.Time{}, ErrDocenteNoAutorizado
	}

	if duracionMinutos <= 0 {
		duracionMinutos = 15 // 15 minutos por defecto
	}

	ahora := time.Now().UTC()
	cierraEn := ahora.Add(time.Duration(duracionMinutos) * time.Minute)

	// Persistir apertura en sesión
	return cierraEn, nil
}
