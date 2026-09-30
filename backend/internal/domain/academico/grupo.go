package academico

import (
	"errors"
	"strings"
	"time"
)

var (
	ErrGrupoNumeroRequerido     = errors.New("el número o identificador del grupo es requerido")
	ErrGrupoAsignaturaRequerida = errors.New("el grupo debe pertenecer a una asignatura válida")
	ErrGrupoPeriodoRequerido    = errors.New("el grupo debe estar asociado a un periodo académico")
)

// ─────────────────────────────────────────────
// Grupo — US-ACA-01 AC-04
// ─────────────────────────────────────────────

type Grupo struct {
	id            string
	numero        string // e.g. "G01", "1", "A"
	asignaturaID  string
	periodoID     string
	cupo          int
	codigoExterno *string
	borrado       bool
	creadoEn      time.Time
	actualizadoEn time.Time
}

func NuevoGrupo(
	id string,
	numero string,
	asignaturaID string,
	periodoID string,
	cupo int,
	codigoExterno *string,
	ahora time.Time,
) (*Grupo, error) {
	numero = strings.TrimSpace(numero)
	asignaturaID = strings.TrimSpace(asignaturaID)
	periodoID = strings.TrimSpace(periodoID)

	if numero == "" {
		return nil, ErrGrupoNumeroRequerido
	}
	if asignaturaID == "" {
		return nil, ErrGrupoAsignaturaRequerida
	}
	if periodoID == "" {
		return nil, ErrGrupoPeriodoRequerido
	}

	var ext *string
	if codigoExterno != nil {
		t := strings.TrimSpace(*codigoExterno)
		if t != "" {
			ext = &t
		}
	}

	return &Grupo{
		id:            id,
		numero:        numero,
		asignaturaID:  asignaturaID,
		periodoID:     periodoID,
		cupo:          cupo,
		codigoExterno: ext,
		borrado:       false,
		creadoEn:      ahora,
		actualizadoEn: ahora,
	}, nil
}

func ReconstituirGrupo(
	id string,
	numero string,
	asignaturaID string,
	periodoID string,
	cupo int,
	codigoExterno *string,
	borrado bool,
	creadoEn time.Time,
	actualizadoEn time.Time,
) *Grupo {
	return &Grupo{
		id:            id,
		numero:        numero,
		asignaturaID:  asignaturaID,
		periodoID:     periodoID,
		cupo:          cupo,
		codigoExterno: codigoExterno,
		borrado:       borrado,
		creadoEn:      creadoEn,
		actualizadoEn: actualizadoEn,
	}
}

func (g *Grupo) ID() string               { return g.id }
func (g *Grupo) Numero() string           { return g.numero }
func (g *Grupo) AsignaturaID() string     { return g.asignaturaID }
func (g *Grupo) PeriodoID() string        { return g.periodoID }
func (g *Grupo) Cupo() int                { return g.cupo }
func (g *Grupo) CodigoExterno() *string   { return g.codigoExterno }
func (g *Grupo) Borrado() bool            { return g.borrado }
func (g *Grupo) CreadoEn() time.Time      { return g.creadoEn }
func (g *Grupo) ActualizadoEn() time.Time { return g.actualizadoEn }
