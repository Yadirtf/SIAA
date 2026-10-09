package reportes

import (
	"context"
	"math"
	"sort"
	"strings"
	"time"

	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/repository"
	usecaseMarcaje "github.com/siaa/backend/internal/usecase/marcaje"
)

// CalculadoraAsistencia es el cálculo que también usa GET /me/asistencia; reutilizarlo
// garantiza que el docente y el estudiante vean exactamente el mismo porcentaje (US-REP-05 AC-03).
type CalculadoraAsistencia interface {
	DelGrupo(ctx context.Context, grupoID string) ([]usecaseMarcaje.AsistenciaDTO, error)
}

// FilaEstudiante es el acumulado de un estudiante del grupo.
type FilaEstudiante struct {
	EstudianteID string  `json:"estudianteId"`
	Nombre       string  `json:"nombre"`
	Documento    string  `json:"documento,omitempty"`
	Dictadas     int     `json:"sesionesDictadas"`
	Asistidas    int     `json:"sesionesAsistidas"`
	Porcentaje   float64 `json:"porcentaje"`
	BajoUmbral   bool    `json:"bajoUmbral"`
}

// ReporteAsistenciaGrupo es el porcentaje por estudiante y el promedio del grupo (US-REP-05 AC-01).
type ReporteAsistenciaGrupo struct {
	GrupoID          string           `json:"grupoId"`
	Grupo            string           `json:"grupo"`
	AsignaturaID     string           `json:"asignaturaId"`
	Asignatura       string           `json:"asignatura"`
	PeriodoID        string           `json:"periodoId"`
	GeneradoEn       time.Time        `json:"generadoEn"`
	Umbral           int              `json:"umbral"`
	SesionesDictadas int              `json:"sesionesDictadas"`
	PromedioGrupo    float64          `json:"promedioGrupo"`
	BajoUmbral       int              `json:"estudiantesBajoUmbral"`
	Estudiantes      []FilaEstudiante `json:"estudiantes"`
}

// AsistenciaGrupoService arma el reporte de asistencia estudiantil de un grupo.
type AsistenciaGrupoService struct {
	calculo    CalculadoraAsistencia
	sesiones   repository.SesionRepository
	estructura repository.EstructuraRepository
	usuarios   repository.UsuarioRepository
	clock      shared.Clock
}

// NewAsistenciaGrupoService crea el servicio del reporte de asistencia estudiantil.
func NewAsistenciaGrupoService(calculo CalculadoraAsistencia, sesiones repository.SesionRepository,
	estructura repository.EstructuraRepository, usuarios repository.UsuarioRepository, clock shared.Clock) *AsistenciaGrupoService {
	return &AsistenciaGrupoService{calculo: calculo, sesiones: sesiones, estructura: estructura, usuarios: usuarios, clock: clock}
}

// DelGrupo devuelve el reporte si el actor es docente del grupo o tiene el grupo en su ámbito.
func (s *AsistenciaGrupoService) DelGrupo(ctx context.Context, actor Actor, grupoID string) (*ReporteAsistenciaGrupo, error) {
	if strings.TrimSpace(grupoID) == "" {
		return nil, shared.NewValidationError("indique el grupo (grupoId)")
	}
	g, err := s.estructura.GetGrupoByID(ctx, grupoID)
	if err != nil || g == nil {
		return nil, shared.NewNotFoundError("grupo", grupoID)
	}
	if err := s.verificarAcceso(ctx, actor, grupoID); err != nil {
		return nil, err
	}
	filas, err := s.calculo.DelGrupo(ctx, grupoID)
	if err != nil {
		return nil, err
	}
	rep := &ReporteAsistenciaGrupo{
		GrupoID: grupoID, Grupo: g.Numero(), AsignaturaID: g.AsignaturaID(), PeriodoID: g.PeriodoID(),
		GeneradoEn: s.clock.Now(), Umbral: 80, Estudiantes: make([]FilaEstudiante, 0, len(filas)),
	}
	if a, err := s.estructura.GetAsignaturaByID(ctx, g.AsignaturaID()); err == nil && a != nil {
		rep.Asignatura = a.Nombre()
	}
	suma := 0.0
	for _, f := range filas {
		rep.Umbral, rep.SesionesDictadas = f.Umbral, f.Dictadas
		fila := FilaEstudiante{EstudianteID: f.EstudianteID, Nombre: f.EstudianteID, Dictadas: f.Dictadas,
			Asistidas: f.Asistidas, Porcentaje: f.Porcentaje, BajoUmbral: f.BajoUmbral}
		if u, err := s.usuarios.FindByID(ctx, f.EstudianteID); err == nil && u != nil {
			fila.Nombre = strings.TrimSpace(u.Nombre + " " + u.Apellido)
			fila.Documento = u.Documento
		}
		if fila.BajoUmbral {
			rep.BajoUmbral++
		}
		suma += f.Porcentaje
		rep.Estudiantes = append(rep.Estudiantes, fila)
	}
	if len(filas) > 0 {
		rep.PromedioGrupo = math.Round(suma/float64(len(filas))*10) / 10
	}
	sort.SliceStable(rep.Estudiantes, func(i, j int) bool {
		return strings.ToLower(rep.Estudiantes[i].Nombre) < strings.ToLower(rep.Estudiantes[j].Nombre)
	})
	return rep, nil
}

// verificarAcceso: el docente solo ve los grupos en los que dicta (alcance de registros
// propios sobre docenteIds); el coordinador, los grupos con sesiones en su sede o facultad.
func (s *AsistenciaGrupoService) verificarAcceso(ctx context.Context, actor Actor, grupoID string) error {
	if actor.Alcance.Global {
		return nil
	}
	sesiones, err := s.sesiones.List(ctx, repository.SesionFilter{
		GrupoIDs: []string{grupoID}, Alcance: repository.FiltroDeAlcance(actor.Alcance),
	})
	if err != nil {
		return err
	}
	if len(sesiones) == 0 {
		return shared.NewScopeError()
	}
	return nil
}
