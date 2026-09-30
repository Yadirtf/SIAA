package academico

import (
	"errors"
	"strings"
	"time"
)

type ModalidadAsignacion string

const (
	ModalidadPresencial ModalidadAsignacion = "PRESENCIAL"
	ModalidadVirtual    ModalidadAsignacion = "VIRTUAL"
	ModalidadHibrida    ModalidadAsignacion = "HIBRIDA"
)

type EstadoAsignacion string

const (
	AsignacionActiva   EstadoAsignacion = "ACTIVA"
	AsignacionInactiva EstadoAsignacion = "INACTIVA"
)

var (
	ErrAsignacionPeriodoRequerido  = errors.New("el periodo académico es requerido")
	ErrAsignacionDocenteRequerido  = errors.New("se debe especificar al menos un docente")
	ErrAsignacionGrupoRequerido    = errors.New("el grupo es requerido")
	ErrAsignacionEspacioRequerido  = errors.New("el espacio/aula es requerido para modalidades presenciales e híbridas")
	ErrAsignacionModalidadInvalida = errors.New("modalidad de asignación inválida")
)

// Asignacion vincula docente(s), grupo, aula, franja horaria y periodo (US-ACA-03).
type Asignacion struct {
	id                 string
	periodoID          string
	docenteIDs         []string
	docenteNombre      string // Nombre legible para listados directos
	grupoID            string
	asignaturaID       string
	facultadID         string // Para chequeo ABAC de coordinador (AC-07)
	espacioID          string
	espacioNombre      string
	franja             FranjaHoraria
	modalidad          ModalidadAsignacion
	exentaGeoespacial  bool                   // True si modalidad es VIRTUAL (AC-06)
	parametrosOverride map[string]interface{} // Overrides de parámetros de marcaje (AC-05)
	estado             EstadoAsignacion
	fechaInicio        time.Time
	fechaFin           time.Time
	codigoExterno      *string
	borrado            bool
	creadoEn           time.Time
	actualizadoEn      time.Time
}

// NuevaAsignacion valida y crea una nueva asignación académica.
func NuevaAsignacion(
	id string,
	periodoID string,
	docenteIDs []string,
	docenteNombre string,
	grupoID string,
	asignaturaID string,
	facultadID string,
	espacioID string,
	espacioNombre string,
	franja FranjaHoraria,
	modalidad ModalidadAsignacion,
	parametrosOverride map[string]interface{},
	fechaInicio time.Time,
	fechaFin time.Time,
	codigoExterno *string,
	ahora time.Time,
) (*Asignacion, error) {
	periodoID = strings.TrimSpace(periodoID)
	grupoID = strings.TrimSpace(grupoID)
	asignaturaID = strings.TrimSpace(asignaturaID)
	facultadID = strings.TrimSpace(facultadID)
	espacioID = strings.TrimSpace(espacioID)

	if periodoID == "" {
		return nil, ErrAsignacionPeriodoRequerido
	}
	if len(docenteIDs) == 0 {
		return nil, ErrAsignacionDocenteRequerido
	}
	if grupoID == "" {
		return nil, ErrAsignacionGrupoRequerido
	}

	switch modalidad {
	case ModalidadPresencial, ModalidadVirtual, ModalidadHibrida:
	default:
		return nil, ErrAsignacionModalidadInvalida
	}

	// Modalidad virtual no requiere aula física obligatoria y está exenta de geocerca (AC-06)
	exenta := (modalidad == ModalidadVirtual)
	if !exenta && espacioID == "" {
		return nil, ErrAsignacionEspacioRequerido
	}

	if parametrosOverride == nil {
		parametrosOverride = make(map[string]interface{})
	}

	var ext *string
	if codigoExterno != nil {
		t := strings.TrimSpace(*codigoExterno)
		if t != "" {
			ext = &t
		}
	}

	return &Asignacion{
		id:                 id,
		periodoID:          periodoID,
		docenteIDs:         docenteIDs,
		docenteNombre:      strings.TrimSpace(docenteNombre),
		grupoID:            grupoID,
		asignaturaID:       asignaturaID,
		facultadID:         facultadID,
		espacioID:          espacioID,
		espacioNombre:      strings.TrimSpace(espacioNombre),
		franja:             franja,
		modalidad:          modalidad,
		exentaGeoespacial:  exenta,
		parametrosOverride: parametrosOverride,
		estado:             AsignacionActiva,
		fechaInicio:        fechaInicio,
		fechaFin:           fechaFin,
		codigoExterno:      ext,
		borrado:            false,
		creadoEn:           ahora,
		actualizadoEn:      ahora,
	}, nil
}

