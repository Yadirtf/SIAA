// Package geo — casos de uso para la jerarquía física de espacios y cartografía (EP-03).
// Implementa reglas de negocio, validaciones y auditoría según el backlog y SRS.
package geo

import (
	"context"

	"github.com/siaa/backend/internal/domain/shared"
	applog "github.com/siaa/backend/internal/platform/log"
	"github.com/siaa/backend/internal/repository"
)

// Service orquesta la lógica de negocio para sedes, bloques, espacios y cartografía.
type Service struct {
	sedeRepo      repository.SedeRepository
	bloqueRepo    repository.BloqueRepository
	espacioRepo   repository.EspacioRepository
	histRepo      repository.EspacioGeometriaHistRepository
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
	histRepo repository.EspacioGeometriaHistRepository,
	sesionChecker repository.SesionFutureChecker,
	auditoriaRepo repository.AuditoriaRepository,
	clk shared.Clock,
	log *applog.Logger,
) *Service {
	return &Service{
		sedeRepo:      sedeRepo,
		bloqueRepo:    bloqueRepo,
		espacioRepo:   espacioRepo,
		histRepo:      histRepo,
		sesionChecker: sesionChecker,
		auditoriaRepo: auditoriaRepo,
		clk:           clk,
		log:           log,
	}
}

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
