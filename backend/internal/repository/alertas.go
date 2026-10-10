package repository

import (
	"context"
	"time"

	"github.com/siaa/backend/internal/domain/notificacion"
)

// AlertasRepository lee los avisos de un tipo emitidos desde un instante, para el tablero en
// vivo (US-REP-03 AC-01). Solo lectura: la cola y la bandeja siguen en NotificacionRepository.
type AlertasRepository interface {
	// Recientes devuelve los avisos del tipo creados desde `desde`, los más recientes primero.
	Recientes(ctx context.Context, tipo notificacion.Tipo, desde time.Time, limite int) ([]*notificacion.Notificacion, error)
}
