// Package geo — casos de uso para la jerarquía física de espacios (US-GEO-01).
// Implementa reglas de negocio, validaciones y auditoría según el backlog y SRS.
package geo

import (
	"context"
	"fmt"
	"strings"

	"github.com/siaa/backend/internal/domain/geo"
	"github.com/siaa/backend/internal/domain/shared"
	applog "github.com/siaa/backend/internal/platform/log"
	"github.com/siaa/backend/internal/repository"
)

// Service orquesta la lógica de negocio para sedes, bloques y espacios.
type Service struct {
	sedeRepo      repository.SedeRepository
	bloqueRepo    repository.BloqueRepository
	espacioRepo   repository.EspacioRepository
	sesionChecker repository.SesionFutureChecker
	auditoriaRepo repository.AuditoriaRepository
	clk           shared.Clock
	log           *applog.Logger
}

// NewService crea una nueva instancia del servicio de cartografía y jerarquía física.
func NewService(
	sedeRepo repository.SedeRepository,
	bloqueRepo repository.BloqueRepository,
	espacioRepo repository.EspacioRepository,
	sesionChecker repository.SesionFutureChecker,
	auditoriaRepo repository.AuditoriaRepository,
	clk shared.Clock,
	log *applog.Logger,
) *Service {
	return &Service{
		sedeRepo:      sedeRepo,
		bloqueRepo:    bloqueRepo,
		espacioRepo:   espacioRepo,
		sesionChecker: sesionChecker,
		auditoriaRepo: auditoriaRepo,
		clk:           clk,
		log:           log,
	}
}

// ─────────────────────────────────────────────────────────────
// SEDES
// ─────────────────────────────────────────────────────────────

func (s *Service) CrearSede(ctx context.Context, cmd CrearSedeCmd) (*geo.Sede, error) {
	if err := geo.ValidarSede(cmd.Codigo, cmd.Nombre); err != nil {
		return nil, err
	}

	existente, err := s.sedeRepo.FindByCodigo(ctx, cmd.Codigo)
	if err != nil {
		return nil, fmt.Errorf("verificar codigo sede: %w", err)
	}
	if existente != nil {
		return nil, &shared.DomainError{
			Code:    shared.ErrConflictoUnicidad,
			Message: fmt.Sprintf("Ya existe una sede con el código '%s'", cmd.Codigo),
		}
	}

	now := s.clk.Now()
	sede := &geo.Sede{
		Codigo:        cmd.Codigo,
		Nombre:        cmd.Nombre,
		Direccion:     cmd.Direccion,
		Activo:        true,
		Eliminado:     false,
		CreadoEn:      now,
		ActualizadoEn: now,
	}

	if err := s.sedeRepo.Create(ctx, sede); err != nil {
		return nil, fmt.Errorf("guardar sede: %w", err)
	}

	s.auditar(ctx, "sede", sede.ID, "SEDE_CREADA", cmd.Actor, nil, sede)
	return sede, nil
}

func (s *Service) ListarSedes(ctx context.Context) ([]*geo.Sede, error) {
	return s.sedeRepo.List(ctx)
}

func (s *Service) ObtenerSedePorID(ctx context.Context, id string) (*geo.Sede, error) {
	sede, err := s.sedeRepo.FindByID(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("obtener sede: %w", err)
	}
	if sede == nil {
		return nil, shared.NewNotFoundError("Sede", id)
	}
	return sede, nil
}

// ─────────────────────────────────────────────────────────────
// BLOQUES
// ─────────────────────────────────────────────────────────────

func (s *Service) CrearBloque(ctx context.Context, cmd CrearBloqueCmd) (*geo.Bloque, error) {
	if err := geo.ValidarBloque(cmd.SedeID, cmd.Codigo, cmd.Nombre); err != nil {
		return nil, err
	}

	// Validar que la sede exista
	sede, err := s.sedeRepo.FindByID(ctx, cmd.SedeID)
	if err != nil {
		return nil, fmt.Errorf("verificar sede: %w", err)
	}
	if sede == nil {
		return nil, shared.NewNotFoundError("Sede", cmd.SedeID)
	}

	// Validar unicidad de código en la sede
	existente, err := s.bloqueRepo.FindByCodigo(ctx, cmd.SedeID, cmd.Codigo)
	if err != nil {
		return nil, fmt.Errorf("verificar codigo bloque: %w", err)
	}
	if existente != nil {
		return nil, &shared.DomainError{
			Code:    shared.ErrConflictoUnicidad,
			Message: fmt.Sprintf("Ya existe un bloque con el código '%s' en esta sede", cmd.Codigo),
		}
	}

	now := s.clk.Now()
	bloque := &geo.Bloque{
		SedeID:        cmd.SedeID,
		Codigo:        cmd.Codigo,
		Nombre:        cmd.Nombre,
		Pisos:         cmd.Pisos,
		Activo:        true,
		Eliminado:     false,
		CreadoEn:      now,
		ActualizadoEn: now,
	}

	if err := s.bloqueRepo.Create(ctx, bloque); err != nil {
		return nil, fmt.Errorf("guardar bloque: %w", err)
	}

	s.auditar(ctx, "bloque", bloque.ID, "BLOQUE_CREADO", cmd.Actor, nil, bloque)
	return bloque, nil
}

