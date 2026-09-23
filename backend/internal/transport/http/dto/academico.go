package dto

import (
	"time"

	domainAca "github.com/siaa/backend/internal/domain/academico"
)

// ─────────────────────────────────────────────
// Periodos
// ─────────────────────────────────────────────

type CrearPeriodoRequest struct {
	Codigo        string `json:"codigo"`
	Nombre        string `json:"nombre"`
	FechaInicio   string `json:"fechaInicio"` // RFC3339 o YYYY-MM-DD
	FechaFin      string `json:"fechaFin"`    // RFC3339 o YYYY-MM-DD
	Estado        string `json:"estado"`      // PLANEACION, ACTIVO, CERRADO
	SedeID        string `json:"sedeId,omitempty"`
	CodigoExterno string `json:"codigoExterno,omitempty"`
}

type PeriodoResponse struct {
	ID            string   `json:"id"`
	Codigo        string   `json:"codigo"`
	Nombre        string   `json:"nombre"`
	FechaInicio   string   `json:"fechaInicio"`
	FechaFin      string   `json:"fechaFin"`
	Estado        string   `json:"estado"`
	SedeID        string   `json:"sedeId,omitempty"`
	CodigoExterno *string  `json:"codigoExterno,omitempty"`
	Advertencias  []string `json:"advertencias,omitempty"`
}

func FromPeriodoDomain(p *domainAca.Periodo, adv []string) PeriodoResponse {
	return PeriodoResponse{
		ID:            p.ID(),
		Codigo:        p.Codigo(),
		Nombre:        p.Nombre(),
		FechaInicio:   p.FechaInicio().Format("2006-01-02"),
		FechaFin:      p.FechaFin().Format("2006-01-02"),
		Estado:        string(p.Estado()),
		SedeID:        p.SedeID(),
		CodigoExterno: p.CodigoExterno(),
		Advertencias:  adv,
	}
}

// ─────────────────────────────────────────────
// Estructura
// ─────────────────────────────────────────────

type CrearFacultadRequest struct {
	Codigo        string `json:"codigo"`
	Nombre        string `json:"nombre"`
	SedeID        string `json:"sedeId,omitempty"`
	CodigoExterno string `json:"codigoExterno,omitempty"`
}

type FacultadResponse struct {
	ID            string  `json:"id"`
	Codigo        string  `json:"codigo"`
	Nombre        string  `json:"nombre"`
	SedeID        string  `json:"sedeId,omitempty"`
	CodigoExterno *string `json:"codigoExterno,omitempty"`
}

func FromFacultadDomain(f *domainAca.Facultad) FacultadResponse {
	return FacultadResponse{
		ID:            f.ID(),
		Codigo:        f.Codigo(),
		Nombre:        f.Nombre(),
		SedeID:        f.SedeID(),
		CodigoExterno: f.CodigoExterno(),
	}
}

type CrearProgramaRequest struct {
	Codigo        string `json:"codigo"`
	Nombre        string `json:"nombre"`
	FacultadID    string `json:"facultadId"`
	CodigoExterno string `json:"codigoExterno,omitempty"`
}

type ProgramaResponse struct {
	ID            string  `json:"id"`
	Codigo        string  `json:"codigo"`
	Nombre        string  `json:"nombre"`
	FacultadID    string  `json:"facultadId"`
	CodigoExterno *string `json:"codigoExterno,omitempty"`
}

func FromProgramaDomain(p *domainAca.Programa) ProgramaResponse {
	return ProgramaResponse{
		ID:            p.ID(),
		Codigo:        p.Codigo(),
		Nombre:        p.Nombre(),
		FacultadID:    p.FacultadID(),
		CodigoExterno: p.CodigoExterno(),
	}
}

type CrearAsignaturaRequest struct {
	Codigo        string `json:"codigo"`
	Nombre        string `json:"nombre"`
	ProgramaID    string `json:"programaId"`
	Creditos      int    `json:"creditos"`
	CodigoExterno string `json:"codigoExterno,omitempty"`
}

type AsignaturaResponse struct {
	ID            string  `json:"id"`
	Codigo        string  `json:"codigo"`
	Nombre        string  `json:"nombre"`
	ProgramaID    string  `json:"programaId"`
	Creditos      int     `json:"creditos"`
	CodigoExterno *string `json:"codigoExterno,omitempty"`
}

func FromAsignaturaDomain(a *domainAca.Asignatura) AsignaturaResponse {
	return AsignaturaResponse{
		ID:            a.ID(),
		Codigo:        a.Codigo(),
		Nombre:        a.Nombre(),
		ProgramaID:    a.ProgramaID(),
		Creditos:      a.Creditos(),
		CodigoExterno: a.CodigoExterno(),
	}
}

type CrearGrupoRequest struct {
	Numero        string `json:"numero"`
	AsignaturaID  string `json:"asignaturaId"`
	PeriodoID     string `json:"periodoId"`
	Cupo          int    `json:"cupo"`
	CodigoExterno string `json:"codigoExterno,omitempty"`
}

type GrupoResponse struct {
	ID            string  `json:"id"`
	Numero        string  `json:"numero"`
	AsignaturaID  string  `json:"asignaturaId"`
	PeriodoID     string  `json:"periodoId"`
	Cupo          int     `json:"cupo"`
	CodigoExterno *string `json:"codigoExterno,omitempty"`
}

func FromGrupoDomain(g *domainAca.Grupo) GrupoResponse {
	return GrupoResponse{
		ID:            g.ID(),
		Numero:        g.Numero(),
		AsignaturaID:  g.AsignaturaID(),
		PeriodoID:     g.PeriodoID(),
		Cupo:          g.Cupo(),
		CodigoExterno: g.CodigoExterno(),
	}
}

