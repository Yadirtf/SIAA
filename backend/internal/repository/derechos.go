// Package repository — persistencia de las solicitudes de derechos del titular (US-LEG-02).
package repository

import (
	"context"
	"errors"

	"github.com/siaa/backend/internal/domain/privacidad"
)

// ErrSolicitudModificada indica que otra persona cambió el caso mientras se atendía.
var ErrSolicitudModificada = errors.New("la solicitud cambió de estado mientras se atendía")

// FiltroSolicitudesDerechos filtra la bandeja de atención.
type FiltroSolicitudesDerechos struct {
	TitularID string
	Estado    privacidad.EstadoSolicitud
	Tipo      privacidad.TipoSolicitud
	// SoloAbiertas limita a RADICADA y EN_TRAMITE (ignora Estado).
	SoloAbiertas bool
}

// SolicitudDerechoRepository guarda los casos de derechos del titular.
type SolicitudDerechoRepository interface {
	Crear(ctx context.Context, s *privacidad.SolicitudDerecho) error
	// Obtener devuelve nil si no existe.
	Obtener(ctx context.Context, id string) (*privacidad.SolicitudDerecho, error)
	// Listar ordena por plazo: lo que vence primero, primero.
	Listar(ctx context.Context, f FiltroSolicitudesDerechos, limite int) ([]*privacidad.SolicitudDerecho, error)
	// Actualizar guarda el caso solo si su estado previo no cambió.
	Actualizar(ctx context.Context, s *privacidad.SolicitudDerecho, estadoPrevio privacidad.EstadoSolicitud) error
}

// ConsentimientoHistorialRepository devuelve todas las decisiones del titular, la más reciente primero.
type ConsentimientoHistorialRepository interface {
	Historial(ctx context.Context, usuarioID string) ([]*privacidad.Consentimiento, error)
}

// SupresionTitularRepository ejecuta la parte eliminable de una supresión (US-LEG-02 AC-03).
type SupresionTitularRepository interface {
	// AnonimizarUbicacionesDe borra las coordenadas de todos los marcajes del titular y de sus
	// copias en la bitácora, salvo los protegidos por `excluir`; devuelve cuántos marcajes cambió.
	AnonimizarUbicacionesDe(ctx context.Context, usuarioID string, excluir privacidad.ExclusionRetencion) (int64, error)
	// EliminarAvisosDe borra sus tokens push y sus preferencias de avisos.
	EliminarAvisosDe(ctx context.Context, usuarioID string) error
}
