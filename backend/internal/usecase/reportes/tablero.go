package reportes

import (
	"context"
	"sort"
	"time"

	"github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/domain/marcaje"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/repository"
)

// RefrescoTableroSegundos es el intervalo base sugerido al cliente; el cliente le suma un
// desfase aleatorio para no sincronizar las consultas de todos los tableros (US-REP-03 AC-02).
const RefrescoTableroSegundos = 60

// Tablero es el pulso del día dentro del ámbito del usuario (US-REP-03, RF-REP-005).
type Tablero struct {
	Fecha                string           `json:"fecha"` // AAAA-MM-DD en hora institucional
	GeneradoEn           time.Time        `json:"generadoEn"`
	SesionesDelDia       int              `json:"sesionesDelDia"` // programadas hoy, sin canceladas ni excluidas
	SesionesCanceladas   int              `json:"sesionesCanceladas"`
	SesionesEnCurso      int              `json:"sesionesEnCurso"`
	SesionesFinalizadas  int              `json:"sesionesFinalizadas"`
	Marcajes             ConteoMarcajes   `json:"marcajes"`
	EnCursoSinMarcaje    []SesionSinMarca `json:"sesionesEnCursoSinMarcaje"`
	AlertasActivas       []AlertaActiva   `json:"alertasActivas"`
	RefrescoSugeridoSegs int              `json:"refrescoSugeridoSegundos"`
}

// ConteoMarcajes son los marcajes vigentes (consolidados) de las sesiones del día.
type ConteoMarcajes struct {
	EntradasDocentes    int `json:"entradasDocentes"`
	SalidasDocentes     int `json:"salidasDocentes"`
	EntradasEstudiantes int `json:"entradasEstudiantes"`
	Total               int `json:"total"`
}

// SesionSinMarca es una sesión en curso a la que le falta la entrada válida de un docente (AC-03).
type SesionSinMarca struct {
	SesionID      string    `json:"sesionId"`
	DocenteID     string    `json:"docenteId"`
	Docente       string    `json:"docente"`
	EspacioID     string    `json:"espacioId"`
	Aula          string    `json:"aula"`
	AsignaturaID  string    `json:"asignaturaId"`
	Asignatura    string    `json:"asignatura"`
	HoraInicio    string    `json:"horaInicio"`
	HoraFin       string    `json:"horaFin"`
	Inicio        time.Time `json:"inicioProgramado"`
	Fin           time.Time `json:"finProgramado"`
	MinutosTransc int       `json:"minutosTranscurridos"`
}

// TableroService calcula el tablero solo con las sesiones de hoy (índice por fecha) y sus
// marcajes por sesionId (índice de idempotencia): nunca recorre la colección completa (AC-04).
type TableroService struct {
	sesiones   repository.SesionRepository
	marcajes   repository.MarcajeRepository
	alertas    repository.AlertasRepository
	usuarios   repository.UsuarioRepository
	espacios   repository.EspacioRepository
	estructura repository.EstructuraRepository
	clock      shared.Clock
}

// NewTableroService crea el servicio del tablero en vivo.
func NewTableroService(sesiones repository.SesionRepository, marcajes repository.MarcajeRepository,
	alertas repository.AlertasRepository, usuarios repository.UsuarioRepository,
	espacios repository.EspacioRepository, estructura repository.EstructuraRepository, clock shared.Clock) *TableroService {
	return &TableroService{
		sesiones: sesiones, marcajes: marcajes, alertas: alertas, clock: clock,
		usuarios: usuarios, espacios: espacios, estructura: estructura,
	}
}

