// Package reportes calcula el reporte de cumplimiento docente (RF-REP-001) y lo exporta
// a XLSX y PDF (RF-REP-004). Las justificaciones aprobadas se reflejan sin alterar los
// marcajes originales (RF-JUS-004).
//
//   - cumplimiento.go → filtros, carga por lotes y agregación (este archivo)
//   - calculo.go      → clasificación de cada sesión y porcentajes
//   - exportar.go     → tabla para XLSX/PDF y auditoría de la exportación
package reportes

import (
	"context"
	"fmt"
	"sort"
	"strings"
	"time"

	"github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/domain/justificacion"
	"github.com/siaa/backend/internal/domain/marcaje"
	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/repository"
)

// Filtro son los criterios del reporte; exige periodo o rango de fechas.
type Filtro struct {
	PeriodoID  string `json:"periodoId,omitempty"`
	FacultadID string `json:"facultadId,omitempty"`
	ProgramaID string `json:"programaId,omitempty"`
	DocenteID  string `json:"docenteId,omitempty"`
	Desde      string `json:"desde,omitempty"` // AAAA-MM-DD
	Hasta      string `json:"hasta,omitempty"`
}

// Actor es quien consulta, con su alcance (RF-ROL-003).
type Actor struct {
	UsuarioID string
	RolActivo string
	Alcance   rbac.Alcance
}

// Reporte es el resultado del cálculo de cumplimiento.
type Reporte struct {
	Filtro         Filtro        `json:"filtro"`
	GeneradoEn     time.Time     `json:"generadoEn"`
	Docentes       []FilaDocente `json:"docentes"`
	Totales        FilaDocente   `json:"totales"`
	FalsosRechazos int           `json:"falsosRechazos"` // justificaciones aprobadas por falla técnica
	// UmbralAlerta es el porcentaje_minimo_asistencia efectivo del ámbito (US-PAR-04 AC-01).
	UmbralAlerta float64 `json:"umbralAlerta"`
}

// Service calcula reportes a partir de sesiones, marcajes y justificaciones.
type Service struct {
	sesiones        repository.SesionRepository
	marcajes        repository.MarcajeRepository
	justificaciones repository.JustificacionRepository
	estructura      repository.EstructuraRepository
	usuarios        repository.UsuarioRepository
	auditoria       repository.AuditoriaRepository
	clock           shared.Clock
	periodos        repository.PeriodoRepository
	umbral          func(ctx context.Context, facultadID string) float64
}

// NewService crea el servicio de reportes.
func NewService(
	sesiones repository.SesionRepository,
	marcajes repository.MarcajeRepository,
	justificaciones repository.JustificacionRepository,
	estructura repository.EstructuraRepository,
	usuarios repository.UsuarioRepository,
	auditoria repository.AuditoriaRepository,
	clock shared.Clock,
) *Service {
	return &Service{
		sesiones: sesiones, marcajes: marcajes, justificaciones: justificaciones, estructura: estructura,
		usuarios: usuarios, auditoria: auditoria, clock: clock,
	}
}

// WithPeriodos permite mostrar el nombre del periodo en los archivos exportados.
func (s *Service) WithPeriodos(p repository.PeriodoRepository) *Service {
	s.periodos = p
	return s
}

// WithUmbralAlerta resuelve el porcentaje mínimo de la cascada de parámetros (US-PAR-04 AC-01).
func (s *Service) WithUmbralAlerta(f func(ctx context.Context, facultadID string) float64) *Service {
	s.umbral = f
	return s
}

