// Package privacidad — suspensión de la retención por investigación en curso (US-AUD-04 AC-03).
// Cuando vence el plazo de un registro marcado, la anonimización se suspende, se registra en
// la bitácora y se avisa a quien marcó la investigación.
package privacidad

import (
	"context"
	"fmt"
	"strconv"
	"time"

	"github.com/siaa/backend/internal/domain/notificacion"
	domain "github.com/siaa/backend/internal/domain/privacidad"
	"github.com/siaa/backend/internal/repository"
)

// AccionRetencionSuspendida es la acción de bitácora de cada suspensión.
const AccionRetencionSuspendida = "RETENCION_SUSPENDIDA"

// WithInvestigaciones habilita la suspensión por investigación; avisos (opcional) es la cola
// de notificaciones en la que se avisa a quien marcó la investigación.
func (w *RetencionWorker) WithInvestigaciones(r repository.InvestigacionRepository, avisos repository.NotificacionRepository) *RetencionWorker {
	w.investigaciones, w.avisos = r, avisos
	return w
}

func (w *RetencionWorker) investigacionesActivas(ctx context.Context) ([]*domain.Investigacion, error) {
	if w.investigaciones == nil {
		return nil, nil
	}
	activas, err := w.investigaciones.Activas(ctx)
	if err != nil {
		return nil, fmt.Errorf("leer investigaciones en curso: %w", err)
	}
	return activas, nil
}

// registrarSuspensiones audita y avisa, una vez al día por investigación, cuántos registros
// vencidos se conservan por ella. Los fallos no detienen la retención del resto.
func (w *RetencionWorker) registrarSuspensiones(ctx context.Context, activas []*domain.Investigacion, limite, ahora time.Time) {
	for _, inv := range activas {
		retenidos, err := w.retencion.ContarRetenidos(ctx, limite, domain.ExclusionDe(inv))
		if err != nil || retenidos == 0 {
			continue
		}
		if !w.avisar(ctx, inv, retenidos, ahora) {
			continue // ya se avisó y auditó hoy
		}
		if w.auditoria != nil {
			_ = w.auditoria.Create(ctx, &repository.AuditEntry{
				Entidad: "investigaciones_retencion", EntidadID: inv.ID, Accion: AccionRetencionSuspendida,
				ActorID: "sistema", CreadoEn: ahora,
				ValorNuevo: map[string]interface{}{
					"alcance": string(inv.Alcance), "objetivoId": inv.ObjetivoID,
					"registrosRetenidos": retenidos, "anterioresA": limite,
				},
			})
		}
	}
}

// avisar encola el aviso para quien marcó la investigación. Devuelve false si ese aviso ya se
// había encolado hoy (clave de deduplicación por investigación y día).
func (w *RetencionWorker) avisar(ctx context.Context, inv *domain.Investigacion, retenidos int64, ahora time.Time) bool {
	if w.avisos == nil || inv.CreadaPor == "" {
		return true
	}
	nuevo, err := w.avisos.Encolar(ctx, &notificacion.Notificacion{
		UsuarioID: inv.CreadaPor,
		Tipo:      domain.TipoAvisoRetencionSuspendida,
		Titulo:    "Retención suspendida por investigación",
		Cuerpo: fmt.Sprintf("%d registro(s) de %s %s cumplieron el plazo de retención y se conservan mientras la investigación siga abierta.",
			retenidos, nombreAlcance(inv.Alcance), inv.ObjetivoID),
		Datos: map[string]string{"ruta": "/auditoria", "investigacionId": inv.ID,
			"registrosRetenidos": strconv.FormatInt(retenidos, 10)},
		ClaveDedupe:    "retencion-suspendida:" + inv.ID + ":" + ahora.UTC().Format("2006-01-02"),
		ProgramadaPara: ahora.UTC(),
	})
	// Si la cola falla, la suspensión igual se audita.
	return err != nil || nuevo
}

func nombreAlcance(a domain.AlcanceInvestigacion) string {
	switch a {
	case domain.AlcanceUsuario:
		return "el usuario"
	case domain.AlcanceSesion:
		return "la sesión"
	}
	return "el marcaje"
}
