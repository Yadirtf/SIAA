package reportes

import (
	"context"
	"math"
	"sort"
	"time"

	"github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/domain/geo"
	"github.com/siaa/backend/internal/domain/marcaje"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/repository"
)

// Agrupaciones del reporte de ocupación (US-REP-04 AC-02).
const (
	AgruparAula   = "aula"
	AgruparBloque = "bloque"
	AgruparSede   = "sede"
)

// FiltroOcupacion son los criterios del reporte de ocupación; exige periodo o rango de fechas.
type FiltroOcupacion struct {
	PeriodoID  string `json:"periodoId,omitempty"`
	FacultadID string `json:"facultadId,omitempty"`
	SedeID     string `json:"sedeId,omitempty"`
	BloqueID   string `json:"bloqueId,omitempty"`
	Desde      string `json:"desde,omitempty"`
	Hasta      string `json:"hasta,omitempty"`
	Agrupacion string `json:"agrupacion"` // aula | bloque | sede
}

// FilaOcupacion es el uso real de un aula, bloque o sede (o los totales).
type FilaOcupacion struct {
	ID                  string  `json:"id,omitempty"`
	Nombre              string  `json:"nombre"`
	Bloque              string  `json:"bloque,omitempty"`
	Sede                string  `json:"sede,omitempty"`
	Espacios            int     `json:"espacios"`
	Sesiones            int     `json:"sesiones"`
	SesionesConfirmadas int     `json:"sesionesConfirmadas"`
	HorasProgramadas    float64 `json:"horasProgramadas"`
	HorasConfirmadas    float64 `json:"horasConfirmadas"`
	// PorcentajeUtilizacion = horas con asistencia confirmada / horas programadas.
	PorcentajeUtilizacion float64 `json:"porcentajeUtilizacion"`
}

// ReporteOcupacion es el resultado del reporte de ocupación de espacios (RF-REP-002).
type ReporteOcupacion struct {
	Filtro     FiltroOcupacion `json:"filtro"`
	GeneradoEn time.Time       `json:"generadoEn"`
	Filas      []FilaOcupacion `json:"filas"`
	Totales    FilaOcupacion   `json:"totales"`
}

// OcupacionService calcula la ocupación con las mismas sesiones del reporte de cumplimiento
// (terminadas, sin canceladas ni excluidas, dentro del alcance) y reutiliza su exportación.
type OcupacionService struct {
	base     *Service
	espacios repository.EspacioRepository
	bloques  repository.BloqueRepository
	sedes    repository.SedeRepository
}

// NewOcupacionService crea el servicio de ocupación sobre el servicio de reportes.
func NewOcupacionService(base *Service, espacios repository.EspacioRepository, bloques repository.BloqueRepository, sedes repository.SedeRepository) *OcupacionService {
	return &OcupacionService{base: base, espacios: espacios, bloques: bloques, sedes: sedes}
}

