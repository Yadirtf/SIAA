package notificaciones

import (
	"context"
	"fmt"
	"time"

	"github.com/siaa/backend/internal/domain/justificacion"
	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/repository"
)

// HorasRevisionPorDefecto es el plazo tras el que se recuerda al revisor (US-JUS-04 AC-02).
const HorasRevisionPorDefecto = 48

// RecordatorioRevision recuerda al revisor asignado las justificaciones que siguen sin resolver
// cuando vence el plazo configurado. Cada justificación se recuerda una sola vez a cada revisor:
// la clave de deduplicación de la cola lo garantiza aunque el ciclo se repita.
type RecordatorioRevision struct {
	pendientes repository.JustificacionesSinResolverRepository
	usuarios   repository.UsuarioRepository
	productor  *Productor
	horas      int
}

// NewRecordatorioRevision crea el proceso con el plazo por defecto de 48 h.
func NewRecordatorioRevision(pendientes repository.JustificacionesSinResolverRepository, usuarios repository.UsuarioRepository, productor *Productor) *RecordatorioRevision {
	return &RecordatorioRevision{pendientes: pendientes, usuarios: usuarios, productor: productor, horas: HorasRevisionPorDefecto}
}

// ConPlazoHoras ajusta el plazo de revisión (0 conserva el defecto).
func (r *RecordatorioRevision) ConPlazoHoras(horas int) *RecordatorioRevision {
	if horas > 0 {
		r.horas = horas
	}
	return r
}

// EjecutarCiclo encola el recordatorio de cada justificación radicada hace más del plazo y aún
// sin decisión. Devuelve cuántos recordatorios nuevos encoló.
func (r *RecordatorioRevision) EjecutarCiclo(ctx context.Context, ahora time.Time) (int, error) {
	lista, err := r.pendientes.SinResolver(ctx, ahora.Add(-time.Duration(r.horas)*time.Hour), 500)
	if err != nil {
		return 0, err
	}
	nuevos := 0
	for _, j := range lista {
		for _, revisor := range r.revisores(ctx, j) {
			creado, err := r.productor.RecordatorioRevision(ctx, revisor, j.ID, j.NombreSesion, j.FechaSesion, r.horas)
			if err != nil {
				return nuevos, fmt.Errorf("encolar recordatorio de revisión: %w", err)
			}
			if creado {
				nuevos++
			}
		}
	}
	return nuevos, nil
}

// revisores devuelve el revisor asignado: quien tomó la justificación en revisión o, si nadie
// la ha tomado, los coordinadores con ámbito en su facultad o sede. Sin coordinadores, la
// administración institucional responde por ella.
func (r *RecordatorioRevision) revisores(ctx context.Context, j *justificacion.Justificacion) []string {
	if j.Estado == justificacion.EstadoEnRevision && j.RevisorID != "" {
		return []string{j.RevisorID}
	}
	var ambitos []string
	for _, id := range []string{j.FacultadID, j.SedeID} {
		if id != "" {
			ambitos = append(ambitos, id)
		}
	}
	if len(ambitos) > 0 {
		if ids := usuariosConRol(ctx, r.usuarios, rbac.RolCoordinador, ambitos); len(ids) > 0 {
			return excluir(ids, j.DocenteID)
		}
	}
	return excluir(usuariosConRol(ctx, r.usuarios, rbac.RolAdminInst, nil), j.DocenteID)
}

// usuariosConRol lista los usuarios activos con el rol; con ámbitos, solo los que tienen alguno.
func usuariosConRol(ctx context.Context, usuarios repository.UsuarioRepository, rol rbac.RoleName, ambitos []string) []string {
	if usuarios == nil {
		return nil
	}
	activo := true
	f := repository.FiltroUsuarios{Rol: string(rol), Activo: &activo, Limite: 100}
	if len(ambitos) > 0 {
		f.Visibilidad = &repository.VisibilidadUsuarios{AmbitoIDs: ambitos}
	}
	lista, _, err := usuarios.Buscar(ctx, f)
	if err != nil {
		return nil
	}
	ids := make([]string, 0, len(lista))
	for _, u := range lista {
		ids = append(ids, u.ID)
	}
	return ids
}

// excluir quita un identificador de la lista (quien radica no revisa su propia justificación).
func excluir(ids []string, quitar string) []string {
	res := ids[:0]
	for _, id := range ids {
		if id != quitar {
			res = append(res, id)
		}
	}
	return res
}
