package usuarios

import (
	"context"
	"fmt"
	"net/mail"
	"strings"
	"time"

	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/domain/user"
)

// RolCmd es un rol a asignar con vigencia opcional (US-ROL-05).
type RolCmd struct {
	Nombre         string     `json:"nombre"`
	VigenciaInicio *time.Time `json:"vigenciaInicio,omitempty"`
	VigenciaFin    *time.Time `json:"vigenciaFin,omitempty"`
}

// rolesVisiblesPorAmbito son los roles que un coordinador ve aunque no compartan ámbito:
// necesita el directorio de docentes para programar asignaciones.
var rolesVisiblesPorAmbito = []string{string(rbac.RolDocente)}

func normalizarCorreo(correo string) (string, error) {
	c := strings.ToLower(strings.TrimSpace(correo))
	if a, err := mail.ParseAddress(c); err != nil || a.Address != c {
		return "", shared.NewValidationError("El correo no es válido", shared.FieldError{Campo: "correo", Error: "formato inválido"})
	}
	return c, nil
}

func validarNombre(nombre, apellido string) error {
	if strings.TrimSpace(nombre) == "" || strings.TrimSpace(apellido) == "" {
		return shared.NewValidationError("Nombre y apellido son obligatorios")
	}
	return nil
}

// validarRoles comprueba que cada rol exista y que el actor pueda otorgarlo (anti-escalamiento).
func (s *Service) validarRoles(ctx context.Context, actor Actor, roles []RolCmd) ([]user.RolAsignado, error) {
	if len(roles) == 0 {
		return nil, shared.NewValidationError("El usuario debe tener al menos un rol")
	}
	vistos := map[string]bool{}
	res := make([]user.RolAsignado, 0, len(roles))
	for _, r := range roles {
		nombre := strings.ToUpper(strings.TrimSpace(r.Nombre))
		if nombre == "" || vistos[nombre] {
			continue
		}
		vistos[nombre] = true
		if !rbac.EsPredefinidoNombre(nombre) && !s.rolPersonalizadoExiste(ctx, nombre) {
			return nil, shared.NewValidationError(fmt.Sprintf("El rol %s no existe", nombre))
		}
		if nombre == string(rbac.RolSuperadmin) && actor.RolActivo != string(rbac.RolSuperadmin) {
			return nil, shared.NewPermissionError()
		}
		if r.VigenciaInicio != nil && r.VigenciaFin != nil && r.VigenciaFin.Before(*r.VigenciaInicio) {
			return nil, shared.NewValidationError(fmt.Sprintf("La vigencia del rol %s termina antes de empezar", nombre))
		}
		res = append(res, user.RolAsignado{RolID: nombre, Nombre: rbac.RoleName(nombre),
			VigenciaInicio: r.VigenciaInicio, VigenciaFin: r.VigenciaFin, AsignadoPor: actor.UsuarioID})
	}
	if len(res) == 0 {
		return nil, shared.NewValidationError("El usuario debe tener al menos un rol")
	}
	return res, nil
}

func (s *Service) rolPersonalizadoExiste(ctx context.Context, nombre string) bool {
	if s.roles == nil {
		return false
	}
	r, err := s.roles.FindByNombre(ctx, nombre)
	return err == nil && r != nil
}

// validarAmbitos depura la lista y exige que quien opera por ámbito solo otorgue los suyos.
func validarAmbitos(actor Actor, ambitos []rbac.Scope) ([]rbac.Scope, error) {
	vistos := map[string]bool{}
	res := make([]rbac.Scope, 0, len(ambitos))
	for _, a := range ambitos {
		a.Tipo = rbac.ScopeType(strings.ToUpper(string(a.Tipo)))
		a.ID = strings.TrimSpace(a.ID)
		switch a.Tipo {
		case rbac.ScopeSede, rbac.ScopeFacultad, rbac.ScopeBloque:
		default:
			return nil, shared.NewValidationError(fmt.Sprintf("Tipo de ámbito inválido: %s", a.Tipo))
		}
		if a.ID == "" {
			return nil, shared.NewValidationError("Cada ámbito requiere un identificador")
		}
		clave := string(a.Tipo) + ":" + a.ID
		if vistos[clave] {
			continue
		}
		vistos[clave] = true
		if !actor.Alcance.Global && !rbac.IsInScope(ambitosDe(actor.Alcance), a.Tipo, a.ID) {
			return nil, shared.NewScopeError()
		}
		res = append(res, a)
	}
	return res, nil
}

// ambitosDe reconstruye los ámbitos del alcance del actor.
func ambitosDe(a rbac.Alcance) []rbac.Scope {
	var res []rbac.Scope
	for _, id := range a.Sedes {
		res = append(res, rbac.Scope{Tipo: rbac.ScopeSede, ID: id})
	}
	for _, id := range a.Facultades {
		res = append(res, rbac.Scope{Tipo: rbac.ScopeFacultad, ID: id})
	}
	for _, id := range a.Bloques {
		res = append(res, rbac.Scope{Tipo: rbac.ScopeBloque, ID: id})
	}
	// Sin ámbitos no hay nada que otorgar: IsInScope rechaza la lista vacía.
	return res
}

// visible indica si el actor puede ver o gestionar al usuario (RF-ROL-003).
func visible(actor Actor, u *user.Usuario) bool {
	switch {
	case actor.Alcance.Global:
		return true
	case actor.Alcance.SoloPropios:
		return u.ID == actor.UsuarioID
	}
	for _, r := range u.Roles {
		for _, v := range rolesVisiblesPorAmbito {
			if string(r.Nombre) == v {
				return true
			}
		}
	}
	for _, a := range u.Ambitos {
		for _, mio := range ambitosDe(actor.Alcance) {
			if a.ID == mio.ID {
				return true
			}
		}
	}
	return false
}

// exigirGestionable verifica visibilidad y que solo un superadministrador gestione a otro.
func exigirGestionable(actor Actor, u *user.Usuario) error {
	if !visible(actor, u) {
		return shared.NewScopeError()
	}
	if tieneRol(u, rbac.RolSuperadmin) && actor.RolActivo != string(rbac.RolSuperadmin) {
		return shared.NewPermissionError()
	}
	return nil
}

func tieneRol(u *user.Usuario, rol rbac.RoleName) bool {
	for _, r := range u.Roles {
		if r.Nombre == rol {
			return true
		}
	}
	return false
}
