package clock

import (
	"time"

	"github.com/siaa/backend/internal/domain/shared"
)

// RealClock implementa shared.Clock usando el reloj del sistema.
type RealClock = shared.RealClock

// FakeClock implementa shared.Clock con tiempo fijo para pruebas.
type FakeClock = shared.FakeClock

func NewFakeClock(t time.Time) shared.FakeClock {
	return shared.NewFakeClock(t)
}
