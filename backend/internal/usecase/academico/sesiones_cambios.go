// Package academico — reprogramación de sesiones y reglas comunes a los cambios puntuales
// (US-ACA-06 AC-01, AC-04; US-ACA-09 AC-04).
package academico

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/repository"
)

// longitudMinimaMotivo exige un motivo que explique el cambio, no una sola palabra.
const longitudMinimaMotivo = 5

// CambioSesion acompaña cualquier cambio puntual de una sesión.
type CambioSesion struct {
	Motivo string
	// Confirmar acepta el impacto de modificar una sesión que ya inició (AC-04).
	Confirmar bool
}

// ReprogramacionSesion es la nueva fecha (AAAA-MM-DD) y horas (HH:MM) de la sesión.
type ReprogramacionSesion struct {
	Fecha      string
	HoraInicio string
	HoraFin    string
}

// validarCambio exige motivo y, si la sesión ya inició, confirmación explícita: los marcajes
// existentes no se borran, pero quedan asociados a la sesión modificada.
func validarCambio(sesion *academico.Sesion, cambio CambioSesion, ahora time.Time) error {
	if len(strings.TrimSpace(cambio.Motivo)) < longitudMinimaMotivo {
		return shared.NewValidationError("Indica el motivo del cambio",
			shared.FieldError{Campo: "motivo", Error: "REQUERIDO"})
	}
	if sesion.Iniciada(ahora) && !cambio.Confirmar {
		return &shared.DomainError{Code: shared.ErrConfirmacionRequerida,
			Message: "La sesión ya inició: los marcajes registrados se conservan y quedarán asociados a la sesión modificada. Confirma para continuar."}
	}
	return nil
}

// ReprogramarSesion mueve una sesión futura a otra fecha u hora, verificando choques del
// docente y del aula y las fechas no lectivas; queda auditada con antes y después.
func (s *Service) ReprogramarSesion(ctx context.Context, id string, nueva ReprogramacionSesion, cambio CambioSesion, actor ContextoActor) (*academico.Sesion, error) {
	sesion, err := s.sesionEnAlcance(ctx, id, actor)
	if err != nil {
		return nil, err
	}
	ahora := s.clk.Now()
	if err := validarCambio(sesion, cambio, ahora); err != nil {
		return nil, err
	}
	loc := zonaInstitucional()
	dia, err := time.ParseInLocation("2006-01-02", nueva.Fecha, loc)
	if err != nil {
		return nil, shared.NewValidationError("La fecha debe tener el formato AAAA-MM-DD",
			shared.FieldError{Campo: "fecha", Error: "FORMATO"})
	}
	inicio, fin, err := calcularTiemposSesion(dia, nueva.HoraInicio, nueva.HoraFin, loc)
	if err != nil {
		return nil, shared.NewValidationError("Las horas deben tener el formato HH:MM",
			shared.FieldError{Campo: "horaInicio", Error: "FORMATO"})
	}
	if err := s.verificarFechaLectiva(ctx, sesion, dia); err != nil {
		return nil, err
	}
	if err := s.verificarChoquesSesion(ctx, sesion, nueva.Fecha, inicio, fin); err != nil {
		return nil, err
	}
	antes := map[string]interface{}{"fecha": sesion.Fecha(), "horaInicio": sesion.HoraInicio(), "horaFin": sesion.HoraFin()}
	if err := sesion.Reprogramar(nueva.Fecha, nueva.HoraInicio, nueva.HoraFin, inicio, fin, ahora); err != nil {
		return nil, err
	}
	if err := s.sesionRepo.Update(ctx, sesion); err != nil {
		return nil, fmt.Errorf("guardar sesión reprogramada: %w", err)
	}
	s.auditar(ctx, "sesion", id, "SESION_REPROGRAMADA", actor, antes, map[string]interface{}{
		"fecha": nueva.Fecha, "horaInicio": nueva.HoraInicio, "horaFin": nueva.HoraFin, "motivo": cambio.Motivo,
	})
	s.avisarCambio(ctx, sesion, sesion.DocenteIDs(), "Clase reprogramada",
		fmt.Sprintf("Nueva fecha: %s de %s a %s. Motivo: %s", nueva.Fecha, nueva.HoraInicio, nueva.HoraFin, cambio.Motivo))
	return sesion, nil
}

// verificarFechaLectiva rechaza mover la sesión a un día excluido por el calendario.
func (s *Service) verificarFechaLectiva(ctx context.Context, sesion *academico.Sesion, dia time.Time) error {
	if s.excepcionRepo == nil {
		return nil
	}
	excepciones, err := s.excepcionRepo.ListByRango(ctx, dia, dia.Add(24*time.Hour-time.Second))
	if err != nil {
		return err
	}
	if excluida, motivo := esFechaExcluida(dia, sesion.SedeID(), sesion.FacultadID(), excepciones); excluida {
		return shared.NewValidationError("La fecha no es lectiva: "+motivo, shared.FieldError{Campo: "fecha", Error: "FECHA_NO_LECTIVA"})
	}
	return nil
}

// verificarChoquesSesion comprueba que ni los docentes ni el aula tengan otra sesión vigente
// que se cruce con el nuevo horario (RF-ACA-005).
func (s *Service) verificarChoquesSesion(ctx context.Context, sesion *academico.Sesion, fecha string, inicio, fin time.Time) error {
	filtros := make([]repository.SesionFilter, 0, len(sesion.DocenteIDs())+1)
	for _, d := range sesion.DocenteIDs() {
		filtros = append(filtros, repository.SesionFilter{DocenteID: d, Fecha: fecha})
	}
	if sesion.EspacioID() != "" {
		filtros = append(filtros, repository.SesionFilter{EspacioID: sesion.EspacioID(), Fecha: fecha})
	}
	for _, f := range filtros {
		otras, err := s.sesionRepo.List(ctx, f)
		if err != nil {
			return err
		}
		for _, o := range otras {
			if o.ID() == sesion.ID() || o.Estado() == academico.EstadoSesionCancelada || o.Estado() == academico.EstadoSesionExcluida {
				continue
			}
			if inicio.Before(o.FinProgramado()) && o.InicioProgramado().Before(fin) {
				quien := "el aula"
				if f.DocenteID != "" {
					quien = "el docente"
				}
				return &shared.DomainError{Code: shared.ErrConflictoHorario,
					Message: fmt.Sprintf("Choque de horario: %s ya tiene una clase el %s de %s a %s", quien, o.Fecha(), o.HoraInicio(), o.HoraFin())}
			}
		}
	}
	return nil
}

// zonaInstitucional es la zona horaria de la institución (US-ACA-02 AC-03).
func zonaInstitucional() *time.Location {
	if loc, err := time.LoadLocation("America/Bogota"); err == nil {
		return loc
	}
	return time.FixedZone("COT", -5*3600)
}