// ─────────────────────────────────────────────
// Asignaciones
// ─────────────────────────────────────────────

type FranjaRequest struct {
	DiaSemana   int    `json:"diaSemana"`
	HoraInicio  string `json:"horaInicio"`
	HoraFin     string `json:"horaFin"`
	ZonaHoraria string `json:"zonaHoraria,omitempty"`
}

type CrearAsignacionRequest struct {
	PeriodoID          string                 `json:"periodoId"`
	DocenteIDs         []string               `json:"docenteIds"`
	DocenteNombre      string                 `json:"docenteNombre"`
	GrupoID            string                 `json:"grupoId"`
	AsignaturaID       string                 `json:"asignaturaId"`
	FacultadID         string                 `json:"facultadId"`
	EspacioID          string                 `json:"espacioId"`
	EspacioNombre      string                 `json:"espacioNombre"`
	Franja             FranjaRequest          `json:"franja"`
	Modalidad          string                 `json:"modalidad"` // PRESENCIAL, VIRTUAL, HIBRIDA
	ParametrosOverride map[string]interface{} `json:"parametrosOverride,omitempty"`
	FechaInicio        string                 `json:"fechaInicio,omitempty"`
	FechaFin           string                 `json:"fechaFin,omitempty"`
	CodigoExterno      string                 `json:"codigoExterno,omitempty"`
}

type AsignacionResponse struct {
	ID                 string                 `json:"id"`
	PeriodoID          string                 `json:"periodoId"`
	DocenteIDs         []string               `json:"docenteIds"`
	DocenteNombre      string                 `json:"docenteNombre"`
	GrupoID            string                 `json:"grupoId"`
	AsignaturaID       string                 `json:"asignaturaId"`
	FacultadID         string                 `json:"facultadId"`
	EspacioID          string                 `json:"espacioId,omitempty"`
	EspacioNombre      string                 `json:"espacioNombre,omitempty"`
	Franja             FranjaRequest          `json:"franja"`
	Modalidad          string                 `json:"modalidad"`
	ExentaGeoespacial  bool                   `json:"exentaGeoespacial"`
	ParametrosOverride map[string]interface{} `json:"parametrosOverride,omitempty"`
	Estado             string                 `json:"estado"`
	FechaInicio        string                 `json:"fechaInicio"`
	FechaFin           string                 `json:"fechaFin"`
	CodigoExterno      *string                `json:"codigoExterno,omitempty"`
	Advertencias       []string               `json:"advertencias,omitempty"`
}

func FromAsignacionDomain(a *domainAca.Asignacion, adv []string) AsignacionResponse {
	return AsignacionResponse{
		ID:            a.ID(),
		PeriodoID:     a.PeriodoID(),
		DocenteIDs:    a.DocenteIDs(),
		DocenteNombre: a.DocenteNombre(),
		GrupoID:       a.GrupoID(),
		AsignaturaID:  a.AsignaturaID(),
		FacultadID:    a.FacultadID(),
		EspacioID:     a.EspacioID(),
		EspacioNombre: a.EspacioNombre(),
		Franja: FranjaRequest{
			DiaSemana:   a.Franja().DiaSemana(),
			HoraInicio:  a.Franja().HoraInicio(),
			HoraFin:     a.Franja().HoraFin(),
			ZonaHoraria: a.Franja().ZonaHoraria(),
		},
		Modalidad:          string(a.Modalidad()),
		ExentaGeoespacial:  a.ExentaGeoespacial(),
		ParametrosOverride: a.ParametrosOverride(),
		Estado:             string(a.Estado()),
		FechaInicio:        a.FechaInicio().Format("2006-01-02"),
		FechaFin:           a.FechaFin().Format("2006-01-02"),
		CodigoExterno:      a.CodigoExterno(),
		Advertencias:       adv,
	}
}

// ─────────────────────────────────────────────
// Excepciones
// ─────────────────────────────────────────────

type CrearExcepcionRequest struct {
	Nombre      string `json:"nombre"`
	Tipo        string `json:"tipo"`   // FESTIVO, RECESO, JORNADA_INSTITUCIONAL, PARO
	Ambito      string `json:"ambito"` // GLOBAL, SEDE, FACULTAD
	AmbitoID    string `json:"ambitoId,omitempty"`
	FechaInicio string `json:"fechaInicio"`
	FechaFin    string `json:"fechaFin"`
}

type ExcepcionResponse struct {
	ID          string `json:"id"`
	Nombre      string `json:"nombre"`
	Tipo        string `json:"tipo"`
	Ambito      string `json:"ambito"`
	AmbitoID    string `json:"ambitoId,omitempty"`
	FechaInicio string `json:"fechaInicio"`
	FechaFin    string `json:"fechaFin"`
}

func FromExcepcionDomain(e *domainAca.CalendarioExcepcion) ExcepcionResponse {
	return ExcepcionResponse{
		ID:          e.ID(),
		Nombre:      e.Nombre(),
		Tipo:        string(e.Tipo()),
		Ambito:      string(e.Ambito()),
		AmbitoID:    e.AmbitoID(),
		FechaInicio: e.FechaInicio().Format("2006-01-02"),
		FechaFin:    e.FechaFin().Format("2006-01-02"),
	}
}

func ParseFechaFlexible(s string) (time.Time, error) {
	if t, err := time.Parse(time.RFC3339, s); err == nil {
		return t, nil
	}
	return time.Parse("2006-01-02", s)
}
