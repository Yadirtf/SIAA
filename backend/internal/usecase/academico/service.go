// Package academico — casos de uso para la estructura académica, horarios y asignaciones (EP-04).
package academico

import (
	"context"
	"errors"
	"fmt"
	"time"

	domainAca "github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/domain/shared"
	applog "github.com/siaa/backend/internal/platform/log"
	"github.com/siaa/backend/internal/repository"
)

var (
	ErrPeriodoNoEncontrado    = errors.New("periodo no encontrado")
	ErrFacultadNoEncontrada   = errors.New("facultad no encontrada")
	ErrProgramaNoEncontrado   = errors.New("programa no encontrado")
	ErrAsignaturaNoEncontrada = errors.New("asignatura no encontrada")
	ErrGrupoNoEncontrado      = errors.New("grupo no encontrado")
	ErrAsignacionNoEncontrada = errors.New("asignación no encontrada")
	ErrExcepcionNoEncontrada  = errors.New("excepción no encontrada")
	ErrFueraDeAmbitoFacultad  = errors.New("el usuario no tiene alcance sobre la facultad especificada (US-ACA-03 AC-07 ABAC)")
	ErrColisionDetectada      = errors.New("se detectó un conflicto de horarios o solapamiento")
)

type ContextoActor struct {
	UsuarioID string
	Rol       string
	Scopes    []rbac.Scope
}

type Service struct {
	periodoRepo    repository.PeriodoRepository
	estructuraRepo repository.EstructuraRepository
	asignacionRepo repository.AsignacionRepository
	excepcionRepo  repository.CalendarioExcepcionRepository
	usuarioRepo    repository.UsuarioRepository
	espacioRepo    repository.EspacioRepository
	auditoriaRepo  repository.AuditoriaRepository
	clk            shared.Clock
	log            *applog.Logger
}

func NewService(
	periodoRepo repository.PeriodoRepository,
	estructuraRepo repository.EstructuraRepository,
	asignacionRepo repository.AsignacionRepository,
	excepcionRepo repository.CalendarioExcepcionRepository,
	usuarioRepo repository.UsuarioRepository,
	espacioRepo repository.EspacioRepository,
	auditoriaRepo repository.AuditoriaRepository,
	clk shared.Clock,
	log *applog.Logger,
) *Service {
	return &Service{
		periodoRepo:    periodoRepo,
		estructuraRepo: estructuraRepo,
		asignacionRepo: asignacionRepo,
		excepcionRepo:  excepcionRepo,
		usuarioRepo:    usuarioRepo,
		espacioRepo:    espacioRepo,
		auditoriaRepo:  auditoriaRepo,
		clk:            clk,
		log:            log,
	}
}

// ─────────────────────────────────────────────────────────────
// 1. GESTIÓN DE PERIODOS ACADÉMICOS (US-ACA-01)
// ─────────────────────────────────────────────────────────────

type CrearPeriodoCmd struct {
	Codigo        string
	Nombre        string
	FechaInicio   time.Time
	FechaFin      time.Time
	Estado        domainAca.EstadoPeriodo
	SedeID        string
	CodigoExterno *string
}

type ResultadoPeriodo struct {
	Periodo      *domainAca.Periodo
	Advertencias []string
}

func (s *Service) CrearPeriodo(ctx context.Context, actor ContextoActor, cmd CrearPeriodoCmd) (*ResultadoPeriodo, error) {
	ahora := s.clk.Now()
	p, err := domainAca.NuevoPeriodo(
		"",
		cmd.Codigo,
		cmd.Nombre,
		cmd.FechaInicio,
		cmd.FechaFin,
		cmd.Estado,
		cmd.SedeID,
		cmd.CodigoExterno,
		ahora,
	)
	if err != nil {
		return nil, err
	}

	var advertencias []string

	// US-ACA-01 AC-03: Advertencia si se activa un segundo periodo con fechas solapadas en la misma sede
	if p.Estado() == domainAca.EstadoActivo && p.SedeID() != "" {
		solapado, err := s.periodoRepo.FindActivoSolapado(ctx, p.SedeID(), p.FechaInicio(), p.FechaFin(), "")
		if err == nil && solapado != nil {
			advertencias = append(advertencias, fmt.Sprintf("Advertencia: ya existe un periodo ACTIVO (%s) con fechas solapadas para la misma sede (US-ACA-01 AC-03)", solapado.Codigo()))
		}
	}

	if err := s.periodoRepo.Create(ctx, p); err != nil {
		return nil, fmt.Errorf("error al persistir periodo: %w", err)
	}

	s.log.Info("periodo creado", applog.UsuarioID(actor.UsuarioID), applog.Extra(map[string]interface{}{"id": p.ID(), "codigo": p.Codigo()}))
	return &ResultadoPeriodo{Periodo: p, Advertencias: advertencias}, nil
}

