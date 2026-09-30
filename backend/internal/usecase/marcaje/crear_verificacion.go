// Package marcaje — verificación complementaria (BSSID, baliza BLE o QR) por espacio (RF-GEO-016).
package marcaje

import (
	"context"

	"github.com/siaa/backend/internal/domain/geo"
	domainMarcaje "github.com/siaa/backend/internal/domain/marcaje"
)

// cargarVerificacion exige la verificación solo si el parámetro está activo y el aula tiene
// valores configurados; sin valores no habría forma de cumplirla y se bloquearía a todos.
func (uc *CrearMarcajeUseCase) cargarVerificacion(ctx context.Context, contexto *domainMarcaje.ContextoSesion, espacioID string) {
	if !contexto.Parametros.VerificacionComplementaria || espacioID == "" || uc.espacioRepo == nil {
		return
	}
	esp, err := uc.espacioRepo.FindByID(ctx, espacioID)
	if err != nil || esp == nil {
		return
	}
	if claves := esp.VerificacionComplementaria.Claves(); len(claves) > 0 {
		contexto.VerificacionExigida = true
		contexto.ValoresVerificacionValidos = claves
	}
}

// solicitudParaEvaluar entrega al motor el valor observado en la misma forma canónica que los
// valores del aula (método + valor normalizado). La evidencia guarda el valor tal como llegó.
func solicitudParaEvaluar(req domainMarcaje.SolicitudMarcaje) domainMarcaje.SolicitudMarcaje {
	if v := req.VerificacionComplementaria; v != nil {
		req.VerificacionComplementaria = &domainMarcaje.VerificacionEntrada{
			Metodo: v.Metodo,
			Valor:  geo.ClaveVerificacion(v.Metodo, v.Valor),
		}
	}
	return req
}
