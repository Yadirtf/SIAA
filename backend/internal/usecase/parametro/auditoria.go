// Package parametro — auditoría de los cambios de parámetros (US-AUD-01 AC-01, AC-05).
// Decora el repositorio: cada Upsert deja en la bitácora quién cambió qué clave, en qué
// ámbito, y el valor anterior y el nuevo. Si la bitácora no se puede escribir, el cambio no se
// aplica: no hay escritura sensible sin rastro.
package parametro

import (
	"context"
	"fmt"

	dompar "github.com/siaa/backend/internal/domain/parametro"
	"github.com/siaa/backend/internal/repository"
)

// Acciones registradas en la bitácora.
const (
	AccionParametroActualizado = "PARAMETRO_ACTUALIZADO"
	// AccionParametroFallido anula la entrada anterior: el cambio auditado no llegó a guardarse.
	AccionParametroFallido = "PARAMETRO_ACTUALIZACION_FALLIDA"
)

// repoAuditado implementa repository.ParametroRepository añadiendo la auditoría al Upsert.
type repoAuditado struct {
	repository.ParametroRepository
	auditoria repository.AuditoriaRepository
}

// ConAuditoria envuelve el repositorio de parámetros para auditar cada cambio.
func ConAuditoria(repo repository.ParametroRepository, auditoria repository.AuditoriaRepository) repository.ParametroRepository {
	if auditoria == nil {
		return repo
	}
	return &repoAuditado{ParametroRepository: repo, auditoria: auditoria}
}

// Upsert registra el cambio en la bitácora y solo después lo persiste: si la auditoría falla
// el parámetro no cambia. Si la escritura falla tras auditar, queda constancia del fallo.
func (r *repoAuditado) Upsert(ctx context.Context, p *dompar.Parametro) error {
	previo, err := r.FindByAmbitoAndClave(ctx, p.Ambito, p.AmbitoID, p.Clave)
	if err != nil {
		return fmt.Errorf("leer valor anterior: %w", err)
	}
	var anterior interface{}
	if previo != nil {
		anterior = map[string]interface{}{"valor": previo.Valor, "vigenteDesde": previo.VigenteDesde, "autorId": previo.AutorID}
	}
	nuevo := map[string]interface{}{
		"ambito": string(p.Ambito), "ambitoId": p.AmbitoID, "clave": string(p.Clave),
		"valor": p.Valor, "vigenteDesde": p.VigenteDesde,
	}
	if err := r.auditoria.Create(ctx, &repository.AuditEntry{
		Entidad: "parametros", EntidadID: claveEntidad(p), Accion: AccionParametroActualizado,
		ActorID: p.AutorID, ValorAnterior: anterior, ValorNuevo: nuevo,
	}); err != nil {
		return fmt.Errorf("auditar parámetro: %w", err)
	}
	if err := r.ParametroRepository.Upsert(ctx, p); err != nil {
		_ = r.auditoria.Create(ctx, &repository.AuditEntry{
			Entidad: "parametros", EntidadID: claveEntidad(p), Accion: AccionParametroFallido,
			ActorID: p.AutorID, ValorNuevo: map[string]interface{}{"error": err.Error()},
		})
		return err
	}
	return nil
}

// claveEntidad identifica el parámetro en la bitácora: ámbito, id de ámbito y clave.
func claveEntidad(p *dompar.Parametro) string {
	if p.AmbitoID == "" {
		return string(p.Ambito) + ":" + string(p.Clave)
	}
	return string(p.Ambito) + ":" + p.AmbitoID + ":" + string(p.Clave)
}