func (s *Service) ActualizarPeriodo(ctx context.Context, actor ContextoActor, id string, cmd CrearPeriodoCmd) (*ResultadoPeriodo, error) {
	p, err := s.periodoRepo.GetByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if p == nil {
		return nil, ErrPeriodoNoEncontrado
	}

	// US-ACA-01 AC-02: Periodo en estado cerrado no puede modificarse
	if err := p.PuedeModificar(); err != nil {
		return nil, err
	}

	ahora := s.clk.Now()
	nuevo, err := domainAca.NuevoPeriodo(
		id,
		cmd.Codigo,
		cmd.Nombre,
		cmd.FechaInicio,
		cmd.FechaFin,
		cmd.Estado,
		cmd.SedeID,
		cmd.CodigoExterno,
		ahora,
	)
	if err != nil {
		return nil, err
	}

	var advertencias []string
	if nuevo.Estado() == domainAca.EstadoActivo && nuevo.SedeID() != "" {
		solapado, err := s.periodoRepo.FindActivoSolapado(ctx, nuevo.SedeID(), nuevo.FechaInicio(), nuevo.FechaFin(), id)
		if err == nil && solapado != nil {
			advertencias = append(advertencias, fmt.Sprintf("Advertencia: ya existe un periodo ACTIVO (%s) con fechas solapadas para la misma sede (US-ACA-01 AC-03)", solapado.Codigo()))
		}
	}

	if err := s.periodoRepo.Update(ctx, nuevo); err != nil {
		return nil, err
	}

	s.log.Info("periodo actualizado", applog.UsuarioID(actor.UsuarioID), applog.Extra(map[string]interface{}{"id": id, "codigo": nuevo.Codigo()}))
	return &ResultadoPeriodo{Periodo: nuevo, Advertencias: advertencias}, nil
}

func (s *Service) ObtenerPeriodo(ctx context.Context, id string) (*domainAca.Periodo, error) {
	p, err := s.periodoRepo.GetByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if p == nil {
		return nil, ErrPeriodoNoEncontrado
	}
	return p, nil
}

func (s *Service) ListarPeriodos(ctx context.Context, sedeID string) ([]*domainAca.Periodo, error) {
	if sedeID != "" {
		return s.periodoRepo.ListBySedeID(ctx, sedeID)
	}
	return s.periodoRepo.ListAll(ctx)
}

// ─────────────────────────────────────────────────────────────
// 2. GESTIÓN DE ESTRUCTURA ACADÉMICA (US-ACA-01 AC-04, AC-05)
// ─────────────────────────────────────────────────────────────

// Facultades
func (s *Service) CrearFacultad(ctx context.Context, actor ContextoActor, codigo, nombre, sedeID string, codigoExterno *string) (*domainAca.Facultad, error) {
	f, err := domainAca.NuevaFacultad("", codigo, nombre, sedeID, codigoExterno, s.clk.Now())
	if err != nil {
		return nil, err
	}
	if err := s.estructuraRepo.CreateFacultad(ctx, f); err != nil {
		return nil, err
	}
	return f, nil
}

func (s *Service) ListarFacultades(ctx context.Context, sedeID string) ([]*domainAca.Facultad, error) {
	return s.estructuraRepo.ListFacultades(ctx, sedeID)
}

func (s *Service) EliminarFacultad(ctx context.Context, actor ContextoActor, id string) error {
	// Borrado lógico con trazabilidad (US-ACA-01 AC-05)
	return s.estructuraRepo.DeleteFacultadLogico(ctx, id)
}

// Programas
func (s *Service) CrearPrograma(ctx context.Context, actor ContextoActor, codigo, nombre, facultadID string, codigoExterno *string) (*domainAca.Programa, error) {
	fac, err := s.estructuraRepo.GetFacultadByID(ctx, facultadID)
	if err != nil || fac == nil {
		return nil, ErrFacultadNoEncontrada
	}
	p, err := domainAca.NuevoPrograma("", codigo, nombre, facultadID, codigoExterno, s.clk.Now())
	if err != nil {
		return nil, err
	}
	if err := s.estructuraRepo.CreatePrograma(ctx, p); err != nil {
		return nil, err
	}
	return p, nil
}

func (s *Service) ListarProgramas(ctx context.Context, facultadID string) ([]*domainAca.Programa, error) {
	return s.estructuraRepo.ListProgramas(ctx, facultadID)
}

func (s *Service) EliminarPrograma(ctx context.Context, actor ContextoActor, id string) error {
	return s.estructuraRepo.DeleteProgramaLogico(ctx, id)
}

