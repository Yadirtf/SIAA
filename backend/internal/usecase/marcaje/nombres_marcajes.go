package marcaje

import (
	"context"
	"strings"

	domainMarcaje "github.com/siaa/backend/internal/domain/marcaje"
	"github.com/siaa/backend/internal/repository"
)

// MarcajeConNombres acompaña al marcaje con los nombres que ve el usuario en lugar de los
// identificadores internos (persona, asignatura, grupo y aula).
type MarcajeConNombres struct {
	*domainMarcaje.Marcaje
	UsuarioNombre    string `json:"usuarioNombre,omitempty"`
	AsignaturaNombre string `json:"asignaturaNombre,omitempty"`
	GrupoNumero      string `json:"grupoNumero,omitempty"`
	EspacioCodigo    string `json:"espacioCodigo,omitempty"`
}

// ListadoConNombres es el historial paginado con los nombres resueltos.
type ListadoConNombres struct {
	Items        []MarcajeConNombres `json:"items"`
	Total        int64               `json:"total"`
	Pagina       int64               `json:"pagina"`
	Limite       int64               `json:"limite"`
	TotalPaginas int64               `json:"totalPaginas"`
}

// NombradorMarcajes resuelve los nombres de una página de marcajes con una consulta por
// entidad distinta (la página tiene como máximo 100 elementos).
type NombradorMarcajes struct {
	sesiones   repository.SesionRepository
	estructura repository.EstructuraRepository
	espacios   repository.EspacioRepository
	usuarios   repository.UsuarioRepository
}

// NewNombradorMarcajes crea el resolutor; cualquier repositorio puede ser nil.
func NewNombradorMarcajes(s repository.SesionRepository, e repository.EstructuraRepository,
	esp repository.EspacioRepository, u repository.UsuarioRepository) *NombradorMarcajes {
	return &NombradorMarcajes{sesiones: s, estructura: e, espacios: esp, usuarios: u}
}

// Nombrar convierte la respuesta paginada; sin nombrador (nil) devuelve solo los marcajes.
func (n *NombradorMarcajes) Nombrar(ctx context.Context, r *RespuestaHistorial) *ListadoConNombres {
	res := &ListadoConNombres{Items: make([]MarcajeConNombres, 0, len(r.Items)),
		Total: r.Total, Pagina: r.Pagina, Limite: r.Limite, TotalPaginas: r.TotalPaginas}
	cache := map[string]string{}
	for _, m := range r.Items {
		item := MarcajeConNombres{Marcaje: m}
		if n != nil {
			n.completar(ctx, &item, cache)
		}
		res.Items = append(res.Items, item)
	}
	return res
}

func (n *NombradorMarcajes) completar(ctx context.Context, item *MarcajeConNombres, cache map[string]string) {
	item.UsuarioNombre = memo(cache, "u:"+item.UsuarioID, func() string { return n.usuario(ctx, item.UsuarioID) })
	espacioID := item.EspacioID
	if n.sesiones != nil && item.SesionID != "" {
		if s, err := n.sesiones.FindByID(ctx, item.SesionID); err == nil && s != nil {
			item.AsignaturaNombre = memo(cache, "a:"+s.AsignaturaID(), func() string { return n.asignatura(ctx, s.AsignaturaID()) })
			item.GrupoNumero = memo(cache, "g:"+s.GrupoID(), func() string { return n.grupo(ctx, s.GrupoID()) })
			if espacioID == "" {
				espacioID = s.EspacioID()
			}
		}
	}
	item.EspacioCodigo = memo(cache, "e:"+espacioID, func() string { return n.espacio(ctx, espacioID) })
}

func memo(cache map[string]string, clave string, f func() string) string {
	if v, ok := cache[clave]; ok {
		return v
	}
	v := f()
	cache[clave] = v
	return v
}

func (n *NombradorMarcajes) usuario(ctx context.Context, id string) string {
	if n.usuarios == nil || id == "" {
		return ""
	}
	if u, err := n.usuarios.FindByID(ctx, id); err == nil && u != nil {
		if nombre := strings.TrimSpace(u.Nombre + " " + u.Apellido); nombre != "" {
			return nombre
		}
		return u.Correo
	}
	return ""
}

func (n *NombradorMarcajes) asignatura(ctx context.Context, id string) string {
	if n.estructura == nil || id == "" {
		return ""
	}
	if a, err := n.estructura.GetAsignaturaByID(ctx, id); err == nil && a != nil {
		return a.Nombre()
	}
	return ""
}

func (n *NombradorMarcajes) grupo(ctx context.Context, id string) string {
	if n.estructura == nil || id == "" {
		return ""
	}
	if g, err := n.estructura.GetGrupoByID(ctx, id); err == nil && g != nil {
		return g.Numero()
	}
	return ""
}

func (n *NombradorMarcajes) espacio(ctx context.Context, id string) string {
	if n.espacios == nil || id == "" {
		return ""
	}
	if e, err := n.espacios.FindByID(ctx, id); err == nil && e != nil {
		return e.Codigo
	}
	return ""
}
