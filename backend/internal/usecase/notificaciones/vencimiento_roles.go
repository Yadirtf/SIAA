package notificaciones

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/domain/user"
	"github.com/siaa/backend/internal/repository"
)

// DiasAvisoVencimientoRol es la anticipación del aviso de vencimiento (US-ROL-05 AC-02).
const DiasAvisoVencimientoRol = 3

// AvisoVencimientoRoles avisa al administrador responsable que un rol asignado con vigencia
// termina en los próximos días. Cada vencimiento se avisa una sola vez por administrador.
type AvisoVencimientoRoles struct {
	porVencer repository.RolesPorVencerRepository
	usuarios  repository.UsuarioRepository
	productor *Productor
	dias      int
}

// NewAvisoVencimientoRoles crea el proceso con 3 días de anticipación.
func NewAvisoVencimientoRoles(porVencer repository.RolesPorVencerRepository, usuarios repository.UsuarioRepository, productor *Productor) *AvisoVencimientoRoles {
	return &AvisoVencimientoRoles{porVencer: porVencer, usuarios: usuarios, productor: productor, dias: DiasAvisoVencimientoRol}
}

// EjecutarCiclo encola el aviso de cada rol cuya vigencia termina entre ahora y ahora + 3 días.
// Devuelve cuántos avisos nuevos encoló.
func (a *AvisoVencimientoRoles) EjecutarCiclo(ctx context.Context, ahora time.Time) (int, error) {
	hasta := ahora.Add(time.Duration(a.dias) * 24 * time.Hour)
	lista, err := a.porVencer.ConRolesPorVencer(ctx, ahora, hasta)
	if err != nil {
		return 0, err
	}
	nuevos := 0
	for _, u := range lista {
		nombre := strings.TrimSpace(u.Nombre + " " + u.Apellido)
		for _, r := range u.Roles {
			if r.VigenciaFin == nil || !r.VigenciaFin.After(ahora) || r.VigenciaFin.After(hasta) {
				continue
			}
			for _, admin := range a.responsables(ctx, r, u.ID) {
				creado, err := a.productor.VencimientoRol(ctx, admin, u.ID, nombre, string(r.Nombre), *r.VigenciaFin)
				if err != nil {
					return nuevos, fmt.Errorf("encolar aviso de vencimiento: %w", err)
				}
				if creado {
					nuevos++
				}
			}
		}
	}
	return nuevos, nil
}

// responsables devuelve quien asignó el rol si sigue activo; si no se conoce, la administración
// institucional (y, sin ella, los superadministradores).
func (a *AvisoVencimientoRoles) responsables(ctx context.Context, r user.RolAsignado, titularID string) []string {
	if r.AsignadoPor != "" && r.AsignadoPor != titularID && a.usuarios != nil {
		if admin, err := a.usuarios.FindByID(ctx, r.AsignadoPor); err == nil && admin != nil && admin.Activo && !admin.Eliminado {
			return []string{admin.ID}
		}
	}
	for _, rol := range []rbac.RoleName{rbac.RolAdminInst, rbac.RolSuperadmin} {
		if ids := excluir(usuariosConRol(ctx, a.usuarios, rol, nil), titularID); len(ids) > 0 {
			return ids
		}
	}
	return nil
}
