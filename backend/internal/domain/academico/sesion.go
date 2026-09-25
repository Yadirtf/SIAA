// Package academico — Entidad de dominio Sesión de clase (EP-04).
// Satisface US-ACA-05 (AC-01..AC-07), RF-ACA-007, RF-PAR-006, SRS §4.2 y §6.4.
// ADR-02: dominio puro sin dependencias de base de datos ni red.
package academico

import (
	"time"

	"github.com/siaa/backend/internal/domain/geo"
	"github.com/siaa/backend/internal/domain/shared"
)

// EstadoSesion define el ciclo de vida de una sesión de clase (SRS §4.2).
type EstadoSesion string

const (
	EstadoSesionProgramada EstadoSesion = "PROGRAMADA"  // AC-07: estado inicial al ser generada
	EstadoSesionEnCurso    EstadoSesion = "EN_CURSO"    // Al abrir ventana y/o primer marcaje
	EstadoSesionRealizada  EstadoSesion = "REALIZADA"   // Marcaje exitoso registrado
	EstadoSesionCancelada  EstadoSesion = "CANCELADA"   // Cancelada administrativamente
	EstadoSesionSinDocente EstadoSesion = "SIN_DOCENTE" // Inasistencia docente consumada
	EstadoSesionExcluida   EstadoSesion = "EXCLUIDA"    // Fecha no lectiva (festivo/paro/receso)
)

// Sesion representa una clase concreta programada en un día, horario y aula específicos.
type Sesion struct {
	id                      string
	periodoID               string
	asignacionID            string
	asignaturaID            string
	grupoID                 string
	docenteIDs              []string
	espacioID               string
	fecha                   string // Formato ISO "YYYY-MM-DD"
	horaInicio              string // Formato "HH:MM"
	horaFin                 string // Formato "HH:MM"
	inicioProgramado        time.Time
	finProgramado           time.Time
	ventanaEntradaAbre      time.Time
	ventanaEntradaCierra    time.Time
	ventanaSalidaAbre       *time.Time
	ventanaSalidaCierra     *time.Time
	estado                  EstadoSesion
	espacioVersionGeometria int
	geometriaSnapshot       *geo.GeoPolygon
	geometriaBufferSnapshot *geo.GeoPolygon
	parametrosCongelados    map[string]interface{} // AC-02, AC-06: congelados e inmutables
	motivoCancelacion       string
	creadoEn                time.Time
	actualizadoEn           time.Time
}

// NuevaSesion construye y valida una nueva sesión con estado PROGRAMADA (AC-01, AC-07).
func NuevaSesion(
	id string,
	periodoID string,
	asignacionID string,
	asignaturaID string,
	grupoID string,
	docenteIDs []string,
	espacioID string,
	fecha string,
	horaInicio string,
	horaFin string,
	inicioProgramado time.Time,
	finProgramado time.Time,
	ventanaEntradaAbre time.Time,
	ventanaEntradaCierra time.Time,
	ventanaSalidaAbre *time.Time,
	ventanaSalidaCierra *time.Time,
	espacioVersionGeometria int,
	geometriaSnapshot *geo.GeoPolygon,
	geometriaBufferSnapshot *geo.GeoPolygon,
	parametrosCongelados map[string]interface{},
	ahora time.Time,
) (*Sesion, error) {
	if periodoID == "" {
		return nil, shared.NewValidationError("El periodo es obligatorio", shared.FieldError{Campo: "periodoId", Error: "REQUERIDO"})
	}
	if asignacionID == "" {
		return nil, shared.NewValidationError("La asignación es obligatoria", shared.FieldError{Campo: "asignacionId", Error: "REQUERIDO"})
	}
	if len(docenteIDs) == 0 {
		return nil, shared.NewValidationError("La sesión debe tener al menos un docente", shared.FieldError{Campo: "docenteIds", Error: "REQUERIDO"})
	}
	if finProgramado.Before(inicioProgramado) || finProgramado.Equal(inicioProgramado) {
		return nil, shared.NewValidationError("La hora de fin debe ser posterior a la de inicio", shared.FieldError{Campo: "finProgramado", Error: "HORAS_INVALIDAS"})
	}

	copiaParams := make(map[string]interface{}, len(parametrosCongelados))
	for k, v := range parametrosCongelados {
		copiaParams[k] = v
	}

	return &Sesion{
		id:                      id,
		periodoID:               periodoID,
		asignacionID:            asignacionID,
		asignaturaID:            asignaturaID,
		grupoID:                 grupoID,
		docenteIDs:              docenteIDs,
		espacioID:               espacioID,
		fecha:                   fecha,
		horaInicio:              horaInicio,
		horaFin:                 horaFin,
		inicioProgramado:        inicioProgramado,
		finProgramado:           finProgramado,
		ventanaEntradaAbre:      ventanaEntradaAbre,
		ventanaEntradaCierra:    ventanaEntradaCierra,
		ventanaSalidaAbre:       ventanaSalidaAbre,
		ventanaSalidaCierra:     ventanaSalidaCierra,
		estado:                  EstadoSesionProgramada,
		espacioVersionGeometria: espacioVersionGeometria,
		geometriaSnapshot:       geometriaSnapshot,
		geometriaBufferSnapshot: geometriaBufferSnapshot,
		parametrosCongelados:    copiaParams,
		creadoEn:                ahora,
		actualizadoEn:           ahora,
	}, nil
}