// Asignaturas
func (s *Service) CrearAsignatura(ctx context.Context, actor ContextoActor, codigo, nombre, programaID string, creditos int, codigoExterno *string) (*domainAca.Asignatura, error) {
	prog, err := s.estructuraRepo.GetProgramaByID(ctx, programaID)
	if err != nil || prog == nil {
		return nil, ErrProgramaNoEncontrado
	}
	a, err := domainAca.NuevaAsignatura("", codigo, nombre, programaID, creditos, codigoExterno, s.clk.Now())
	if err != nil {
		return nil, err
	}
	if err := s.estructuraRepo.CreateAsignatura(ctx, a); err != nil {
		return nil, err
	}
	return a, nil
}

func (s *Service) ListarAsignaturas(ctx context.Context, programaID string) ([]*domainAca.Asignatura, error) {
	return s.estructuraRepo.ListAsignaturas(ctx, programaID)
}

func (s *Service) EliminarAsignatura(ctx context.Context, actor ContextoActor, id string) error {
	return s.estructuraRepo.DeleteAsignaturaLogico(ctx, id)
}

// Grupos
func (s *Service) CrearGrupo(ctx context.Context, actor ContextoActor, numero, asignaturaID, periodoID string, cupo int, codigoExterno *string) (*domainAca.Grupo, error) {
	asig, err := s.estructuraRepo.GetAsignaturaByID(ctx, asignaturaID)
	if err != nil || asig == nil {
		return nil, ErrAsignaturaNoEncontrada
	}
	per, err := s.periodoRepo.GetByID(ctx, periodoID)
	if err != nil || per == nil {
		return nil, ErrPeriodoNoEncontrado
	}
	if err := per.PuedeModificar(); err != nil {
		return nil, err
	}
	g, err := domainAca.NuevoGrupo("", numero, asignaturaID, periodoID, cupo, codigoExterno, s.clk.Now())
	if err != nil {
		return nil, err
	}
	if err := s.estructuraRepo.CreateGrupo(ctx, g); err != nil {
		return nil, err
	}
	return g, nil
}

func (s *Service) ListarGrupos(ctx context.Context, asignaturaID, periodoID string) ([]*domainAca.Grupo, error) {
	return s.estructuraRepo.ListGrupos(ctx, asignaturaID, periodoID)
}

func (s *Service) EliminarGrupo(ctx context.Context, actor ContextoActor, id string) error {
	return s.estructuraRepo.DeleteGrupoLogico(ctx, id)
}

// ─────────────────────────────────────────────────────────────
// 3. GESTIÓN DE ASIGNACIONES (US-ACA-02, US-ACA-03)
// ─────────────────────────────────────────────────────────────

type CrearAsignacionCmd struct {
	PeriodoID          string
	DocenteIDs         []string
	DocenteNombre      string
	GrupoID            string
	AsignaturaID       string
	FacultadID         string
	EspacioID          string
	EspacioNombre      string
	DiaSemana          int
	HoraInicio         string
	HoraFin            string
	ZonaHoraria        string
	Modalidad          domainAca.ModalidadAsignacion
	ParametrosOverride map[string]interface{}
	FechaInicio        time.Time
	FechaFin           time.Time
	CodigoExterno      *string
}

type ResultadoAsignacion struct {
	Asignacion   *domainAca.Asignacion
	Advertencias []string
}

