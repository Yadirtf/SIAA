package marcaje

import (
	"context"
	"math"
	"sort"
	"strings"
	"time"

	"github.com/siaa/backend/internal/domain/academico"
	domainMarcaje "github.com/siaa/backend/internal/domain/marcaje"
	"github.com/siaa/backend/internal/domain/parametro"
	"github.com/siaa/backend/internal/repository"
)

// umbralAsistenciaPorDefecto aplica si la sesión no congeló porcentaje_minimo_asistencia.
const umbralAsistenciaPorDefecto = 80

// AsistenciaDTO es el acumulado de un estudiante en un grupo (US-MAR-13 AC-05, US-REP-05).
// Cuenta las sesiones ya terminadas que se dictaron (no canceladas, excluidas ni sin docente).
type AsistenciaDTO struct {
	EstudianteID string  `json:"estudianteId,omitempty"`
	Nombre       string  `json:"nombre,omitempty"`
	GrupoID      string  `json:"grupoId"`
	Grupo        string  `json:"grupo"`
	AsignaturaID string  `json:"asignaturaId"`
	Asignatura   string  `json:"asignatura"`
	Dictadas     int     `json:"sesionesDictadas"`
	Asistidas    int     `json:"sesionesAsistidas"`
	Porcentaje   float64 `json:"porcentaje"`
	Umbral       int     `json:"umbral"`
	BajoUmbral   bool    `json:"bajoUmbral"`
}

// AsistenciaEstudianteUseCase calcula el porcentaje de asistencia estudiantil con la misma
// regla para la app del estudiante y el reporte del docente (US-REP-05 AC-03).
type AsistenciaEstudianteUseCase struct {
	sesiones repository.SesionRepository
	marcajes repository.MarcajeRepository
	grupos   repository.GrupoEstudiantesRepository
	nombres  *SesionActivaUseCase
	reloj    func() time.Time
}

func NewAsistenciaEstudianteUseCase(s repository.SesionRepository, m repository.MarcajeRepository,
	g repository.GrupoEstudiantesRepository, nombres *SesionActivaUseCase) *AsistenciaEstudianteUseCase {
	return &AsistenciaEstudianteUseCase{sesiones: s, marcajes: m, grupos: g, nombres: nombres,
		reloj: func() time.Time { return time.Now().UTC() }}
}

// WithReloj fija el reloj (pruebas).
func (uc *AsistenciaEstudianteUseCase) WithReloj(r func() time.Time) *AsistenciaEstudianteUseCase {
	uc.reloj = r
	return uc
}

// DelEstudiante devuelve el acumulado por asignatura de los grupos que integra el estudiante.
func (uc *AsistenciaEstudianteUseCase) DelEstudiante(ctx context.Context, estudianteID string) ([]AsistenciaDTO, error) {
	grupos, err := uc.grupos.GruposDeEstudiante(ctx, estudianteID)
	if err != nil {
		return nil, err
	}
	res := make([]AsistenciaDTO, 0, len(grupos))
	for _, g := range grupos {
		filas, err := uc.calcular(ctx, g, []string{estudianteID})
		if err != nil {
			return nil, err
		}
		if len(filas) > 0 {
			filas[0].EstudianteID = ""
			res = append(res, filas[0])
		}
	}
	sort.SliceStable(res, func(i, j int) bool { return strings.ToLower(res[i].Asignatura) < strings.ToLower(res[j].Asignatura) })
	return res, nil
}

// DelGrupo devuelve el acumulado de cada integrante del grupo.
func (uc *AsistenciaEstudianteUseCase) DelGrupo(ctx context.Context, grupoID string) ([]AsistenciaDTO, error) {
	ids, err := uc.grupos.Listar(ctx, grupoID)
	if err != nil {
		return nil, err
	}
	return uc.calcular(ctx, grupoID, ids)
}

func (uc *AsistenciaEstudianteUseCase) calcular(ctx context.Context, grupoID string, estudiantes []string) ([]AsistenciaDTO, error) {
	sesiones, err := uc.sesiones.List(ctx, repository.SesionFilter{GrupoIDs: []string{grupoID}})
	if err != nil {
		return nil, err
	}
	ahora := uc.reloj()
	base := AsistenciaDTO{GrupoID: grupoID, Umbral: umbralAsistenciaPorDefecto}
	ids := make([]string, 0, len(sesiones))
	for _, s := range sesiones {
		if base.AsignaturaID == "" {
			base.AsignaturaID = s.AsignaturaID()
		}
		if umbral, ok := aEntero(s.ParametrosCongelados()[string(parametro.ClavePorcentajeMinimoAsistencia)]); ok {
			base.Umbral = umbral
		}
		if sesionDictada(s, ahora) {
			ids = append(ids, s.ID())
		}
	}
	base.Dictadas = len(ids)
	if uc.nombres != nil && base.AsignaturaID != "" {
		base.Asignatura = uc.nombres.nombreAsignatura(ctx, base.AsignaturaID)
		base.Grupo = uc.nombres.numeroGrupo(ctx, grupoID)
	}
	asistidas := map[string]int{}
	if len(ids) > 0 {
		entradas, err := uc.marcajes.ListarConsolidados(ctx, ids, domainMarcaje.TipoEntrada)
		if err != nil {
			return nil, err
		}
		for _, m := range entradas {
			if m.EsExitoso() {
				asistidas[m.UsuarioID]++
			}
		}
	}
	res := make([]AsistenciaDTO, 0, len(estudiantes))
	for _, id := range estudiantes {
		fila := base
		fila.EstudianteID = id
		fila.Asistidas = asistidas[id]
		fila.Porcentaje = 100
		if fila.Dictadas > 0 {
			fila.Porcentaje = math.Round(float64(fila.Asistidas)*1000/float64(fila.Dictadas)) / 10
		}
		fila.BajoUmbral = fila.Dictadas > 0 && fila.Porcentaje < float64(fila.Umbral)
		res = append(res, fila)
	}
	return res, nil
}

// sesionDictada: terminó y se dictó (cuenta para el porcentaje).
func sesionDictada(s *academico.Sesion, ahora time.Time) bool {
	switch s.Estado() {
	case academico.EstadoSesionCancelada, academico.EstadoSesionExcluida, academico.EstadoSesionSinDocente:
		return false
	}
	return s.FinProgramado().Before(ahora)
}
