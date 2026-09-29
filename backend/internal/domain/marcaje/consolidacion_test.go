package marcaje_test

import (
	"testing"

	"github.com/siaa/backend/internal/domain/marcaje"
)

// ADR-07: solo la asistencia válida y la ausencia ocupan la ranura única de la sesión;
// un rechazo no debe impedir el marcaje posterior desde el aula.
func TestConsolidaSesion(t *testing.T) {
	casos := map[marcaje.ResultadoMarcaje]bool{
		marcaje.ResultadoPresente:              true,
		marcaje.ResultadoTardanza:              true,
		marcaje.ResultadoValido:                true,
		marcaje.ResultadoRetardo:               true,
		marcaje.ResultadoAusente:               true,
		marcaje.ResultadoRechazadoFueraDeArea:  false,
		marcaje.ResultadoRechazadoIntegridad:   false,
		marcaje.ResultadoPrecisionInsuficiente: false,
		marcaje.ResultadoRechazadoFueraHorario: false,
	}
	for resultado, esperado := range casos {
		m := &marcaje.Marcaje{Resultado: resultado}
		if got := m.ConsolidaSesion(); got != esperado {
			t.Errorf("%s: ConsolidaSesion() = %v, want %v", resultado, got, esperado)
		}
	}
}
