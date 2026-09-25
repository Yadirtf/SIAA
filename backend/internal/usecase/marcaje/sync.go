// Package marcaje — caso de uso para sincronización en lote de marcajes offline.
// Satisface US-MAR-11 (AC-01..AC-07), RN-004, CA-009 y RNF-DIS-002.
package marcaje

import (
	"context"
	"math"
	"time"

	domainMarcaje "github.com/siaa/backend/internal/domain/marcaje"
	"github.com/siaa/backend/internal/repository"
)

// ItemSyncResultado contiene el resultado individual de procesar un elemento de la cola offline.
type ItemSyncResultado struct {
	SesionID         string                         `json:"sesionId"`
	Tipo             domainMarcaje.TipoMarcaje      `json:"tipo"`
	Exitoso          bool                           `json:"exitoso"`
	Resultado        domainMarcaje.ResultadoMarcaje `json:"resultado,omitempty"`
	MotivoRechazo    string                         `json:"motivoRechazo,omitempty"`
	Mensaje          string                         `json:"mensaje"`
	MarcajeID        string                         `json:"marcajeId,omitempty"`
	RequiereRevision bool                           `json:"requiereRevision"`
	Error            string                         `json:"error,omitempty"`
}

// SyncLoteRespuesta contiene el balance consolidado de la sincronización en lote.
type SyncLoteRespuesta struct {
	Sincronizados int                 `json:"sincronizados"`
	Fallidos      int                 `json:"fallidos"`
	Resultados    []ItemSyncResultado `json:"resultados"`
}

// SyncOfflineUseCase gestiona la reevaluación y persistencia de marcajes encolados sin conexión.
type SyncOfflineUseCase struct {
	crearUC     *CrearMarcajeUseCase
	marcajeRepo repository.MarcajeRepository
}

func NewSyncOfflineUseCase(crearUC *CrearMarcajeUseCase, marcajeRepo repository.MarcajeRepository) *SyncOfflineUseCase {
	return &SyncOfflineUseCase{
		crearUC:     crearUC,
		marcajeRepo: marcajeRepo,
	}
}

// Sincronizar procesa la cola de marcajes offline elemento por elemento de forma independiente (AC-06).
func (uc *SyncOfflineUseCase) Sincronizar(ctx context.Context, items []domainMarcaje.SolicitudMarcaje, usuarioID string, ahoraServidor time.Time) (*SyncLoteRespuesta, error) {
	if ahoraServidor.IsZero() {
		ahoraServidor = time.Now().UTC()
	}

	// Lote máximo de 50 elementos por contrato
	if len(items) > 50 {
		items = items[:50]
	}

	resp := &SyncLoteRespuesta{
		Resultados: make([]ItemSyncResultado, 0, len(items)),
	}

	for _, item := range items {
		// Asegurar identidad del usuario autenticado y origen OFFLINE (RN-004)
		item.UsuarioID = usuarioID
		item.Origen = domainMarcaje.OrigenOffline

		// Reevaluar temporalmente usando el timestamp del dispositivo pero detectando desfase (AC-03, AC-04)
		tiempoEvaluacion := item.TimestampDispositivo
		if tiempoEvaluacion.IsZero() {
			tiempoEvaluacion = ahoraServidor
		}

		desfaseSegundos := int(math.Abs(ahoraServidor.Sub(item.TimestampDispositivo).Seconds()))
		requiereRevision := desfaseSegundos > 300 // Más de 5 minutos de desfase (AC-04)

		evalRes, m, err := uc.crearUC.Ejecutar(ctx, item, tiempoEvaluacion)
		if err != nil {
			resp.Fallidos++
			resp.Resultados = append(resp.Resultados, ItemSyncResultado{
				SesionID: item.SesionID,
				Tipo:     item.Tipo,
				Exitoso:  false,
				Error:    err.Error(),
			})
			continue
		}

		exitoso := evalRes.Resultado == domainMarcaje.ResultadoPresente || evalRes.Resultado == domainMarcaje.ResultadoTardanza

		// Si el marcaje offline fue exitoso, revertir ausencia previa si existía (US-MAR-07 AC-05)
		if exitoso && m != nil {
			_ = uc.marcajeRepo.RevertirAusenciaPorOffline(ctx, item.SesionID, usuarioID, m)
		}

		marcajeID := ""
		if m != nil {
			marcajeID = m.ID
		}

		resp.Sincronizados++
		resp.Resultados = append(resp.Resultados, ItemSyncResultado{
			SesionID:         item.SesionID,
			Tipo:             item.Tipo,
			Exitoso:          exitoso,
			Resultado:        evalRes.Resultado,
			MotivoRechazo:    string(evalRes.MotivoRechazo),
			Mensaje:          evalRes.Mensaje,
			MarcajeID:        marcajeID,
			RequiereRevision: requiereRevision,
		})
	}

	return resp, nil
}