// ReconstituirSesion reconstituye una sesión desde la capa de persistencia.
func ReconstituirSesion(
	id string,
	periodoID string,
	asignacionID string,
	asignaturaID string,
	grupoID string,
	docenteIDs []string,
	espacioID string,
	fecha string,
	horaInicio string,
	horaFin string,
	inicioProgramado time.Time,
	finProgramado time.Time,
	ventanaEntradaAbre time.Time,
	ventanaEntradaCierra time.Time,
	ventanaSalidaAbre *time.Time,
	ventanaSalidaCierra *time.Time,
	estado EstadoSesion,
	espacioVersionGeometria int,
	geometriaSnapshot *geo.GeoPolygon,
	geometriaBufferSnapshot *geo.GeoPolygon,
	parametrosCongelados map[string]interface{},
	motivoCancelacion string,
	creadoEn time.Time,
	actualizadoEn time.Time,
) *Sesion {
	return &Sesion{
		id:                      id,
		periodoID:               periodoID,
		asignacionID:            asignacionID,
		asignaturaID:            asignaturaID,
		grupoID:                 grupoID,
		docenteIDs:              docenteIDs,
		espacioID:               espacioID,
		fecha:                   fecha,
		horaInicio:              horaInicio,
		horaFin:                 horaFin,
		inicioProgramado:        inicioProgramado,
		finProgramado:           finProgramado,
		ventanaEntradaAbre:      ventanaEntradaAbre,
		ventanaEntradaCierra:    ventanaEntradaCierra,
		ventanaSalidaAbre:       ventanaSalidaAbre,
		ventanaSalidaCierra:     ventanaSalidaCierra,
		estado:                  estado,
		espacioVersionGeometria: espacioVersionGeometria,
		geometriaSnapshot:       geometriaSnapshot,
		geometriaBufferSnapshot: geometriaBufferSnapshot,
		parametrosCongelados:    parametrosCongelados,
		motivoCancelacion:       motivoCancelacion,
		creadoEn:                creadoEn,
		actualizadoEn:           actualizadoEn,
	}
}

