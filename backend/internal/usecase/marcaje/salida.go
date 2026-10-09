// Package marcaje — reglas del marcaje de salida según el parámetro salida_obligatoria.
// US-MAR-15: con el parámetro DESACTIVADO la salida no se procesa (AC-03); con OPCIONAL u
// OBLIGATORIO se registra y se calcula la permanencia efectiva (AC-02).
package marcaje

import (
	"context"
	"math"

	domainMarcaje "github.com/siaa/backend/internal/domain/marcaje"
	dompar "github.com/siaa/backend/internal/domain/parametro"
	"github.com/siaa/backend/internal/domain/shared"
)

// validarSalidaPermitida rechaza, sin registrar evidencia, una salida en una sesión cuyo
// parámetro congelado la desactiva: no es un intento de asistencia sino una operación inválida.
func validarSalidaPermitida(req domainMarcaje.SolicitudMarcaje, c *domainMarcaje.ContextoSesion) error {
	if req.Tipo != domainMarcaje.TipoSalida || c == nil || c.Sesion == nil {
		return nil
	}
	if c.Parametros.MarcajeSalidaModo == dompar.SalidaDesactivada {
		return &shared.DomainError{
			Code:    shared.ErrEstadoInvalido,
			Message: "El marcaje de salida está desactivado para esta sesión",
		}
	}
	return nil
}

// completarSalida calcula la permanencia efectiva de una salida aceptada a partir de la entrada
// válida del mismo usuario en la sesión. Si no hay entrada válida, la salida queda sin permanencia.
func (uc *CrearMarcajeUseCase) completarSalida(ctx context.Context, m *domainMarcaje.Marcaje) *domainMarcaje.Marcaje {
	if m == nil || m.Tipo != domainMarcaje.TipoSalida || !m.EsExitoso() {
		return m
	}
	entrada, err := uc.marcajeRepo.ObtenerPrevio(ctx, m.SesionID, m.UsuarioID, domainMarcaje.TipoEntrada)
	if err != nil || entrada == nil || !entrada.EsExitoso() {
		return m
	}
	if p, ok := PermanenciaMinutos(entrada, m); ok {
		m.PermanenciaMin = &p
	}
	return m
}

// PermanenciaMinutos devuelve los minutos entre una entrada y una salida (redondeados).
func PermanenciaMinutos(entrada, salida *domainMarcaje.Marcaje) (int, bool) {
	inicio, fin := entrada.TimestampServidor, salida.TimestampServidor
	if inicio.IsZero() || fin.Before(inicio) {
		return 0, false
	}
	return int(math.Round(fin.Sub(inicio).Minutes())), true
}