// Cumplimiento calcula horas programadas, dictadas, tardanzas y ausencias por docente.
func (s *Service) Cumplimiento(ctx context.Context, actor Actor, f Filtro) (*Reporte, error) {
	if err := validarFiltro(f); err != nil {
		return nil, err
	}
	sesiones, err := s.cargarSesiones(ctx, actor, f)
	if err != nil {
		return nil, err
	}
	ids := make([]string, len(sesiones))
	for i, se := range sesiones {
		ids[i] = se.ID()
	}
	entradas, err := s.marcajes.ListarConsolidados(ctx, ids, marcaje.TipoEntrada)
	if err != nil {
		return nil, err
	}
	salidas, err := s.marcajes.ListarConsolidados(ctx, ids, marcaje.TipoSalida)
	if err != nil {
		return nil, err
	}
	aprobadas, _, err := s.justificaciones.Listar(ctx, repository.FiltroJustificaciones{
		SesionIDs: ids, Estado: justificacion.EstadoAprobada,
	}, 0, 0)
	if err != nil {
		return nil, err
	}

	agg := nuevoAgregador(entradas, salidas, aprobadas)
	for _, se := range sesiones {
		for _, docenteID := range se.DocenteIDs() {
			if f.DocenteID != "" && docenteID != f.DocenteID {
				continue
			}
			if actor.Alcance.SoloPropios && docenteID != actor.UsuarioID {
				continue
			}
			agg.sumar(se, docenteID)
		}
	}
	rep := &Reporte{Filtro: f, GeneradoEn: s.clock.Now(), FalsosRechazos: agg.falsosRechazos, UmbralAlerta: 80}
	if s.umbral != nil {
		rep.UmbralAlerta = s.umbral(ctx, f.FacultadID)
	}
	rep.Docentes, rep.Totales = agg.resultado(rep.UmbralAlerta)
	s.completarNombres(ctx, rep.Docentes)
	return rep, nil
}

func validarFiltro(f Filtro) error {
	if f.PeriodoID == "" && (f.Desde == "" || f.Hasta == "") {
		return shared.NewValidationError("indique el periodo o el rango de fechas (desde y hasta)")
	}
	for _, v := range []string{f.Desde, f.Hasta} {
		if v == "" {
			continue
		}
		if _, err := time.Parse("2006-01-02", v); err != nil {
			return shared.NewValidationError(fmt.Sprintf("fecha inválida %q; use AAAA-MM-DD", v))
		}
	}
	return nil
}

// cargarSesiones trae las sesiones ya terminadas del filtro dentro del alcance del actor.
// Las canceladas y las de fechas no lectivas no cuentan como horas programadas.
func (s *Service) cargarSesiones(ctx context.Context, actor Actor, f Filtro) ([]*academico.Sesion, error) {
	filtro := repository.SesionFilter{
		PeriodoID:  f.PeriodoID,
		DocenteID:  f.DocenteID,
		FechaDesde: f.Desde,
		FechaHasta: f.Hasta,
		FacultadID: f.FacultadID,
		Alcance:    repository.FiltroDeAlcance(actor.Alcance),
	}
	if f.ProgramaID != "" {
		asignaturas, err := s.estructura.ListAsignaturas(ctx, f.ProgramaID)
		if err != nil {
			return nil, err
		}
		filtro.AsignaturaIDs = []string{}
		for _, a := range asignaturas {
			filtro.AsignaturaIDs = append(filtro.AsignaturaIDs, a.ID())
		}
	}
	todas, err := s.sesiones.List(ctx, filtro)
	if err != nil {
		return nil, err
	}
	ahora := s.clock.Now()
	var res []*academico.Sesion
	for _, se := range todas {
		if se.Estado() == academico.EstadoSesionCancelada || se.Estado() == academico.EstadoSesionExcluida {
			continue
		}
		if se.FinProgramado().After(ahora) {
			continue
		}
		res = append(res, se)
	}
	return res, nil
}

// completarNombres agrega nombre y documento de cada docente y ordena por nombre.
func (s *Service) completarNombres(ctx context.Context, filas []FilaDocente) {
	for i := range filas {
		if u, err := s.usuarios.FindByID(ctx, filas[i].DocenteID); err == nil && u != nil {
			filas[i].Nombre = strings.TrimSpace(u.Nombre + " " + u.Apellido)
			filas[i].Documento = u.Documento
		}
	}
	sort.SliceStable(filas, func(a, b int) bool { return filas[a].Nombre < filas[b].Nombre })
}
