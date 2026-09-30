package middleware

import (
	"fmt"
	"testing"
	"time"
)

// Las ventanas vencidas se eliminan: el almacén no crece con claves que no vuelven.
func TestRateLimitStore_EliminaVentanasVencidas(t *testing.T) {
	s := newMemoryRateLimitStore()
	inicio := time.Date(2026, 9, 30, 8, 0, 0, 0, time.UTC)
	for i := 0; i < 500; i++ {
		s.allow(fmt.Sprintf("ip-%d", i), 20, inicio)
	}
	if s.tamano() != 500 {
		t.Fatalf("se esperaban 500 claves, hay %d", s.tamano())
	}
	s.allow("ip-nueva", 20, inicio.Add(2*time.Minute))
	if s.tamano() != 1 {
		t.Fatalf("tras vencer la ventana solo debe quedar la clave nueva, hay %d", s.tamano())
	}
}

func TestRateLimitStore_LimitaYReinicia(t *testing.T) {
	s := newMemoryRateLimitStore()
	ahora := time.Date(2026, 9, 30, 8, 0, 0, 0, time.UTC)
	for i := 0; i < 3; i++ {
		if ok, _ := s.allow("u", 3, ahora); !ok {
			t.Fatalf("la petición %d debía pasar", i+1)
		}
	}
	if ok, espera := s.allow("u", 3, ahora); ok || espera <= 0 {
		t.Fatalf("la cuarta petición debía bloquearse con espera positiva")
	}
	if ok, _ := s.allow("u", 3, ahora.Add(61*time.Second)); !ok {
		t.Fatalf("tras la ventana la petición debía pasar")
	}
}
