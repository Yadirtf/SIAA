package academico

import (
	"errors"
	"strings"
	"time"
)

type TipoExcepcion string

const (
	ExcepcionFestivo              TipoExcepcion = "FESTIVO"
	ExcepcionReceso               TipoExcepcion = "RECESO"
	ExcepcionJornadaInstitucional TipoExcepcion = "JORNADA_INSTITUCIONAL"
	ExcepcionParo                 TipoExcepcion = "PARO"
)

type AmbitoExcepcion string

const (
	AmbitoGlobal   AmbitoExcepcion = "GLOBAL"
	AmbitoSede     AmbitoExcepcion = "SEDE"
	AmbitoFacultad AmbitoExcepcion = "FACULTAD"
)

var (
	ErrExcepcionNombreRequerido = errors.New("el nombre o motivo de la excepción es requerido")
	ErrExcepcionTipoInvalido    = errors.New("tipo de excepción no reconocido")
	ErrExcepcionAmbitoInvalido  = errors.New("ámbito de excepción no reconocido")
	ErrExcepcionAmbitoIDReq     = errors.New("el ámbito sede o facultad requiere el identificador correspondiente")
	ErrExcepcionFechasInvalidas = errors.New("la fecha de fin no puede ser anterior a la fecha de inicio")
)

// CalendarioExcepcion representa una fecha o rango no lectivo (US-ACA-04).
type CalendarioExcepcion struct {
	id            string
	nombre        string
	tipo          TipoExcepcion
	ambito        AmbitoExcepcion
	ambitoID      string // Vacío para GLOBAL, sedeID o facultadID
	fechaInicio   time.Time
	fechaFin      time.Time
	borrado       bool
	creadoEn      time.Time
	actualizadoEn time.Time
}

func NuevaCalendarioExcepcion(
	id string,
	nombre string,
	tipo TipoExcepcion,
	ambito AmbitoExcepcion,
	ambitoID string,
	fechaInicio time.Time,
	fechaFin time.Time,
	ahora time.Time,
) (*CalendarioExcepcion, error) {
	nombre = strings.TrimSpace(nombre)
	ambitoID = strings.TrimSpace(ambitoID)

	if nombre == "" {
		return nil, ErrExcepcionNombreRequerido
	}

	switch tipo {
	case ExcepcionFestivo, ExcepcionReceso, ExcepcionJornadaInstitucional, ExcepcionParo:
	default:
		return nil, ErrExcepcionTipoInvalido
	}

	switch ambito {
	case AmbitoGlobal:
		ambitoID = ""
	case AmbitoSede, AmbitoFacultad:
		if ambitoID == "" {
			return nil, ErrExcepcionAmbitoIDReq
		}
	default:
		return nil, ErrExcepcionAmbitoInvalido
	}

	if fechaFin.Before(fechaInicio) {
		return nil, ErrExcepcionFechasInvalidas
	}

	return &CalendarioExcepcion{
		id:            id,
		nombre:        nombre,
		tipo:          tipo,
		ambito:        ambito,
		ambitoID:      ambitoID,
		fechaInicio:   fechaInicio,
		fechaFin:      fechaFin,
		borrado:       false,
		creadoEn:      ahora,
		actualizadoEn: ahora,
	}, nil
}

func ReconstituirCalendarioExcepcion(
	id string,
	nombre string,
	tipo TipoExcepcion,
	ambito AmbitoExcepcion,
	ambitoID string,
	fechaInicio time.Time,
	fechaFin time.Time,
	borrado bool,
	creadoEn time.Time,
	actualizadoEn time.Time,
) *CalendarioExcepcion {
	return &CalendarioExcepcion{
		id:            id,
		nombre:        nombre,
		tipo:          tipo,
		ambito:        ambito,
		ambitoID:      ambitoID,
		fechaInicio:   fechaInicio,
		fechaFin:      fechaFin,
		borrado:       borrado,
		creadoEn:      creadoEn,
		actualizadoEn: actualizadoEn,
	}
}

func (e *CalendarioExcepcion) ID() string               { return e.id }
func (e *CalendarioExcepcion) Nombre() string           { return e.nombre }
func (e *CalendarioExcepcion) Tipo() TipoExcepcion      { return e.tipo }
func (e *CalendarioExcepcion) Ambito() AmbitoExcepcion  { return e.ambito }
func (e *CalendarioExcepcion) AmbitoID() string         { return e.ambitoID }
func (e *CalendarioExcepcion) FechaInicio() time.Time   { return e.fechaInicio }
func (e *CalendarioExcepcion) FechaFin() time.Time      { return e.fechaFin }
func (e *CalendarioExcepcion) Borrado() bool            { return e.borrado }
func (e *CalendarioExcepcion) CreadoEn() time.Time      { return e.creadoEn }
func (e *CalendarioExcepcion) ActualizadoEn() time.Time { return e.actualizadoEn }

// AfectaFechaYAmbito determina si la excepción es aplicable a una fecha y ámbito dados (US-ACA-04 AC-02, AC-05).
func (e *CalendarioExcepcion) AfectaFechaYAmbito(fecha time.Time, sedeID string, facultadID string) bool {
	if e.borrado {
		return false
	}

	// Normalizar solo componente de fecha año-mes-día sin sesgo de huso horario
	yF, mF, dF := fecha.Date()
	f := time.Date(yF, mF, dF, 0, 0, 0, 0, time.UTC)
	yIni, mIni, dIni := e.fechaInicio.Date()
	ini := time.Date(yIni, mIni, dIni, 0, 0, 0, 0, time.UTC)
	yFin, mFin, dFin := e.fechaFin.Date()
	fin := time.Date(yFin, mFin, dFin, 23, 59, 59, 999999999, time.UTC)

	if f.Before(ini) || f.After(fin) {
		return false
	}

	switch e.ambito {
	case AmbitoGlobal:
		return true
	case AmbitoSede:
		return e.ambitoID == sedeID
	case AmbitoFacultad:
		return e.ambitoID == facultadID
	default:
		return false
	}
}
