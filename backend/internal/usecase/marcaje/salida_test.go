package marcaje

import (
	"testing"
	"time"

	domainMarcaje "github.com/siaa/backend/internal/domain/marcaje"
)

// US-MAR-15 AC-02: la permanencia son los minutos entre entrada y salida.
func TestPermanenciaMinutos(t *testing.T) {
	inicio := time.Date(2026, 10, 9, 7, 0, 0, 0, time.UTC)
	entrada := &domainMarcaje.Marcaje{TimestampServidor: inicio}
	salida := &domainMarcaje.Marcaje{TimestampServidor: inicio.Add(95*time.Minute + 20*time.Second)}
	if p, ok := PermanenciaMinutos(entrada, salida); !ok || p != 95 {
		t.Fatalf("permanencia = %d, %v", p, ok)
	}
	if _, ok := PermanenciaMinutos(salida, entrada); ok {
		t.Fatal("una salida anterior a la entrada no tiene permanencia")
	}
}

// US-MAR-15 AC-03: con el parámetro desactivado la salida es una operación inválida.
func TestValidarSalidaPermitida(t *testing.T) {
	req := domainMarcaje.SolicitudMarcaje{Tipo: domainMarcaje.TipoSalida}
	c := &domainMarcaje.ContextoSesion{Sesion: &domainMarcaje.SesionInfo{}, Parametros: parametrosPorDefecto()}
	if validarSalidaPermitida(req, c) == nil {
		t.Fatal("DESACTIVADO debe rechazar la salida")
	}
	c.Parametros.MarcajeSalidaModo = "OPCIONAL"
	if err := validarSalidaPermitida(req, c); err != nil {
		t.Fatalf("OPCIONAL admite la salida: %v", err)
	}
	req.Tipo = domainMarcaje.TipoEntrada
	c.Parametros.MarcajeSalidaModo = "DESACTIVADO"
	if err := validarSalidaPermitida(req, c); err != nil {
		t.Fatalf("la entrada no depende del modo de salida: %v", err)
	}
}