// Calcular arma el tablero del día dentro del alcance del actor; facultadID es opcional.
func (t *TableroService) Calcular(ctx context.Context, actor Actor, facultadID string) (*Tablero, error) {
	ahora := t.clock.Now()
	n := nuevosNombres(t.usuarios, t.espacios, t.estructura)
	hoy := shared.FechaLocal(ahora)
	todas, err := t.sesiones.List(ctx, repository.SesionFilter{
		Fecha: hoy, FacultadID: facultadID, Alcance: repository.FiltroDeAlcance(actor.Alcance),
	})
	if err != nil {
		return nil, err
	}
	tab := &Tablero{Fecha: hoy, GeneradoEn: ahora, RefrescoSugeridoSegs: RefrescoTableroSegundos,
		EnCursoSinMarcaje: []SesionSinMarca{}, AlertasActivas: []AlertaActiva{}}
	var vigentes []*academico.Sesion
	for _, s := range todas {
		if s.Estado() == academico.EstadoSesionCancelada || s.Estado() == academico.EstadoSesionExcluida {
			tab.SesionesCanceladas++
			continue
		}
		vigentes = append(vigentes, s)
	}
	tab.SesionesDelDia = len(vigentes)

	ids := make([]string, len(vigentes))
	for i, s := range vigentes {
		ids[i] = s.ID()
	}
	entradas, err := t.marcajes.ListarConsolidados(ctx, ids, marcaje.TipoEntrada)
	if err != nil {
		return nil, err
	}
	salidas, err := t.marcajes.ListarConsolidados(ctx, ids, marcaje.TipoSalida)
	if err != nil {
		return nil, err
	}
	conEntrada := indexar(entradas)
	porSesion := map[string]*academico.Sesion{}
	for _, s := range vigentes {
		porSesion[s.ID()] = s
	}
	tab.Marcajes = contarMarcajes(porSesion, entradas, salidas)

	for _, s := range vigentes {
		switch {
		case !s.FinProgramado().After(ahora):
			tab.SesionesFinalizadas++
		case !s.InicioProgramado().After(ahora):
			tab.SesionesEnCurso++
			for _, d := range s.DocenteIDs() {
				if !exitoso(conEntrada[clave{s.ID(), d}]) {
					tab.EnCursoSinMarcaje = append(tab.EnCursoSinMarcaje, sinMarca(ctx, n, s, d, ahora))
				}
			}
		}
	}
	sort.SliceStable(tab.EnCursoSinMarcaje, func(i, j int) bool {
		return tab.EnCursoSinMarcaje[i].Inicio.Before(tab.EnCursoSinMarcaje[j].Inicio)
	})
	if tab.AlertasActivas, err = t.alertasActivas(ctx, n, actor, facultadID, ahora); err != nil {
		return nil, err
	}
	return tab, nil
}

// contarMarcajes cuenta los marcajes exitosos vigentes de docentes y estudiantes.
func contarMarcajes(sesiones map[string]*academico.Sesion, entradas, salidas []*marcaje.Marcaje) ConteoMarcajes {
	var c ConteoMarcajes
	esDocente := func(m *marcaje.Marcaje) bool {
		s := sesiones[m.SesionID]
		u := m.UsuarioID
		if u == "" {
			u = m.DocenteID
		}
		return s != nil && s.TieneDocente(u)
	}
	for _, m := range entradas {
		if !m.EsExitoso() {
			continue
		}
		if esDocente(m) {
			c.EntradasDocentes++
		} else {
			c.EntradasEstudiantes++
		}
	}
	for _, m := range salidas {
		if m.EsExitoso() && esDocente(m) {
			c.SalidasDocentes++
		}
	}
	c.Total = c.EntradasDocentes + c.SalidasDocentes + c.EntradasEstudiantes
	return c
}

func sinMarca(ctx context.Context, n *nombres, s *academico.Sesion, docenteID string, ahora time.Time) SesionSinMarca {
	return SesionSinMarca{
		SesionID: s.ID(), DocenteID: docenteID, Docente: n.usuario(ctx, docenteID),
		EspacioID: s.EspacioID(), Aula: n.espacio(ctx, s.EspacioID()),
		AsignaturaID: s.AsignaturaID(), Asignatura: n.asignatura(ctx, s.AsignaturaID()),
		HoraInicio: s.HoraInicio(), HoraFin: s.HoraFin(), Inicio: s.InicioProgramado(), Fin: s.FinProgramado(),
		MinutosTransc: int(ahora.Sub(s.InicioProgramado()).Minutes()),
	}
}
