package marcaje

import (
	"context"
	"fmt"
	"time"

	domainMarcaje "github.com/siaa/backend/internal/domain/marcaje"
	"github.com/siaa/backend/internal/repository"
)

// esAusenciaReemplazable indica si el registro vigente es la ausencia automática y el intento
// llega desde la cola offline: el docente sí marcó a tiempo, pero sin conexión.
func esAusenciaReemplazable(previo *domainMarcaje.Marcaje, req domainMarcaje.SolicitudMarcaje) bool {
	return previo.Origen == domainMarcaje.OrigenSistemaAusencia &&
		previo.Resultado == domainMarcaje.ResultadoAusente &&
		req.Origen == domainMarcaje.OrigenOffline
}

// reemplazarAusencia evalúa el marcaje offline con su hora de captura. Si es válido, reemplaza
// la ausencia sin borrarla (RF-JUS-004); si no, queda como evidencia del intento rechazado.
func (uc *CrearMarcajeUseCase) reemplazarAusencia(
	ctx context.Context,
	req domainMarcaje.SolicitudMarcaje,
	contexto *domainMarcaje.ContextoSesion,
	ausencia *domainMarcaje.Marcaje,
	ahora time.Time,
) (*domainMarcaje.ResultadoEvaluacion, *domainMarcaje.Marcaje, error) {
	contexto.MarcajePrevio = nil
	res := domainMarcaje.EvaluarMarcaje(req, *contexto, ahora)
	if res.Resultado == domainMarcaje.ResultadoPrecisionInsuficiente {
		return &res, nil, nil
	}
	m := uc.construirEntidadMarcaje(req, res, contexto, ahora)
	var err error
	if m.EsExitoso() {
		err = uc.marcajeRepo.RevertirAusenciaPorOffline(ctx, ausencia.ID, m)
	} else {
		err = uc.marcajeRepo.Crear(ctx, m)
	}
	if err != nil {
		return nil, nil, fmt.Errorf("registrar marcaje offline tardío: %w", err)
	}
	if uc.metrics != nil {
		uc.metrics.RecordMarcajeResultado(string(res.Resultado))
	}
	uc.registrarAuditoria(ctx, req, res, m)
	if m.EsExitoso() && uc.auditoriaRepo != nil {
		_ = uc.auditoriaRepo.Create(ctx, &repository.AuditEntry{
			Entidad:       "marcajes",
			EntidadID:     ausencia.ID,
			Accion:        "AUSENCIA_REVERTIDA_OFFLINE",
			ActorID:       req.UsuarioID,
			ValorAnterior: ausencia,
			ValorNuevo:    m,
			CreadoEn:      ahora,
		})
	}
	return &res, m, nil
}

// auditarIntentoSobreExistente deja constancia de un intento con ubicación simulada, root o
// emulador aunque la sesión ya tenga marcaje: no cambia el registro, pero no pasa inadvertido.
func (uc *CrearMarcajeUseCase) auditarIntentoSobreExistente(ctx context.Context, req domainMarcaje.SolicitudMarcaje, previo *domainMarcaje.Marcaje, ahora time.Time) {
	i := req.Integridad
	if uc.auditoriaRepo == nil || (!i.MockLocation && !i.Rooteado && !i.Emulador) {
		return
	}
	_ = uc.auditoriaRepo.Create(ctx, &repository.AuditEntry{
		Entidad:   "marcajes",
		EntidadID: previo.ID,
		Accion:    "MARCAJE_INTENTO_INTEGRIDAD",
		ActorID:   req.UsuarioID,
		ValorNuevo: map[string]interface{}{
			"sesionId":      req.SesionID,
			"tipo":          req.Tipo,
			"dispositivoId": req.DispositivoID,
			"mockLocation":  i.MockLocation,
			"rooteado":      i.Rooteado,
			"emulador":      i.Emulador,
			"coordenadas":   []float64{req.Longitud, req.Latitud},
		},
		CreadoEn: ahora,
	})
}