func (s *Service) ListarBloques(ctx context.Context, sedeID string) ([]*geo.Bloque, error) {
	if sedeID != "" {
		return s.bloqueRepo.ListBySede(ctx, sedeID)
	}
	return s.bloqueRepo.List(ctx)
}

func (s *Service) ObtenerBloquePorID(ctx context.Context, id string) (*geo.Bloque, error) {
	bloque, err := s.bloqueRepo.FindByID(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("obtener bloque: %w", err)
	}
	if bloque == nil {
		return nil, shared.NewNotFoundError("Bloque", id)
	}
	return bloque, nil
}

// ─────────────────────────────────────────────────────────────
// ESPACIOS (AULAS / LABORATORIOS / AUDITORIOS / TALLERES)
// ─────────────────────────────────────────────────────────────

// CrearEspacio implementa AC-01, AC-02, AC-03, AC-04.
func (s *Service) CrearEspacio(ctx context.Context, cmd CrearEspacioCmd) (*geo.Espacio, error) {
	// AC-04 por defecto
	if cmd.Estado == "" {
		cmd.Estado = geo.EstadoActivo
	}
	if cmd.NivelValidacion == "" {
		cmd.NivelValidacion = geo.NivelAula
	}
	if cmd.BufferMetros <= 0 {
		cmd.BufferMetros = 10.0 // buffer por defecto
	}

	// AC-02: sede y espacio obligatorios; torre, bloque y piso opcionales
	if err := geo.ValidarEspacio(cmd.SedeID, cmd.Codigo, cmd.Nombre, cmd.Tipo, cmd.Estado, cmd.Capacidad); err != nil {
		return nil, err
	}

	// Verificar existencia de sede
	sede, err := s.sedeRepo.FindByID(ctx, cmd.SedeID)
	if err != nil {
		return nil, fmt.Errorf("verificar sede de espacio: %w", err)
	}
	if sede == nil {
		return nil, shared.NewNotFoundError("Sede", cmd.SedeID)
	}

	// Si se indica bloque, verificar que exista y pertenezca a la misma sede
	if cmd.BloqueID != nil && strings.TrimSpace(*cmd.BloqueID) != "" {
		bloque, err := s.bloqueRepo.FindByID(ctx, *cmd.BloqueID)
		if err != nil {
			return nil, fmt.Errorf("verificar bloque de espacio: %w", err)
		}
		if bloque == nil {
			return nil, shared.NewNotFoundError("Bloque", *cmd.BloqueID)
		}
		if bloque.SedeID != cmd.SedeID {
			return nil, shared.NewValidationError("Jerarquía inválida", shared.FieldError{
				Campo: "bloqueId",
				Error: "El bloque indicado no pertenece a la sede especificada",
			})
		}
	}

	// AC-03: unicidad de código
	existente, err := s.espacioRepo.FindByCodigo(ctx, cmd.Codigo)
	if err != nil {
		return nil, fmt.Errorf("verificar codigo espacio: %w", err)
	}
	if existente != nil {
		return nil, &shared.DomainError{
			Code:    shared.ErrConflictoUnicidad,
			Message: fmt.Sprintf("Ya existe un espacio con el código '%s'", cmd.Codigo),
		}
	}

	now := s.clk.Now()
	espacio := &geo.Espacio{
		SedeID:              cmd.SedeID,
		Torre:               cmd.Torre,
		BloqueID:            cmd.BloqueID,
		Piso:                cmd.Piso,
		Codigo:              cmd.Codigo,
		Nombre:              cmd.Nombre,
		Capacidad:           cmd.Capacidad,
		Tipo:                cmd.Tipo,
		FacultadResponsable: cmd.FacultadResponsable,
		Estado:              cmd.Estado,
		NivelValidacion:     cmd.NivelValidacion,
		BufferMetros:        cmd.BufferMetros,
		VersionGeometria:    0,
		Activo:              cmd.Estado == geo.EstadoActivo,
		Eliminado:           false,
		CreadoEn:            now,
		ActualizadoEn:       now,
	}

	if err := s.espacioRepo.Create(ctx, espacio); err != nil {
		return nil, fmt.Errorf("guardar espacio: %w", err)
	}

	s.auditar(ctx, "espacio", espacio.ID, "ESPACIO_CREADO", cmd.Actor, nil, espacio)
	return espacio, nil
}

