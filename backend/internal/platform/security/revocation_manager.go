// Package security — Gestor de lista de revocación en memoria para tokens JWT.
// Satisface US-AUT-07, AC-02 (rechazo de token de acceso en <= 60 s sin sobrecargar MongoDB).
package security

import (
	"sync"
	"time"
)

// RevocationManager mantiene una lista en memoria de usuarios con sesiones revocadas
// y la marca temporal antes de la cual cualquier token emitido debe ser rechazado.
type RevocationManager struct {
	mu           sync.RWMutex
	revocaciones map[string]time.Time // usuarioID -> revocadaAntesDe
}

var (
	defaultRevocationManager *RevocationManager
	once                     sync.Once
)

// DefaultRevocationManager retorna la instancia singleton del gestor de revocación.
func DefaultRevocationManager() *RevocationManager {
	once.Do(func() {
		defaultRevocationManager = &RevocationManager{
			revocaciones: make(map[string]time.Time),
		}
	})
	return defaultRevocationManager
}

// RevokeUser marca todas las sesiones emitidas antes de now como revocadas para ese usuario.
func (m *RevocationManager) RevokeUser(usuarioID string, revokedAt time.Time) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.revocaciones[usuarioID] = revokedAt
}

// IsTokenRevoked verifica si el token fue emitido antes de la última revocación del usuario.
func (m *RevocationManager) IsTokenRevoked(usuarioID string, tokenIssuedAt time.Time) bool {
	m.mu.RLock()
	defer m.mu.RUnlock()

	revokedAt, exists := m.revocaciones[usuarioID]
	if !exists {
		return false
	}

	// Si el token fue emitido antes o en el mismo segundo de la revocación, está revocado
	return !tokenIssuedAt.After(revokedAt)
}

// CleanOldEntries purga entradas mayores a 30 días para evitar acumulación en memoria.
func (m *RevocationManager) CleanOldEntries(retention time.Duration) {
	m.mu.Lock()
	defer m.mu.Unlock()
	threshold := time.Now().Add(-retention)
	for uid, t := range m.revocaciones {
		if t.Before(threshold) {
			delete(m.revocaciones, uid)
		}
	}
}
