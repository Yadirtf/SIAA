package privacidad

import (
	"testing"
	"time"
)

func TestCalcularEstado(t *testing.T) {
	ahora := time.Now()
	if e := CalcularEstado("1.0", nil); !e.RequiereAceptacion || e.PermiteMarcar() || e.Decision != nil {
		t.Fatalf("sin decisión debe pedir aceptación: %+v", e)
	}
	acepto := &Consentimiento{Version: "1.0", Decision: DecisionAceptado, DecididoEn: ahora}
	if e := CalcularEstado("1.0", acepto); e.RequiereAceptacion || !e.PermiteMarcar() || *e.Decision != DecisionAceptado {
		t.Fatalf("aceptar la vigente habilita el marcaje: %+v", e)
	}
	if e := CalcularEstado("2.0", acepto); !e.RequiereAceptacion || *e.VersionDecidida != "1.0" {
		t.Fatalf("una versión nueva exige aceptar de nuevo: %+v", e)
	}
	rechazo := &Consentimiento{Version: "1.0", Decision: DecisionRechazado, DecididoEn: ahora}
	if e := CalcularEstado("1.0", rechazo); e.PermiteMarcar() {
		t.Fatalf("un rechazo no permite marcar: %+v", e)
	}
}