// ReconstituirAsignacion reconstituye una asignación desde persistencia.
func ReconstituirAsignacion(
	id string,
	periodoID string,
	docenteIDs []string,
	docenteNombre string,
	grupoID string,
	asignaturaID string,
	facultadID string,
	espacioID string,
	espacioNombre string,
	franja FranjaHoraria,
	modalidad ModalidadAsignacion,
	exentaGeoespacial bool,
	parametrosOverride map[string]interface{},
	estado EstadoAsignacion,
	fechaInicio time.Time,
	fechaFin time.Time,
	codigoExterno *string,
	borrado bool,
	creadoEn time.Time,
	actualizadoEn time.Time,
) *Asignacion {
	return &Asignacion{
		id:                 id,
		periodoID:          periodoID,
		docenteIDs:         docenteIDs,
		docenteNombre:      docenteNombre,
		grupoID:            grupoID,
		asignaturaID:       asignaturaID,
		facultadID:         facultadID,
		espacioID:          espacioID,
		espacioNombre:      espacioNombre,
		franja:             franja,
		modalidad:          modalidad,
		exentaGeoespacial:  exentaGeoespacial,
		parametrosOverride: parametrosOverride,
		estado:             estado,
		fechaInicio:        fechaInicio,
		fechaFin:           fechaFin,
		codigoExterno:      codigoExterno,
		borrado:            borrado,
		creadoEn:           creadoEn,
		actualizadoEn:      actualizadoEn,
	}
}

func (a *Asignacion) ID() string                                 { return a.id }
func (a *Asignacion) PeriodoID() string                          { return a.periodoID }
func (a *Asignacion) DocenteIDs() []string                       { return a.docenteIDs }
func (a *Asignacion) DocenteNombre() string                      { return a.docenteNombre }
func (a *Asignacion) GrupoID() string                            { return a.grupoID }
func (a *Asignacion) AsignaturaID() string                       { return a.asignaturaID }
func (a *Asignacion) FacultadID() string                         { return a.facultadID }
func (a *Asignacion) EspacioID() string                          { return a.espacioID }
func (a *Asignacion) EspacioNombre() string                      { return a.espacioNombre }
func (a *Asignacion) Franja() FranjaHoraria                      { return a.franja }
func (a *Asignacion) Modalidad() ModalidadAsignacion             { return a.modalidad }
func (a *Asignacion) ExentaGeoespacial() bool                    { return a.exentaGeoespacial }
func (a *Asignacion) ParametrosOverride() map[string]interface{} { return a.parametrosOverride }
func (a *Asignacion) Estado() EstadoAsignacion                   { return a.estado }
func (a *Asignacion) FechaInicio() time.Time                     { return a.fechaInicio }
func (a *Asignacion) FechaFin() time.Time                        { return a.fechaFin }
func (a *Asignacion) CodigoExterno() *string                     { return a.codigoExterno }
func (a *Asignacion) Borrado() bool                              { return a.borrado }
func (a *Asignacion) CreadoEn() time.Time                        { return a.creadoEn }
func (a *Asignacion) ActualizadoEn() time.Time                   { return a.actualizadoEn }

func (a *Asignacion) ContieneDocente(docenteID string) bool {
	for _, id := range a.docenteIDs {
		if id == docenteID {
			return true
		}
	}
	return false
}