func (s *Service) ListarEspacios(ctx context.Context, filter repository.EspacioFilter) ([]*geo.Espacio, error) {
	return s.espacioRepo.List(ctx, filter)
}

func (s *Service) ObtenerEspacioPorID(ctx context.Context, id string) (*geo.Espacio, error) {
	espacio, err := s.espacioRepo.FindByID(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("obtener espacio: %w", err)
	}
	if espacio == nil {
		return nil, shared.NewNotFoundError("Espacio", id)
	}
	return espacio, nil
}

// ActualizarEspacio implementa AC-04 y AC-05 (advertencia de impacto ante sesiones futuras).
func (s *Service) ActualizarEspacio(ctx context.Context, id string, cmd ActualizarEspacioCmd) (*geo.Espacio, error) {
	espacio, err := s.espacioRepo.FindByID(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("obtener espacio a actualizar: %w", err)
	}
	if espacio == nil {
		return nil, shared.NewNotFoundError("Espacio", id)
	}

	valorAnterior := *espacio

	// Verificar unicidad de código si se intenta cambiar
	if cmd.Codigo != nil && *cmd.Codigo != espacio.Codigo {
		existente, err := s.espacioRepo.FindByCodigo(ctx, *cmd.Codigo)
		if err != nil {
			return nil, fmt.Errorf("verificar codigo espacio: %w", err)
		}
		if existente != nil && existente.ID != id {
			return nil, &shared.DomainError{
				Code:    shared.ErrConflictoUnicidad,
				Message: fmt.Sprintf("Ya existe otro espacio con el código '%s'", *cmd.Codigo),
			}
		}
		espacio.Codigo = *cmd.Codigo
	}

	// Verificar sede si cambia
	if cmd.SedeID != nil && *cmd.SedeID != espacio.SedeID {
		sede, err := s.sedeRepo.FindByID(ctx, *cmd.SedeID)
		if err != nil || sede == nil {
			return nil, shared.NewNotFoundError("Sede", *cmd.SedeID)
		}
		espacio.SedeID = *cmd.SedeID
	}

	// Verificar bloque si cambia
	if cmd.BloqueID != nil && *cmd.BloqueID != "" {
		bloque, err := s.bloqueRepo.FindByID(ctx, *cmd.BloqueID)
		if err != nil || bloque == nil {
			return nil, shared.NewNotFoundError("Bloque", *cmd.BloqueID)
		}
		if bloque.SedeID != espacio.SedeID {
			return nil, shared.NewValidationError("Jerarquía inválida", shared.FieldError{
				Campo: "bloqueId",
				Error: "El bloque indicado no pertenece a la sede del espacio",
			})
		}
		espacio.BloqueID = cmd.BloqueID
	} else if cmd.BloqueID != nil && *cmd.BloqueID == "" {
		espacio.BloqueID = nil
	}

	if cmd.Torre != nil {
		espacio.Torre = cmd.Torre
	}
	if cmd.Piso != nil {
		espacio.Piso = cmd.Piso
	}
	if cmd.Nombre != nil && strings.TrimSpace(*cmd.Nombre) != "" {
		espacio.Nombre = *cmd.Nombre
	}
	if cmd.Capacidad != nil && *cmd.Capacidad >= 0 {
		espacio.Capacidad = *cmd.Capacidad
	}
	if cmd.Tipo != nil && geo.EsTipoEspacioValido(*cmd.Tipo) {
		espacio.Tipo = *cmd.Tipo
	}
	if cmd.FacultadResponsable != nil {
		espacio.FacultadResponsable = *cmd.FacultadResponsable
	}
	if cmd.NivelValidacion != nil && geo.EsNivelValidacionValido(*cmd.NivelValidacion) {
		espacio.NivelValidacion = *cmd.NivelValidacion
	}
	if cmd.BufferMetros != nil && *cmd.BufferMetros > 0 {
		espacio.BufferMetros = *cmd.BufferMetros
	}

	// AC-05: Verificación de impacto al inactivar o pasar a mantenimiento
	if cmd.Estado != nil && geo.EsEstadoEspacioValido(*cmd.Estado) {
		nuevoEstado := *cmd.Estado
		if (nuevoEstado == geo.EstadoInactivo || nuevoEstado == geo.EstadoMantenimiento) && espacio.Estado == geo.EstadoActivo {
			if s.sesionChecker != nil {
				afectadas, err := s.sesionChecker.CountSesionesFuturasPorEspacio(ctx, id, s.clk.Now())
				if err != nil {
					s.log.Warn("no se pudo verificar sesiones futuras del espacio", applog.Err(err))
				} else if afectadas > 0 && !cmd.ConfirmarImpacto {
					return nil, &shared.DomainError{
						Code:    shared.ErrValidacion,
						Message: fmt.Sprintf("El espacio tiene %d sesiones futuras programadas. Requiere confirmación explícita para pasar a estado %s.", afectadas, nuevoEstado),
						Fields: []shared.FieldError{
							{Campo: "confirmarImpacto", Error: fmt.Sprintf("afecta_%d_sesiones_futuras", afectadas)},
						},
					}
				}
			}
		}
		espacio.Estado = nuevoEstado
		espacio.Activo = nuevoEstado == geo.EstadoActivo
	}

	espacio.ActualizadoEn = s.clk.Now()

	if err := s.espacioRepo.Update(ctx, espacio); err != nil {
		return nil, fmt.Errorf("actualizar espacio: %w", err)
	}

	s.auditar(ctx, "espacio", espacio.ID, "ESPACIO_ACTUALIZADO", cmd.Actor, valorAnterior, espacio)
	return espacio, nil
}

