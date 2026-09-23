package academico

import (
	"errors"
	"strings"
	"time"
)

var (
	ErrFacultadNombreRequerido   = errors.New("el nombre de la facultad es requerido")
	ErrFacultadCodigoRequerido   = errors.New("el código de la facultad es requerido")
	ErrProgramaNombreRequerido   = errors.New("el nombre del programa es requerido")
	ErrProgramaCodigoRequerido   = errors.New("el código del programa es requerido")
	ErrProgramaFacultadRequerida = errors.New("el programa debe pertenecer a una facultad válida")
	ErrAsignaturaNombreRequerido = errors.New("el nombre de la asignatura es requerido")
	ErrAsignaturaCodigoRequerido = errors.New("el código de la asignatura es requerido")
	ErrAsignaturaProgramaReq     = errors.New("la asignatura debe pertenecer a un programa válido")
	ErrGrupoNumeroRequerido      = errors.New("el número o identificador del grupo es requerido")
	ErrGrupoAsignaturaRequerida  = errors.New("el grupo debe pertenecer a una asignatura válida")
	ErrGrupoPeriodoRequerido     = errors.New("el grupo debe estar asociado a un periodo académico")
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
