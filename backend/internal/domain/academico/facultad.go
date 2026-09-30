package academico

import (
	"errors"
	"strings"
	"time"
)

var (
	ErrFacultadNombreRequerido = errors.New("el nombre de la facultad es requerido")
	ErrFacultadCodigoRequerido = errors.New("el código de la facultad es requerido")
)

// ─────────────────────────────────────────────
// Facultad — US-ACA-01 AC-04
// ─────────────────────────────────────────────

type Facultad struct {
	id            string
	codigo        string
	nombre        string
	sedeID        string
	codigoExterno *string
	borrado       bool
	creadoEn      time.Time
	actualizadoEn time.Time
}

func NuevaFacultad(
	id string,
	codigo string,
	nombre string,
	sedeID string,
	codigoExterno *string,
	ahora time.Time,
) (*Facultad, error) {
	codigo = strings.TrimSpace(codigo)
	nombre = strings.TrimSpace(nombre)
	sedeID = strings.TrimSpace(sedeID)

	if codigo == "" {
		return nil, ErrFacultadCodigoRequerido
	}
	if nombre == "" {
		return nil, ErrFacultadNombreRequerido
	}

	var ext *string
	if codigoExterno != nil {
		t := strings.TrimSpace(*codigoExterno)
		if t != "" {
			ext = &t
		}
	}

	return &Facultad{
		id:            id,
		codigo:        codigo,
		nombre:        nombre,
		sedeID:        sedeID,
		codigoExterno: ext,
		borrado:       false,
		creadoEn:      ahora,
		actualizadoEn: ahora,
	}, nil
}

func ReconstituirFacultad(
	id string,
	codigo string,
	nombre string,
	sedeID string,
	codigoExterno *string,
	borrado bool,
	creadoEn time.Time,
	actualizadoEn time.Time,
) *Facultad {
	return &Facultad{
		id:            id,
		codigo:        codigo,
		nombre:        nombre,
		sedeID:        sedeID,
		codigoExterno: codigoExterno,
		borrado:       borrado,
		creadoEn:      creadoEn,
		actualizadoEn: actualizadoEn,
	}
}

func (f *Facultad) ID() string               { return f.id }
func (f *Facultad) Codigo() string           { return f.codigo }
func (f *Facultad) Nombre() string           { return f.nombre }
func (f *Facultad) SedeID() string           { return f.sedeID }
func (f *Facultad) CodigoExterno() *string   { return f.codigoExterno }
func (f *Facultad) Borrado() bool            { return f.borrado }
func (f *Facultad) CreadoEn() time.Time      { return f.creadoEn }
func (f *Facultad) ActualizadoEn() time.Time { return f.actualizadoEn }
