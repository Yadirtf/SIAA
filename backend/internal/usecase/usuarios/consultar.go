package usuarios

import (
	"context"

	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/domain/user"
	"github.com/siaa/backend/internal/repository"
)

// Pagina es un listado paginado de usuarios.
type Pagina struct {
	Usuarios []*user.Usuario
	Total    int64
}

// Listar devuelve los usuarios visibles para el actor (RF-ROL-003): los roles globales ven a
// todos; quien opera por ámbito ve a quienes comparten alguno de sus ámbitos y a los docentes.
func (s *Service) Listar(ctx context.Context, actor Actor, f repository.FiltroUsuarios) (*Pagina, error) {
	f.Visibilidad = nil
	switch {
	case actor.Alcance.SoloPropios:
		u, err := s.usuarios.FindByID(ctx, actor.UsuarioID)
		if err != nil || u == nil {
			return &Pagina{Usuarios: []*user.Usuario{}}, err
		}
		return &Pagina{Usuarios: []*user.Usuario{u}, Total: 1}, nil
	case !actor.Alcance.Global:
		ids := append(append(append([]string{}, actor.Alcance.Sedes...), actor.Alcance.Facultades...), actor.Alcance.Bloques...)
		f.Visibilidad = &repository.VisibilidadUsuarios{AmbitoIDs: ids, RolesVisibles: rolesVisiblesPorAmbito}
	}
	lista, total, err := s.usuarios.Buscar(ctx, f)
	if err != nil {
		return nil, err
	}
	return &Pagina{Usuarios: lista, Total: total}, nil
}

// Obtener devuelve el detalle de un usuario visible para el actor.
func (s *Service) Obtener(ctx context.Context, actor Actor, id string) (*user.Usuario, error) {
	u, err := s.usuarios.FindByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if u == nil || u.Eliminado {
		return nil, shared.NewNotFoundError("Usuario", id)
	}
	if !visible(actor, u) {
		return nil, shared.NewScopeError()
	}
	return u, nil
}