// Calcular obtiene por espacio las horas programadas, las horas con entrada válida del
// docente y el porcentaje de utilización, agregados por aula, bloque o sede.
func (o *OcupacionService) Calcular(ctx context.Context, actor Actor, f FiltroOcupacion) (*ReporteOcupacion, error) {
	if f.Agrupacion == "" {
		f.Agrupacion = AgruparAula
	}
	if f.Agrupacion != AgruparAula && f.Agrupacion != AgruparBloque && f.Agrupacion != AgruparSede {
		return nil, shared.NewValidationError("agrupación inválida; use aula, bloque o sede")
	}
	base := Filtro{PeriodoID: f.PeriodoID, FacultadID: f.FacultadID, Desde: f.Desde, Hasta: f.Hasta}
	if err := validarFiltro(base); err != nil {
		return nil, err
	}
	sesiones, err := o.base.cargarSesiones(ctx, actor, base)
	if err != nil {
		return nil, err
	}
	ids := make([]string, len(sesiones))
	for i, s := range sesiones {
		ids[i] = s.ID()
	}
	entradas, err := o.base.marcajes.ListarConsolidados(ctx, ids, marcaje.TipoEntrada)
	if err != nil {
		return nil, err
	}
	confirmadas := sesionesConfirmadas(sesiones, entradas)

	u := newUbicaciones(o.espacios, o.bloques, o.sedes)
	filas := map[string]*FilaOcupacion{}
	espaciosPorFila := map[string]map[string]bool{}
	for _, s := range sesiones {
		e := u.espacio(ctx, s.EspacioID())
		if e == nil || (f.SedeID != "" && e.SedeID != f.SedeID) || (f.BloqueID != "" && bloqueDe(e) != f.BloqueID) {
			continue
		}
		k, fila := u.filaPara(ctx, f.Agrupacion, e)
		if filas[k] == nil {
			filas[k] = &fila
			espaciosPorFila[k] = map[string]bool{}
		}
		sumarSesion(filas[k], s, confirmadas[s.ID()])
		espaciosPorFila[k][e.ID] = true
	}

	rep := &ReporteOcupacion{Filtro: f, GeneradoEn: o.base.clock.Now(), Filas: make([]FilaOcupacion, 0, len(filas))}
	rep.Totales.Nombre = "TOTAL"
	todos := map[string]bool{}
	for k, fila := range filas {
		fila.Espacios = len(espaciosPorFila[k])
		for id := range espaciosPorFila[k] {
			todos[id] = true
		}
		fila.PorcentajeUtilizacion = utilizacion(fila)
		rep.Filas = append(rep.Filas, *fila)
		rep.Totales.Sesiones += fila.Sesiones
		rep.Totales.SesionesConfirmadas += fila.SesionesConfirmadas
		rep.Totales.HorasProgramadas += fila.HorasProgramadas
		rep.Totales.HorasConfirmadas += fila.HorasConfirmadas
	}
	rep.Totales.Espacios = len(todos)
	rep.Totales.PorcentajeUtilizacion = utilizacion(&rep.Totales)
	sort.SliceStable(rep.Filas, func(i, j int) bool {
		a, b := rep.Filas[i], rep.Filas[j]
		if a.Sede != b.Sede {
			return a.Sede < b.Sede
		}
		if a.Bloque != b.Bloque {
			return a.Bloque < b.Bloque
		}
		return a.Nombre < b.Nombre
	})
	return rep, nil
}

// sesionesConfirmadas marca las sesiones con al menos una entrada docente válida vigente.
func sesionesConfirmadas(sesiones []*academico.Sesion, entradas []*marcaje.Marcaje) map[string]bool {
	porID := make(map[string]*academico.Sesion, len(sesiones))
	for _, s := range sesiones {
		porID[s.ID()] = s
	}
	res := map[string]bool{}
	for _, m := range entradas {
		s := porID[m.SesionID]
		if s == nil || !m.EsExitoso() {
			continue
		}
		if s.TieneDocente(m.UsuarioID) || (m.DocenteID != "" && s.TieneDocente(m.DocenteID)) {
			res[m.SesionID] = true
		}
	}
	return res
}

func sumarSesion(f *FilaOcupacion, s *academico.Sesion, confirmada bool) {
	horas := s.FinProgramado().Sub(s.InicioProgramado()).Hours()
	f.Sesiones++
	f.HorasProgramadas += horas
	if confirmada {
		f.SesionesConfirmadas++
		f.HorasConfirmadas += horas
	}
}

func utilizacion(f *FilaOcupacion) float64 {
	f.HorasProgramadas = math.Round(f.HorasProgramadas*100) / 100
	f.HorasConfirmadas = math.Round(f.HorasConfirmadas*100) / 100
	if f.HorasProgramadas <= 0 {
		return 0
	}
	return math.Round(f.HorasConfirmadas/f.HorasProgramadas*1000) / 10
}

func bloqueDe(e *geo.Espacio) string {
	if e.BloqueID == nil {
		return ""
	}
	return *e.BloqueID
}
