package usuarios

import (
	"context"
	"strings"

	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/domain/user"
)

// ActualizarCmd son los datos personales editables.
type ActualizarCmd struct {
	Correo    string `json:"correo"`
	Nombre    string `json:"nombre"`
	Apellido  string `json:"apellido"`
	Documento string `json:"documento"`
}

// gestionable carga el usuario y verifica que el actor pueda administrarlo.
func (s *Service) gestionable(ctx context.Context, actor Actor, id string) (*user.Usuario, error) {
	u, err := s.usuarios.FindByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if u == nil || u.Eliminado {
		return nil, shared.NewNotFoundError("Usuario", id)
	}
	if err := exigirGestionable(actor, u); err != nil {
		return nil, err
	}
	return u, nil
}

// Actualizar modifica correo, nombre, apellido y documento, preservando la unicidad.
func (s *Service) Actualizar(ctx context.Context, actor Actor, id string, cmd ActualizarCmd) (*user.Usuario, error) {
	u, err := s.gestionable(ctx, actor, id)
	if err != nil {
		return nil, err
	}
	correo, err := normalizarCorreo(cmd.Correo)
	if err != nil {
		return nil, err
	}
	if err := validarNombre(cmd.Nombre, cmd.Apellido); err != nil {
		return nil, err
	}
	if otro, _ := s.usuarios.FindByCorreo(ctx, correo); otro != nil && otro.ID != u.ID {
		return nil, &shared.DomainError{Code: shared.ErrConflictoUnicidad, Message: "Ya existe un usuario con ese correo"}
	}
	documento := strings.TrimSpace(cmd.Documento)
	if documento != "" {
		if otro, _ := s.usuarios.FindByDocumento(ctx, documento); otro != nil && otro.ID != u.ID {
			return nil, &shared.DomainError{Code: shared.ErrConflictoUnicidad, Message: "Ya existe un usuario con ese documento"}
		}
	}
	antes := resumen(u)
	u.Correo, u.Nombre, u.Apellido, u.Documento = correo, strings.TrimSpace(cmd.Nombre), strings.TrimSpace(cmd.Apellido), documento
	return s.guardar(ctx, actor, u, "USUARIO_EDITADO", antes)
}

// CambiarEstado activa o desactiva la cuenta. Al desactivar se cierran sus sesiones.
func (s *Service) CambiarEstado(ctx context.Context, actor Actor, id string, activo bool, motivo string) (*user.Usuario, error) {
	u, err := s.gestionable(ctx, actor, id)
	if err != nil {
		return nil, err
	}
	if !activo && u.ID == actor.UsuarioID {
		return nil, shared.NewValidationError("No puedes desactivar tu propia cuenta")
	}
	if !activo && strings.TrimSpace(motivo) == "" {
		return nil, shared.NewValidationError("El motivo de la desactivación es obligatorio")
	}
	antes := resumen(u)
	u.Activo = activo
	accion := "USUARIO_ACTIVADO"
	if !activo {
		accion = "USUARIO_DESACTIVADO"
	}
	res, err := s.guardar(ctx, actor, u, accion, antes)
	if err == nil && !activo && s.revocador != nil {
		_ = s.revocador.RevocarSesionesUsuario(ctx, actor.UsuarioID, u.ID, motivo)
	}
	return res, err
}

// AsignarRoles reemplaza los roles del usuario (US-ROL-05), auditando antes y después.
func (s *Service) AsignarRoles(ctx context.Context, actor Actor, id string, roles []RolCmd) (*user.Usuario, error) {
	u, err := s.gestionable(ctx, actor, id)
	if err != nil {
		return nil, err
	}
	nuevos, err := s.validarRoles(ctx, actor, roles)
	if err != nil {
		return nil, err
	}
	if u.ID == actor.UsuarioID && tieneRol(u, rbac.RolSuperadmin) && !contieneRol(nuevos, rbac.RolSuperadmin) {
		return nil, shared.NewValidationError("No puedes quitarte el rol de superadministrador")
	}
	antes := resumen(u)
	u.Roles = nuevos
	return s.guardar(ctx, actor, u, "ROLES_ASIGNADOS", antes)
}

// AsignarAmbitos reemplaza las sedes, facultades y bloques del usuario (RF-ROL-003).
func (s *Service) AsignarAmbitos(ctx context.Context, actor Actor, id string, ambitos []rbac.Scope) (*user.Usuario, error) {
	u, err := s.gestionable(ctx, actor, id)
	if err != nil {
		return nil, err
	}
	nuevos, err := validarAmbitos(actor, ambitos)
	if err != nil {
		return nil, err
	}
	antes := resumen(u)
	u.Ambitos = nuevos
	return s.guardar(ctx, actor, u, "AMBITOS_ASIGNADOS", antes)
}

func (s *Service) guardar(ctx context.Context, actor Actor, u *user.Usuario, accion string, antes map[string]interface{}) (*user.Usuario, error) {
	u.ActualizadoEn = s.clock.Now()
	if err := s.usuarios.Update(ctx, u); err != nil {
		return nil, err
	}
	s.auditar(ctx, actor, u.ID, accion, antes, resumen(u))
	return u, nil
}

func contieneRol(roles []user.RolAsignado, rol rbac.RoleName) bool {
	for _, r := range roles {
		if r.Nombre == rol {
			return true
		}
	}
	return false
}
