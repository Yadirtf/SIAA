// Package mongo — monitores del driver que alimentan /metrics (US-PLT-05 AC-01).
// El pool informa conexiones abiertas y prestadas (saturación) y cada comando su latencia.
package mongo

import (
	"context"

	"go.mongodb.org/mongo-driver/event"

	"github.com/siaa/backend/internal/platform/metrics"
)

// monitorPool traduce los eventos del pool de conexiones a contadores del colector.
func monitorPool(m *metrics.Collector) *event.PoolMonitor {
	return &event.PoolMonitor{
		Event: func(e *event.PoolEvent) {
			switch e.Type {
			case event.ConnectionCreated:
				m.ConexionDBAbierta()
			case event.ConnectionClosed:
				m.ConexionDBCerrada()
			case event.GetSucceeded:
				m.ConexionDBPrestada()
			case event.ConnectionReturned:
				m.ConexionDBDevuelta()
			}
		},
	}
}

// monitorComandos registra cada comando terminado con su duración real medida por el driver.
func monitorComandos(m *metrics.Collector) *event.CommandMonitor {
	return &event.CommandMonitor{
		Succeeded: func(_ context.Context, e *event.CommandSucceededEvent) {
			m.RecordComandoDB(e.CommandName, e.Duration, false)
		},
		Failed: func(_ context.Context, e *event.CommandFailedEvent) {
			m.RecordComandoDB(e.CommandName, e.Duration, true)
		},
	}
}