// EliminarEspacio implementa AC-06: borrado lógico con trazabilidad.
func (s *Service) EliminarEspacio(ctx context.Context, id string, actor ContextoActor) error {
	espacio, err := s.espacioRepo.FindByID(ctx, id)
	if err != nil {
		return fmt.Errorf("obtener espacio a eliminar: %w", err)
	}
	if espacio == nil {
		return shared.NewNotFoundError("Espacio", id)
	}

	if err := s.espacioRepo.SoftDelete(ctx, id); err != nil {
		return fmt.Errorf("borrado logico espacio: %w", err)
	}

	s.auditar(ctx, "espacio", id, "ESPACIO_ELIMINADO", actor, espacio, map[string]interface{}{"eliminado": true})
	return nil
}

// GuardarGeometriaEspacio implementa RF-GEO-002, T-GEO-02.7, AC-06, AC-07.
// Valida el polígono, calcula área en m² y centroide, incrementa versión de geometría,
// actualiza la entidad y registra entrada en auditoría con acción "GEOMETRIA_ACTUALIZADA".
func (s *Service) GuardarGeometriaEspacio(ctx context.Context, cmd GuardarGeometriaCmd) (*geo.Espacio, error) {
	espacio, err := s.espacioRepo.FindByID(ctx, cmd.EspacioID)
	if err != nil {
		return nil, fmt.Errorf("obtener espacio para geometría: %w", err)
	}
	if espacio == nil {
		return nil, shared.NewNotFoundError("Espacio", cmd.EspacioID)
	}

	poly, err := geo.NewGeoPolygon(cmd.Vertices)
	if err != nil {
		return nil, err
	}

	valorAnterior := *espacio

	if err := espacio.AsignarGeometria(poly, cmd.MetodoCaptura, cmd.PrecisionPromedioMetros); err != nil {
		return nil, err
	}

	if err := s.espacioRepo.Update(ctx, espacio); err != nil {
		return nil, fmt.Errorf("guardar geometria espacio: %w", err)
	}

	s.auditar(ctx, "espacio", espacio.ID, "GEOMETRIA_ACTUALIZADA", cmd.Actor, valorAnterior, espacio)
	return espacio, nil
}

// ─────────────────────────────────────────────────────────────
// HELPER AUDITORÍA
// ─────────────────────────────────────────────────────────────

func (s *Service) auditar(ctx context.Context, entidad, entidadID, accion string, actor ContextoActor, valAnt, valNuevo interface{}) {
	if s.auditoriaRepo == nil {
		return
	}
	entry := &repository.AuditEntry{
		Entidad:       entidad,
		EntidadID:     entidadID,
		Accion:        accion,
		ActorID:       actor.ActorID,
		RolActivo:     actor.RolActivo,
		CorrelationID: actor.CorrelationID,
		IPOrigen:      actor.IPOrigen,
		AgenteUsuario: actor.AgenteUsuario,
		ValorAnterior: valAnt,
		ValorNuevo:    valNuevo,
		CreadoEn:      s.clk.Now(),
	}
	if err := s.auditoriaRepo.Create(ctx, entry); err != nil {
		s.log.Error("fallo al registrar auditoria",
			applog.Err(err),
			applog.Extra(map[string]string{
				"entidad": entidad,
				"accion":  accion,
			}),
		)
	}
}
