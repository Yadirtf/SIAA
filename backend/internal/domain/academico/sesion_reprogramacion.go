package academico

import (
	"time"

	"github.com/siaa/backend/internal/domain/shared"
)

// RanuraOriginal es la fecha y hora con que se generó la sesión. Se conserva al reprogramarla
// para que la generación siga reconociéndola y no cree un duplicado (US-ACA-05 AC-03).
type RanuraOriginal struct {
	Fecha      string
	HoraInicio string
}

// ConRanuraOriginal restablece la ranura original al reconstituir la sesión.
func (s *Sesion) ConRanuraOriginal(r *RanuraOriginal) *Sesion {
	s.ranuraOriginal = r
	return s
}

// RanuraOriginal devuelve la ranura generada (nil si nunca se reprogramó).
func (s *Sesion) RanuraOriginal() *RanuraOriginal { return s.ranuraOriginal }

// Iniciada indica si la sesión ya abrió su ventana de entrada o tiene actividad.
func (s *Sesion) Iniciada(ahora time.Time) bool {
	return s.estado == EstadoSesionEnCurso || s.estado == EstadoSesionRealizada || !ahora.Before(s.ventanaEntradaAbre)
}

// Reprogramar mueve la sesión a otra fecha u hora (US-ACA-06 AC-01). Las ventanas de entrada
// y salida conservan su holgura congelada respecto al nuevo inicio y fin.
func (s *Sesion) Reprogramar(fecha, horaInicio, horaFin string, inicio, fin, ahora time.Time) error {
	switch s.estado {
	case EstadoSesionCancelada, EstadoSesionExcluida, EstadoSesionRealizada, EstadoSesionSinDocente:
		return &shared.DomainError{Code: shared.ErrEstadoInvalido,
			Message: "Solo se reprograma una sesión programada o en curso; esta está " + string(s.estado)}
	}
	if !fin.After(inicio) {
		return shared.NewValidationError("La hora de fin debe ser posterior a la de inicio",
			shared.FieldError{Campo: "horaFin", Error: "HORAS_INVALIDAS"})
	}
	if !inicio.After(ahora) {
		return shared.NewValidationError("La nueva fecha y hora deben ser futuras",
			shared.FieldError{Campo: "fecha", Error: "FECHA_PASADA"})
	}
	if s.ranuraOriginal == nil {
		s.ranuraOriginal = &RanuraOriginal{Fecha: s.fecha, HoraInicio: s.horaInicio}
	}
	abre, cierra := s.ventanaEntradaAbre.Sub(s.inicioProgramado), s.ventanaEntradaCierra.Sub(s.inicioProgramado)
	s.ventanaEntradaAbre, s.ventanaEntradaCierra = inicio.Add(abre), inicio.Add(cierra)
	if s.ventanaSalidaAbre != nil && s.ventanaSalidaCierra != nil {
		a, c := fin.Add(s.ventanaSalidaAbre.Sub(s.finProgramado)), fin.Add(s.ventanaSalidaCierra.Sub(s.finProgramado))
		s.ventanaSalidaAbre, s.ventanaSalidaCierra = &a, &c
	}
	s.fecha, s.horaInicio, s.horaFin = fecha, horaInicio, horaFin
	s.inicioProgramado, s.finProgramado = inicio, fin
	s.ventanaEstudiantil = nil
	s.estado = EstadoSesionProgramada
	s.actualizadoEn = ahora
	return nil
}
