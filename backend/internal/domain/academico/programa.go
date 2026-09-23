package academico

import (
	"errors"
	"strings"
	"time"
)

var (
	ErrProgramaNombreRequerido   = errors.New("el nombre del programa es requerido")
	ErrProgramaCodigoRequerido   = errors.New("el código del programa es requerido")
	ErrProgramaFacultadRequerida = errors.New("el programa debe pertenecer a una facultad válida")
)

// ─────────────────────────────────────────────
// Programa — US-ACA-01 AC-04
// ─────────────────────────────────────────────

type Programa struct {
	id            string
	codigo        string
	nombre        string
	facultadID    string
	codigoExterno *string
	borrado       bool
	creadoEn      time.Time
	actualizadoEn time.Time
}

func NuevoPrograma(
	id string,
	codigo string,
	nombre string,
	facultadID string,
	codigoExterno *string,
	ahora time.Time,
) (*Programa, error) {
	codigo = strings.TrimSpace(codigo)
	nombre = strings.TrimSpace(nombre)
	facultadID = strings.TrimSpace(facultadID)

	if codigo == "" {
		return nil, ErrProgramaCodigoRequerido
	}
	if nombre == "" {
		return nil, ErrProgramaNombreRequerido
	}
	if facultadID == "" {
		return nil, ErrProgramaFacultadRequerida
	}

	var ext *string
	if codigoExterno != nil {
		t := strings.TrimSpace(*codigoExterno)
		if t != "" {
			ext = &t
		}
	}

	return &Programa{
		id:            id,
		codigo:        codigo,
		nombre:        nombre,
		facultadID:    facultadID,
		codigoExterno: ext,
		borrado:       false,
		creadoEn:      ahora,
		actualizadoEn: ahora,
	}, nil
}

func ReconstituirPrograma(
	id string,
	codigo string,
	nombre string,
	facultadID string,
	codigoExterno *string,
	borrado bool,
	creadoEn time.Time,
	actualizadoEn time.Time,
) *Programa {
	return &Programa{
		id:            id,
		codigo:        codigo,
		nombre:        nombre,
		facultadID:    facultadID,
		codigoExterno: codigoExterno,
		borrado:       borrado,
		creadoEn:      creadoEn,
		actualizadoEn: actualizadoEn,
	}
}

func (p *Programa) ID() string               { return p.id }
func (p *Programa) Codigo() string           { return p.codigo }
func (p *Programa) Nombre() string           { return p.nombre }
func (p *Programa) FacultadID() string       { return p.facultadID }
func (p *Programa) CodigoExterno() *string   { return p.codigoExterno }
func (p *Programa) Borrado() bool            { return p.borrado }
func (p *Programa) CreadoEn() time.Time      { return p.creadoEn }
func (p *Programa) ActualizadoEn() time.Time { return p.actualizadoEn }
