package academico

import (
	"errors"
	"strings"
	"time"
)

var (
	ErrAsignaturaNombreRequerido = errors.New("el nombre de la asignatura es requerido")
	ErrAsignaturaCodigoRequerido = errors.New("el código de la asignatura es requerido")
	ErrAsignaturaProgramaReq     = errors.New("la asignatura debe pertenecer a un programa válido")
)

// ─────────────────────────────────────────────
// Asignatura — US-ACA-01 AC-04
// ─────────────────────────────────────────────

type Asignatura struct {
	id            string
	codigo        string
	nombre        string
	programaID    string
	creditos      int
	codigoExterno *string
	borrado       bool
	creadoEn      time.Time
	actualizadoEn time.Time
}

func NuevaAsignatura(
	id string,
	codigo string,
	nombre string,
	programaID string,
	creditos int,
	codigoExterno *string,
	ahora time.Time,
) (*Asignatura, error) {
	codigo = strings.TrimSpace(codigo)
	nombre = strings.TrimSpace(nombre)
	programaID = strings.TrimSpace(programaID)

	if codigo == "" {
		return nil, ErrAsignaturaCodigoRequerido
	}
	if nombre == "" {
		return nil, ErrAsignaturaNombreRequerido
	}
	if programaID == "" {
		return nil, ErrAsignaturaProgramaReq
	}

	var ext *string
	if codigoExterno != nil {
		t := strings.TrimSpace(*codigoExterno)
		if t != "" {
			ext = &t
		}
	}

	return &Asignatura{
		id:            id,
		codigo:        codigo,
		nombre:        nombre,
		programaID:    programaID,
		creditos:      creditos,
		codigoExterno: ext,
		borrado:       false,
		creadoEn:      ahora,
		actualizadoEn: ahora,
	}, nil
}

func ReconstituirAsignatura(
	id string,
	codigo string,
	nombre string,
	programaID string,
	creditos int,
	codigoExterno *string,
	borrado bool,
	creadoEn time.Time,
	actualizadoEn time.Time,
) *Asignatura {
	return &Asignatura{
		id:            id,
		codigo:        codigo,
		nombre:        nombre,
		programaID:    programaID,
		creditos:      creditos,
		codigoExterno: codigoExterno,
		borrado:       borrado,
		creadoEn:      creadoEn,
		actualizadoEn: actualizadoEn,
	}
}

func (a *Asignatura) ID() string               { return a.id }
func (a *Asignatura) Codigo() string           { return a.codigo }
func (a *Asignatura) Nombre() string           { return a.nombre }
func (a *Asignatura) ProgramaID() string       { return a.programaID }
func (a *Asignatura) Creditos() int            { return a.creditos }
func (a *Asignatura) CodigoExterno() *string   { return a.codigoExterno }
func (a *Asignatura) Borrado() bool            { return a.borrado }
func (a *Asignatura) CreadoEn() time.Time      { return a.creadoEn }
func (a *Asignatura) ActualizadoEn() time.Time { return a.actualizadoEn }
