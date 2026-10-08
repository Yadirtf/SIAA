package academico

import (
	"time"

	"github.com/siaa/backend/internal/domain/shared"
)

// VentanaEstudiantil es el intervalo en el que los estudiantes del grupo pueden marcar
// (US-MAR-13 AC-01). La abre y la cierra el docente de la sesión.
type VentanaEstudiantil struct {
	Abierta   bool
	AbiertaEn time.Time
	CierraEn  time.Time
}

// ConVentanaEstudiantil restablece la ventana guardada al reconstituir la sesión.
func (s *Sesion) ConVentanaEstudiantil(v *VentanaEstudiantil) *Sesion {
	s.ventanaEstudiantil = v
	return s
}

// VentanaEstudiantil devuelve la ventana estudiantil (nil si nunca se abrió).
func (s *Sesion) VentanaEstudiantil() *VentanaEstudiantil { return s.ventanaEstudiantil }

// VentanaEstudiantilVigente indica si en este instante los estudiantes pueden marcar.
func (s *Sesion) VentanaEstudiantilVigente(ahora time.Time) bool {
	v := s.ventanaEstudiantil
	return v != nil && v.Abierta && !ahora.Before(v.AbiertaEn) && !ahora.After(v.CierraEn)
}

// AbrirVentanaEstudiantil habilita el marcaje estudiantil durante la duración dada, sin pasar
// del fin de la clase. Solo se abre en una sesión vigente: desde que abre la ventana de
// entrada hasta el fin programado.
func (s *Sesion) AbrirVentanaEstudiantil(ahora time.Time, duracion time.Duration) error {
	if s.estado == EstadoSesionCancelada || s.estado == EstadoSesionExcluida {
		return conflictoSesion("La sesión está cancelada; no se puede abrir el marcaje de estudiantes")
	}
	if ahora.Before(s.ventanaEntradaAbre) || ahora.After(s.finProgramado) {
		return conflictoSesion("Solo puedes abrir el marcaje de estudiantes mientras la sesión está en curso")
	}
	cierra := ahora.Add(duracion)
	if cierra.After(s.finProgramado) {
		cierra = s.finProgramado
	}
	s.ventanaEstudiantil = &VentanaEstudiantil{Abierta: true, AbiertaEn: ahora, CierraEn: cierra}
	s.actualizadoEn = ahora
	return nil
}

// CerrarVentanaEstudiantil termina la ventana en este instante.
func (s *Sesion) CerrarVentanaEstudiantil(ahora time.Time) error {
	v := s.ventanaEstudiantil
	if v == nil || !v.Abierta {
		return conflictoSesion("El marcaje de estudiantes no está abierto")
	}
	cierre := ahora
	if v.CierraEn.Before(cierre) {
		cierre = v.CierraEn
	}
	s.ventanaEstudiantil = &VentanaEstudiantil{Abierta: false, AbiertaEn: v.AbiertaEn, CierraEn: cierre}
	s.actualizadoEn = ahora
	return nil
}

func conflictoSesion(msg string) error {
	return &shared.DomainError{Code: shared.ErrConflictoUnicidad, Message: msg}
}
