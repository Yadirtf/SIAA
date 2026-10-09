// Package auditoria — registrador transversal de la bitácora (US-AUD-01 AC-02, AC-04).
// Decora el repositorio de auditoría: toda entrada sale con IP, agente de usuario,
// correlationId, actor y rol activo tomados del contexto de la petición cuando el caso de
// uso no los trae, y ningún fallo de escritura pasa en silencio.
package auditoria

import (
	"context"
	"time"

	"github.com/siaa/backend/internal/platform/auditctx"
	applog "github.com/siaa/backend/internal/platform/log"
	"github.com/siaa/backend/internal/repository"
)

// actorSistema es el ActorID con el que los procesos del worker firman sus entradas.
const actorSistema = "sistema"

// Registrador implementa repository.AuditoriaRepository sobre otro repositorio.
type Registrador struct {
	repo repository.AuditoriaRepository
	log  *applog.Logger
}

// NewRegistrador envuelve el repositorio real; log puede ser nil (se usa el logger por defecto).
func NewRegistrador(repo repository.AuditoriaRepository, log *applog.Logger) *Registrador {
	if log == nil {
		log = applog.Default()
	}
	return &Registrador{repo: repo, log: log}
}

// Create completa los metadatos ausentes, escribe la entrada y registra en el log cualquier
// fallo: muchos llamadores no pueden propagarlo, pero nunca debe perderse sin rastro.
func (r *Registrador) Create(ctx context.Context, e *repository.AuditEntry) error {
	Completar(ctx, e)
	err := r.repo.Create(ctx, e)
	if err != nil {
		r.log.Error("no se pudo escribir la entrada de auditoría",
			applog.Err(err),
			applog.CorrelationID(e.CorrelationID),
			applog.UsuarioID(e.ActorID),
			applog.Extra(map[string]string{"accion": e.Accion, "entidad": e.Entidad, "entidadId": e.EntidadID}),
		)
	}
	return err
}

// Completar rellena los campos de origen que la entrada no trae. Los valores explícitos del
// caso de uso (p. ej. el rol elegido al cambiar de contexto) nunca se sobrescriben.
func Completar(ctx context.Context, e *repository.AuditEntry) {
	if e.CreadoEn.IsZero() {
		e.CreadoEn = time.Now().UTC()
	}
	if md := auditctx.De(ctx); md != nil {
		usuarioID, rol := md.Sesion()
		e.IPOrigen = valorOr(e.IPOrigen, md.IP)
		e.AgenteUsuario = valorOr(e.AgenteUsuario, md.AgenteUsuario)
		e.CorrelationID = valorOr(e.CorrelationID, md.CorrelationID)
		e.ActorID = valorOr(e.ActorID, usuarioID)
		e.RolActivo = valorOr(e.RolActivo, rol)
	}
	if e.RolActivo == "" {
		if e.ActorID == actorSistema {
			e.RolActivo = auditctx.RolSistema
		} else {
			e.RolActivo = auditctx.RolSinSesion
		}
	}
}

func valorOr(actual, alterno string) string {
	if actual != "" {
		return actual
	}
	return alterno
}