func (s *Service) CrearAsignacion(ctx context.Context, actor ContextoActor, cmd CrearAsignacionCmd) (*ResultadoAsignacion, error) {
	// 1. Validar alcance ABAC del actor si es coordinador (US-ACA-03 AC-07)
	if cmd.FacultadID != "" && (actor.Rol == string(rbac.RolCoordinador) || len(actor.Scopes) > 0) {
		scopes := actor.Scopes
		if len(scopes) == 0 && s.usuarioRepo != nil && actor.UsuarioID != "" {
			if u, err := s.usuarioRepo.FindByID(ctx, actor.UsuarioID); err == nil && u != nil {
				scopes = u.Ambitos
			}
		}
		if len(scopes) > 0 && !rbac.IsInScope(scopes, rbac.ScopeFacultad, cmd.FacultadID) {
			return nil, ErrFueraDeAmbitoFacultad
		}
	}

	// 2. Validar periodo
	periodo, err := s.periodoRepo.GetByID(ctx, cmd.PeriodoID)
	if err != nil || periodo == nil {
		return nil, ErrPeriodoNoEncontrado
	}
	if err := periodo.PuedeModificar(); err != nil {
		return nil, err
	}

	// 3. Construir y validar franja horaria (US-ACA-02)
	franja, franjaAdv, err := domainAca.NuevaFranjaHoraria(cmd.DiaSemana, cmd.HoraInicio, cmd.HoraFin, cmd.ZonaHoraria)
	if err != nil {
		return nil, err
	}

	ahora := s.clk.Now()
	fInicio := cmd.FechaInicio
	if fInicio.IsZero() {
		fInicio = periodo.FechaInicio()
	}
	fFin := cmd.FechaFin
	if fFin.IsZero() {
		fFin = periodo.FechaFin()
	}

	asig, err := domainAca.NuevaAsignacion(
		"",
		cmd.PeriodoID,
		cmd.DocenteIDs,
		cmd.DocenteNombre,
		cmd.GrupoID,
		cmd.AsignaturaID,
		cmd.FacultadID,
		cmd.EspacioID,
		cmd.EspacioNombre,
		franja,
		cmd.Modalidad,
		cmd.ParametrosOverride,
		fInicio,
		fFin,
		cmd.CodigoExterno,
		ahora,
	)
	if err != nil {
		return nil, err
	}

	// 4. Detección de colisiones contra asignaciones activas del periodo (US-ACA-03 AC-02, AC-03, RF-ACA-005)
	existentes, err := s.asignacionRepo.ListByPeriodoID(ctx, cmd.PeriodoID)
	if err != nil {
		return nil, fmt.Errorf("error al verificar colisiones: %w", err)
	}

	if colision := domainAca.DetectarColisiones(existentes, *asig); colision != nil {
		s.log.Warn("colisión horaria rechazada", applog.Extra(map[string]interface{}{"tipo": colision.Tipo, "mensaje": colision.Mensaje}))
		return nil, fmt.Errorf("%w: %s", ErrColisionDetectada, colision.Mensaje)
	}

	var advertencias []string
	advertencias = append(advertencias, franjaAdv...)

	// 5. Advertencia si espacio no tiene geometría capturada (US-ACA-03 AC-04)
	if !asig.ExentaGeoespacial() && asig.EspacioID() != "" {
		espacio, err := s.espacioRepo.FindByID(ctx, asig.EspacioID())
		if err == nil && espacio != nil {
			if espacio.Geometria == nil || len(espacio.Geometria.Coordinates()) == 0 {
				advertencias = append(advertencias, "Advertencia: El espacio asignado no tiene geometría levantada. Las sesiones generadas no podrán validarse espacialmente hasta capturar su geocerca (US-ACA-03 AC-04).")
			}
		}
	}

	if err := s.asignacionRepo.Create(ctx, asig); err != nil {
		return nil, fmt.Errorf("error al persistir asignación: %w", err)
	}

	s.log.Info("asignación creada", applog.UsuarioID(actor.UsuarioID), applog.Extra(map[string]interface{}{"id": asig.ID(), "periodo": asig.PeriodoID(), "grupo": asig.GrupoID()}))
	return &ResultadoAsignacion{
		Asignacion:   asig,
		Advertencias: advertencias,
	}, nil
}

func (s *Service) ListarAsignaciones(ctx context.Context, periodoID string) ([]domainAca.Asignacion, error) {
	return s.asignacionRepo.ListByPeriodoID(ctx, periodoID)
}

func (s *Service) EliminarAsignacion(ctx context.Context, actor ContextoActor, id string) error {
	return s.asignacionRepo.DeleteLogico(ctx, id)
}

// ─────────────────────────────────────────────────────────────
// 4. CALENDARIO DE EXCEPCIONES (US-ACA-04)
// ─────────────────────────────────────────────────────────────

type CrearExcepcionCmd struct {
	Nombre      string
	Tipo        domainAca.TipoExcepcion
	Ambito      domainAca.AmbitoExcepcion
	AmbitoID    string
	FechaInicio time.Time
	FechaFin    time.Time
}

func (s *Service) CrearExcepcion(ctx context.Context, actor ContextoActor, cmd CrearExcepcionCmd) (*domainAca.CalendarioExcepcion, error) {
	exc, err := domainAca.NuevaCalendarioExcepcion(
		"",
		cmd.Nombre,
		cmd.Tipo,
		cmd.Ambito,
		cmd.AmbitoID,
		cmd.FechaInicio,
		cmd.FechaFin,
		s.clk.Now(),
	)
	if err != nil {
		return nil, err
	}

	if err := s.excepcionRepo.Create(ctx, exc); err != nil {
		return nil, fmt.Errorf("error al persistir excepción: %w", err)
	}

	s.log.Info("excepción de calendario creada", applog.UsuarioID(actor.UsuarioID), applog.Extra(map[string]interface{}{"id": exc.ID(), "tipo": exc.Tipo(), "ambito": exc.Ambito()}))
	return exc, nil
}

func (s *Service) ListarExcepciones(ctx context.Context) ([]*domainAca.CalendarioExcepcion, error) {
	return s.excepcionRepo.ListAll(ctx)
}

func (s *Service) EliminarExcepcion(ctx context.Context, actor ContextoActor, id string) error {
	return s.excepcionRepo.DeleteLogico(ctx, id)
}
