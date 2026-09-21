package shared

import "time"

// Clock es una dependencia inyectable para el tiempo. ADR-03.
// Ninguna regla de negocio llama a time.Now() directamente.
type Clock interface {
	Now() time.Time
}

// RealClock usa el reloj del sistema.
type RealClock struct{}

func (RealClock) Now() time.Time { return time.Now().UTC() }

// FakeClock permite fijar el tiempo en pruebas.
type FakeClock struct {
	FixedTime time.Time
}

func (f FakeClock) Now() time.Time { return f.FixedTime }

func NewFakeClock(t time.Time) FakeClock { return FakeClock{FixedTime: t} }
