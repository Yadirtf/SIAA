// Package marcaje — ventana de salida en la sesión activa (US-MAR-15).
package marcaje

import (
	"context"
	"math"
	"time"

	"github.com/siaa/backend/internal/domain/academico"
	domainMarcaje "github.com/siaa/backend/internal/domain/marcaje"
	dompar "github.com/siaa/backend/internal/domain/parametro"
)

// Tipos de ventana que informa la sesión activa.
const (
	VentanaTipoEntrada = "ENTRADA"
	VentanaTipoSalida  = "SALIDA"
)

// sesionEnVentanaSalida busca la sesión del día cuya ventana de salida está abierta ahora.
// Solo cuentan las sesiones cuyo parámetro congelado admite salida (OPCIONAL u OBLIGATORIO):
// con DESACTIVADO la app no ofrece marcar salida (US-MAR-15 AC-03).
func sesionEnVentanaSalida(sesiones []*academico.Sesion, ahora time.Time) (*academico.Sesion, VentanaDTO) {
	var elegida *academico.Sesion
	var ventana VentanaDTO
	minDiff := math.MaxFloat64
	for _, s := range sesiones {
		if s.Estado() == academico.EstadoSesionCancelada || s.Estado() == academico.EstadoSesionExcluida {
			continue
		}
		abre, cierra := s.VentanaSalidaAbre(), s.VentanaSalidaCierra()
		if abre == nil || cierra == nil || ahora.Before(*abre) || ahora.After(*cierra) {
			continue
		}
		if ParametrosDesdeSesion(s.ParametrosCongelados()).MarcajeSalidaModo == dompar.SalidaDesactivada {
			continue
		}
		// Desempate: gana la sesión cuyo fin está más próximo a ahora.
		if diff := math.Abs(ahora.Sub(s.FinProgramado()).Seconds()); diff < minDiff {
			minDiff = diff
			elegida = s
			ventana = VentanaDTO{AbreEn: *abre, CierraEn: *cierra, Estado: "ABIERTA", Tipo: VentanaTipoSalida}
		}
	}
	return elegida, ventana
}

// salidaPrevia devuelve la salida ya registrada cuando la ventana vigente es la de salida.
func (uc *SesionActivaUseCase) salidaPrevia(ctx context.Context, s *academico.Sesion, usuarioID string, v VentanaDTO) *domainMarcaje.Marcaje {
	if v.Tipo != VentanaTipoSalida {
		return nil
	}
	m, _ := uc.marcajeRepo.ObtenerPrevio(ctx, s.ID(), usuarioID, domainMarcaje.TipoSalida)
	return m
}
