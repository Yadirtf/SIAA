package unit_test

import (
	"testing"
	"time"

	"github.com/siaa/backend/internal/domain/shared"
)

// Toda hora que ve el usuario se escribe en 12 h con a. m./p. m. en hora de Bogotá.
func TestHorasEnDoceHoras(t *testing.T) {
	utc := time.Date(2026, 10, 1, 23, 5, 9, 0, time.UTC) // 6:05 p. m. en Bogotá
	casos := map[string]string{
		shared.HoraLocal(utc):                                          "6:05 p. m.",
		shared.FechaHoraLocal(utc):                                     "2026-10-01 6:05 p. m.",
		shared.FechaHoraSegundosLocal(utc):                             "2026-10-01 6:05:09 p. m.",
		shared.HoraLocal(time.Date(2026, 10, 1, 5, 0, 0, 0, time.UTC)): "12:00 a. m.",
		shared.Hora12h("12:30"):                                        "12:30 p. m.",
		shared.Hora12h("07:15"):                                        "7:15 a. m.",
		shared.Hora12h("sin hora"):                                     "sin hora",
	}
	for obtenido, esperado := range casos {
		if obtenido != esperado {
			t.Errorf("obtenido %q, esperado %q", obtenido, esperado)
		}
	}
}
