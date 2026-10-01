package academico

import (
	"context"
	"fmt"
	"strings"

	domainAca "github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/domain/shared"
)

var nombresDia = [...]string{"", "lunes", "martes", "miércoles", "jueves", "viernes", "sábado", "domingo"}

// errorColisionLegible convierte el reporte de colisión en un error 409 que explica el choque con
// nombres (docente, aula, asignatura, grupo, día y horas en 12 h), sin identificadores (RNF-USA-005).
// El contexto permite a la interfaz armar su propio mensaje; Cause conserva ErrColisionDetectada.
func (s *Service) errorColisionLegible(ctx context.Context, rep *domainAca.ReporteColision, existentes []domainAca.Asignacion) error {
	var previa *domainAca.Asignacion
	for i := range existentes {
		if existentes[i].ID() == rep.AsignacionPrevia {
			previa = &existentes[i]
			break
		}
	}
	ctxDatos := map[string]string{
		"tipo":       string(rep.Tipo),
		"dia":        nombreDia(rep.DiaSemana),
		"horaInicio": hora12h(rep.HoraInicio),
		"horaFin":    hora12h(rep.HoraFin),
	}
	if previa != nil {
		ctxDatos["asignatura"] = s.nombreAsignatura(ctx, previa.AsignaturaID())
		ctxDatos["grupo"] = s.numeroGrupo(ctx, previa.GrupoID())
		ctxDatos["aula"] = s.nombreAula(ctx, previa.EspacioID(), previa.EspacioNombre())
		ctxDatos["docente"] = s.nombreDocentes(ctx, previa)
	}
	if rep.Tipo == domainAca.ColisionDocente && rep.DocenteConflicto != "" {
		if n := s.nombreUsuario(ctx, rep.DocenteConflicto); n != "" {
			ctxDatos["docente"] = n
		}
	}

	campo := "docenteIds"
	mensaje := mensajeColisionDocente(ctxDatos)
	if rep.Tipo == domainAca.ColisionAula {
		campo = "espacioId"
		mensaje = mensajeColisionAula(ctxDatos)
	}
	return &shared.DomainError{
		Code:     shared.ErrConflictoHorario,
		Message:  mensaje,
		Cause:    ErrColisionDetectada,
		Fields:   []shared.FieldError{{Campo: campo, Error: string(rep.Tipo)}},
		Contexto: ctxDatos,
	}
}

func mensajeColisionDocente(d map[string]string) string {
	quien := valorO(d["docente"], "El docente")
	clase := descripcionClase(d)
	return fmt.Sprintf("%s ya tiene clase el %s de %s a %s%s. Un docente no puede dictar dos clases a la misma hora: cambie el docente, el día o la hora.",
		quien, d["dia"], d["horaInicio"], d["horaFin"], clase)
}

func mensajeColisionAula(d map[string]string) string {
	aula := valorO(d["aula"], "seleccionada")
	clase := descripcionClase(d)
	return fmt.Sprintf("El aula %s ya está ocupada el %s de %s a %s%s. Elija otra aula, otro día u otra hora.",
		aula, d["dia"], d["horaInicio"], d["horaFin"], clase)
}

// descripcionClase arma " (Cálculo I, grupo 01, aula A-201, con Ana Pérez)" con lo que se conozca.
func descripcionClase(d map[string]string) string {
	var partes []string
	if d["asignatura"] != "" {
		partes = append(partes, d["asignatura"])
	}
	if d["grupo"] != "" {
		partes = append(partes, "grupo "+d["grupo"])
	}
	if d["tipo"] == string(domainAca.ColisionDocente) && d["aula"] != "" {
		partes = append(partes, "aula "+d["aula"])
	}
	if d["tipo"] == string(domainAca.ColisionAula) && d["docente"] != "" {
		partes = append(partes, "con "+d["docente"])
	}
	if len(partes) == 0 {
		return ""
	}
	return " (" + strings.Join(partes, ", ") + ")"
}

func valorO(v, defecto string) string {
	if v == "" {
		return defecto
	}
	return v
}

func nombreDia(d int) string {
	if d < 1 || d > 7 {
		return fmt.Sprintf("día %d", d)
	}
	return nombresDia[d]
}

// hora12h convierte "18:30" a "6:30 p. m."; si no es una hora válida la devuelve igual.
func hora12h(hhmm string) string {
	var h, m int
	if _, err := fmt.Sscanf(hhmm, "%d:%d", &h, &m); err != nil || h < 0 || h > 23 || m < 0 || m > 59 {
		return hhmm
	}
	sufijo := "a. m."
	if h >= 12 {
		sufijo = "p. m."
	}
	h12 := h % 12
	if h12 == 0 {
		h12 = 12
	}
	return fmt.Sprintf("%d:%02d %s", h12, m, sufijo)
}
