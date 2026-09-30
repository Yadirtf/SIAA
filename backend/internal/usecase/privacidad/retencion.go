package privacidad

import (
	"context"
	"fmt"
	"time"

	dompar "github.com/siaa/backend/internal/domain/parametro"
	"github.com/siaa/backend/internal/repository"
)

// RetencionWorker anonimiza las coordenadas de los marcajes que superan el plazo de retención
// institucional (RNF-LEG-006). Lo ejecuta el proceso cmd/worker.
type RetencionWorker struct {
	retencion  repository.RetencionRepository
	parametros repository.ParametroRepository
	auditoria  repository.AuditoriaRepository
}

// NewRetencionWorker crea el proceso de anonimización.
func NewRetencionWorker(r repository.RetencionRepository, p repository.ParametroRepository, a repository.AuditoriaRepository) *RetencionWorker {
	return &RetencionWorker{retencion: r, parametros: p, auditoria: a}
}

// DiasRetencion lee el parámetro GLOBAL retencion_coordenadas_dias o su valor por defecto.
func (w *RetencionWorker) DiasRetencion(ctx context.Context) int {
	dias := dompar.ValoresPorDefecto()[dompar.ClaveRetencionCoordenadasDias].(int)
	if w.parametros == nil {
		return dias
	}
	p, err := w.parametros.FindByAmbitoAndClave(ctx, dompar.AmbitoGlobal, "", dompar.ClaveRetencionCoordenadasDias)
	if err != nil || p == nil {
		return dias
	}
	switch v := p.Valor.(type) {
	case int:
		dias = v
	case int32:
		dias = int(v)
	case int64:
		dias = int(v)
	case float64:
		dias = int(v)
	}
	// Un valor fuera del rango permitido nunca debe anonimizar datos recientes.
	if rango := dompar.RangosValidos[dompar.ClaveRetencionCoordenadasDias]; dias < rango[0] || dias > rango[1] {
		return dompar.ValoresPorDefecto()[dompar.ClaveRetencionCoordenadasDias].(int)
	}
	return dias
}

// EjecutarCiclo anonimiza lo anterior a `ahora - retención` y deja constancia en la bitácora.
func (w *RetencionWorker) EjecutarCiclo(ctx context.Context, ahora time.Time) (int64, error) {
	dias := w.DiasRetencion(ctx)
	limite := ahora.AddDate(0, 0, -dias)
	n, err := w.retencion.AnonimizarUbicaciones(ctx, limite)
	if err != nil {
		return n, fmt.Errorf("anonimizar ubicaciones: %w", err)
	}
	if n > 0 && w.auditoria != nil {
		_ = w.auditoria.Create(ctx, &repository.AuditEntry{
			Entidad: "marcajes", Accion: "UBICACIONES_ANONIMIZADAS", ActorID: "sistema", CreadoEn: ahora,
			ValorNuevo: map[string]interface{}{"cantidad": n, "anterioresA": limite, "retencionDias": dias},
		})
	}
	return n, nil
}