// Getters
func (s *Sesion) ID() string           { return s.id }
func (s *Sesion) PeriodoID() string    { return s.periodoID }
func (s *Sesion) AsignacionID() string { return s.asignacionID }
func (s *Sesion) AsignaturaID() string { return s.asignaturaID }
func (s *Sesion) GrupoID() string      { return s.grupoID }
func (s *Sesion) DocenteIDs() []string { return s.docenteIDs }
func (s *Sesion) TieneDocente(id string) bool {
	for _, d := range s.docenteIDs {
		if d == id {
			return true
		}
	}
	return false
}
func (s *Sesion) EspacioID() string                            { return s.espacioID }
func (s *Sesion) Fecha() string                                { return s.fecha }
func (s *Sesion) HoraInicio() string                           { return s.horaInicio }
func (s *Sesion) HoraFin() string                              { return s.horaFin }
func (s *Sesion) InicioProgramado() time.Time                  { return s.inicioProgramado }
func (s *Sesion) FinProgramado() time.Time                     { return s.finProgramado }
func (s *Sesion) VentanaEntradaAbre() time.Time                { return s.ventanaEntradaAbre }
func (s *Sesion) VentanaEntradaCierra() time.Time              { return s.ventanaEntradaCierra }
func (s *Sesion) VentanaSalidaAbre() *time.Time                { return s.ventanaSalidaAbre }
func (s *Sesion) VentanaSalidaCierra() *time.Time              { return s.ventanaSalidaCierra }
func (s *Sesion) Estado() EstadoSesion                         { return s.estado }
func (s *Sesion) EspacioVersionGeometria() int                 { return s.espacioVersionGeometria }
func (s *Sesion) GeometriaSnapshot() *geo.GeoPolygon           { return s.geometriaSnapshot }
func (s *Sesion) GeometriaBufferSnapshot() *geo.GeoPolygon     { return s.geometriaBufferSnapshot }
func (s *Sesion) ParametrosCongelados() map[string]interface{} { return s.parametrosCongelados }
func (s *Sesion) MotivoCancelacion() string                    { return s.motivoCancelacion }
func (s *Sesion) CreadoEn() time.Time                          { return s.creadoEn }
func (s *Sesion) ActualizadoEn() time.Time                     { return s.actualizadoEn }

// Cancelar cancela la sesión con motivo explícito auditado (US-ACA-08).
func (s *Sesion) Cancelar(motivo string, ahora time.Time) error {
	if s.estado == EstadoSesionRealizada {
		return shared.NewValidationError("No se puede cancelar una sesión que ya ha sido realizada", shared.FieldError{
			Campo: "estado", Error: "SESION_YA_REALIZADA",
		})
	}
	s.estado = EstadoSesionCancelada
	s.motivoCancelacion = motivo
	s.actualizadoEn = ahora
	return nil
}

// ReasignarEspacio actualiza el aula asignada para esta sesión puntual y congela la versión de su geometría (US-ACA-06).
func (s *Sesion) ReasignarEspacio(nuevoEspacioID string, versionGeom int, geom, geomBuffer *geo.GeoPolygon, ahora time.Time) {
	s.espacioID = nuevoEspacioID
	s.espacioVersionGeometria = versionGeom
	s.geometriaSnapshot = geom
	s.geometriaBufferSnapshot = geomBuffer
	s.actualizadoEn = ahora
}

// AsignarDocenteReemplazo designa un docente suplente para esta sesión específica (US-ACA-09).
func (s *Sesion) AsignarDocenteReemplazo(nuevoDocenteID string, ahora time.Time) error {
	if s.estado == EstadoSesionCancelada || s.estado == EstadoSesionRealizada {
		return shared.NewValidationError("No se puede asignar suplente a una sesión cancelada o ya realizada", shared.FieldError{
			Campo: "estado", Error: "SESION_NO_MODIFICABLE",
		})
	}
	s.docenteIDs = []string{nuevoDocenteID}
	s.actualizadoEn = ahora
	return nil
}

// EsMarcable comprueba si la hora dada cae dentro de la ventana de entrada de la sesión (SRS §6.4).
func (s *Sesion) EsMarcable(t time.Time) bool {
	if s.estado != EstadoSesionProgramada && s.estado != EstadoSesionEnCurso {
		return false
	}
	return (t.Equal(s.ventanaEntradaAbre) || t.After(s.ventanaEntradaAbre)) &&
		(t.Equal(s.ventanaEntradaCierra) || t.Before(s.ventanaEntradaCierra))
}
