// Package repository — bitácora de auditoría.
// La auditoría es de solo adición: sin Update ni Delete a nivel de aplicación.
// ADR-02: usecase depende de interfaces, no de implementaciones concretas.
package repository

import (
	"context"
	"time"
)

// AuditEntry representa una entrada de auditoría inmutable.
// Se registra cualquier acción relevante para trazabilidad y cumplimiento.
type AuditEntry struct {
	ID            string
	Entidad       string
	EntidadID     string
	Accion        string
	ActorID       string
	RolActivo     string
	CorrelationID string
	IPOrigen      string
	AgenteUsuario string
	ValorAnterior interface{}
	ValorNuevo    interface{}
	CreadoEn      time.Time
}

// AuditoriaRepository define operaciones sobre la bitácora de auditoría.
// Es de solo escritura desde la perspectiva del caso de uso.
type AuditoriaRepository interface {
	// Create agrega una nueva entrada de auditoría. No puede fallar silenciosamente.
	Create(ctx context.Context, e *AuditEntry) error
}
