// Package academico implementa las entidades de dominio y reglas de negocio para
// la estructura académica, periodos, franjas horarias y asignaciones (EP-04).
package academico

import (
	"errors"
	"strings"
	"time"
)

// EstadoPeriodo representa el ciclo de vida de un periodo académico (US-ACA-01 AC-01).
type EstadoPeriodo string

const (
	EstadoPlaneacion EstadoPeriodo = "PLANEACION"
	EstadoActivo     EstadoPeriodo = "ACTIVO"
	EstadoCerrado    EstadoPeriodo = "CERRADO"
)

var (
	ErrPeriodoNombreRequerido = errors.New("el nombre del periodo es requerido")
	ErrPeriodoCodigoRequerido = errors.New("el código del periodo es requerido")
	ErrPeriodoFechasInvalidas = errors.New("la fecha de fin del periodo debe ser posterior a la fecha de inicio")
	ErrPeriodoCerradoModif    = errors.New("no se pueden realizar cambios en un periodo cerrado (US-ACA-01 AC-02)")
	ErrPeriodoEstadoInvalido  = errors.New("estado de periodo no reconocido")
)

// Periodo representa un periodo lectivo institucional (semestre, cuatrimestre, etc.).
type Periodo struct {
	id            string
	codigo        string
	nombre        string
	fechaInicio   time.Time
	fechaFin      time.Time
	estado        EstadoPeriodo
	sedeID        string
	codigoExterno *string
	borrado       bool
	creadoEn      time.Time
	actualizadoEn time.Time
}

// NuevoPeriodo crea una nueva entidad de periodo académico con validaciones de invariantes.
func NuevoPeriodo(
	id string,
	codigo string,
	nombre string,
	fechaInicio time.Time,
	fechaFin time.Time,
	estado EstadoPeriodo,
	sedeID string,
	codigoExterno *string,
	ahora time.Time,
) (*Periodo, error) {
	codigo = strings.TrimSpace(codigo)
	nombre = strings.TrimSpace(nombre)
	sedeID = strings.TrimSpace(sedeID)

	if codigo == "" {
		return nil, ErrPeriodoCodigoRequerido
	}
	if nombre == "" {
		return nil, ErrPeriodoNombreRequerido
	}
	if !fechaFin.After(fechaInicio) {
		return nil, ErrPeriodoFechasInvalidas
	}

	switch estado {
	case EstadoPlaneacion, EstadoActivo, EstadoCerrado:
	default:
		return nil, ErrPeriodoEstadoInvalido
	}

	var ext *string
	if codigoExterno != nil {
		trimmed := strings.TrimSpace(*codigoExterno)
		if trimmed != "" {
			ext = &trimmed
		}
	}

	return &Periodo{
		id:            id,
		codigo:        codigo,
		nombre:        nombre,
		fechaInicio:   fechaInicio,
		fechaFin:      fechaFin,
		estado:        estado,
		sedeID:        sedeID,
		codigoExterno: ext,
		borrado:       false,
		creadoEn:      ahora,
		actualizadoEn: ahora,
	}, nil
}

// ReconstituirPeriodo reconstruye una entidad Periodo desde persistencia.
func ReconstituirPeriodo(
	id string,
	codigo string,
	nombre string,
	fechaInicio time.Time,
	fechaFin time.Time,
	estado EstadoPeriodo,
	sedeID string,
	codigoExterno *string,
	borrado bool,
	creadoEn time.Time,
	actualizadoEn time.Time,
) *Periodo {
	return &Periodo{
		id:            id,
		codigo:        codigo,
		nombre:        nombre,
		fechaInicio:   fechaInicio,
		fechaFin:      fechaFin,
		estado:        estado,
		sedeID:        sedeID,
		codigoExterno: codigoExterno,
		borrado:       borrado,
		creadoEn:      creadoEn,
		actualizadoEn: actualizadoEn,
	}
}

// Getters de la entidad Periodo
func (p *Periodo) ID() string               { return p.id }
func (p *Periodo) Codigo() string           { return p.codigo }
func (p *Periodo) Nombre() string           { return p.nombre }
func (p *Periodo) FechaInicio() time.Time   { return p.fechaInicio }
func (p *Periodo) FechaFin() time.Time      { return p.fechaFin }
func (p *Periodo) Estado() EstadoPeriodo    { return p.estado }
func (p *Periodo) SedeID() string           { return p.sedeID }
func (p *Periodo) CodigoExterno() *string   { return p.codigoExterno }
func (p *Periodo) Borrado() bool            { return p.borrado }
func (p *Periodo) CreadoEn() time.Time      { return p.creadoEn }
func (p *Periodo) ActualizadoEn() time.Time { return p.actualizadoEn }

// PuedeModificar valida si el periodo admite modificaciones (AC-02).
func (p *Periodo) PuedeModificar() error {
	if p.estado == EstadoCerrado {
		return ErrPeriodoCerradoModif
	}
	return nil
}

// CambiarEstado actualiza el estado del periodo respetando las reglas de negocio.
func (p *Periodo) CambiarEstado(nuevo EstadoPeriodo, ahora time.Time) error {
	if p.estado == EstadoCerrado && nuevo != EstadoCerrado {
		return ErrPeriodoCerradoModif
	}
	switch nuevo {
	case EstadoPlaneacion, EstadoActivo, EstadoCerrado:
		p.estado = nuevo
		p.actualizadoEn = ahora
		return nil
	default:
		return ErrPeriodoEstadoInvalido
	}
}

// SeSolapaCon comprueba si dos periodos en la misma sede se solapan en fechas (US-ACA-01 AC-03).
func (p *Periodo) SeSolapaCon(otro *Periodo) bool {
	if p.sedeID != "" && otro.sedeID != "" && p.sedeID != otro.sedeID {
		return false
	}
	// [p.Inicio, p.Fin] se solapa con [otro.Inicio, otro.Fin] si p.Inicio < otro.Fin && otro.Inicio < p.Fin
	return p.fechaInicio.Before(otro.fechaFin) && otro.fechaInicio.Before(p.fechaFin)
}
