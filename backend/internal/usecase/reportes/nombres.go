package reportes

import (
	"context"
	"strings"

	"github.com/siaa/backend/internal/repository"
)

// nombres resuelve nombres legibles (docente, aula, asignatura) con caché por consulta
// para no repetir lecturas en tablas con muchas filas del mismo docente o aula.
type nombres struct {
	usuarios   repository.UsuarioRepository
	espacios   repository.EspacioRepository
	estructura repository.EstructuraRepository
	cache      map[string]string
}

func nuevosNombres(u repository.UsuarioRepository, e repository.EspacioRepository, est repository.EstructuraRepository) *nombres {
	return &nombres{usuarios: u, espacios: e, estructura: est}
}

// buscar devuelve el valor en caché o lo calcula; si no se encuentra, devuelve el id.
func (n *nombres) buscar(tipo, id string, f func() string) string {
	if id == "" {
		return ""
	}
	if n.cache == nil {
		n.cache = map[string]string{}
	}
	k := tipo + ":" + id
	if v, ok := n.cache[k]; ok {
		return v
	}
	v := f()
	if v == "" {
		v = id
	}
	n.cache[k] = v
	return v
}

func (n *nombres) usuario(ctx context.Context, id string) string {
	return n.buscar("u", id, func() string {
		if n.usuarios == nil {
			return ""
		}
		if u, err := n.usuarios.FindByID(ctx, id); err == nil && u != nil {
			return strings.TrimSpace(u.Nombre + " " + u.Apellido)
		}
		return ""
	})
}

func (n *nombres) espacio(ctx context.Context, id string) string {
	return n.buscar("e", id, func() string {
		if n.espacios == nil {
			return ""
		}
		if e, err := n.espacios.FindByID(ctx, id); err == nil && e != nil {
			return strings.TrimSpace(e.Codigo + " · " + e.Nombre)
		}
		return ""
	})
}

func (n *nombres) asignatura(ctx context.Context, id string) string {
	return n.buscar("a", id, func() string {
		if n.estructura == nil {
			return ""
		}
		if a, err := n.estructura.GetAsignaturaByID(ctx, id); err == nil && a != nil {
			return a.Nombre()
		}
		return ""
	})
}
