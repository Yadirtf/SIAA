// Package auditctx transporta en el context.Context los datos de la petición que exige cada
// entrada de bitácora (US-AUD-01 AC-02, RF-AUD-002): dirección IP, agente de usuario,
// correlationId, actor y rol activo. El middleware HTTP los carga y el registrador de
// auditoría los completa en las entradas que no los traen.
package auditctx

import (
	"context"
	"sync"
)

// Rol usado cuando la acción no ocurre dentro de una sesión autenticada.
const (
	RolSinSesion = "SIN_SESION" // p. ej. intento de login o recuperación de contraseña
	RolSistema   = "SISTEMA"    // procesos del worker (retención, ausencias)
)

// Metadatos son los datos de origen de la petición en curso.
type Metadatos struct {
	IP            string
	AgenteUsuario string
	CorrelationID string

	mu        sync.RWMutex
	usuarioID string
	rolActivo string
}

// FijarSesion guarda el actor y el rol activo cuando la petición queda autenticada.
func (m *Metadatos) FijarSesion(usuarioID, rolActivo string) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.usuarioID, m.rolActivo = usuarioID, rolActivo
}

// Sesion devuelve el actor y el rol activo de la petición ("" si no hay sesión).
func (m *Metadatos) Sesion() (usuarioID, rolActivo string) {
	m.mu.RLock()
	defer m.mu.RUnlock()
	return m.usuarioID, m.rolActivo
}

type claveCtx struct{}

// Con devuelve un contexto que lleva los metadatos.
func Con(ctx context.Context, m *Metadatos) context.Context {
	return context.WithValue(ctx, claveCtx{}, m)
}

// De extrae los metadatos del contexto, o nil si la operación no nace de una petición HTTP.
func De(ctx context.Context) *Metadatos {
	if ctx == nil {
		return nil
	}
	m, _ := ctx.Value(claveCtx{}).(*Metadatos)
	return m
}
