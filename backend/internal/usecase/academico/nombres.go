// Package academico — nombres legibles de las sesiones para listados y detalle.
package academico

import (
	"context"
	"strings"

	domainAca "github.com/siaa/backend/internal/domain/academico"
)

// NombresSesion agrupa los nombres que la interfaz muestra en lugar de identificadores.
type NombresSesion struct {
	AsignaturaCodigo string
	AsignaturaNombre string
	GrupoNumero      string
	EspacioCodigo    string
	EspacioNombre    string
	Docentes         []string
}

// NombresDeSesiones resuelve los nombres de un lote de sesiones consultando cada entidad una sola
// vez. Lo que no se encuentra queda vacío y la interfaz recurre al identificador.
func (s *Service) NombresDeSesiones(ctx context.Context, sesiones []*domainAca.Sesion) map[string]NombresSesion {
	asignaturas := map[string][2]string{}
	grupos := map[string]string{}
	espacios := map[string][2]string{}
	docentes := map[string]string{}
	res := make(map[string]NombresSesion, len(sesiones))
	for _, ses := range sesiones {
		n := NombresSesion{}
		if v, ok := asignaturas[ses.AsignaturaID()]; ok {
			n.AsignaturaCodigo, n.AsignaturaNombre = v[0], v[1]
		} else if a, err := s.estructuraRepo.GetAsignaturaByID(ctx, ses.AsignaturaID()); err == nil && a != nil {
			n.AsignaturaCodigo, n.AsignaturaNombre = a.Codigo(), a.Nombre()
			asignaturas[ses.AsignaturaID()] = [2]string{a.Codigo(), a.Nombre()}
		}
		if v, ok := grupos[ses.GrupoID()]; ok {
			n.GrupoNumero = v
		} else if g, err := s.estructuraRepo.GetGrupoByID(ctx, ses.GrupoID()); err == nil && g != nil {
			n.GrupoNumero = g.Numero()
			grupos[ses.GrupoID()] = g.Numero()
		}
		if v, ok := espacios[ses.EspacioID()]; ok {
			n.EspacioCodigo, n.EspacioNombre = v[0], v[1]
		} else if s.espacioRepo != nil && ses.EspacioID() != "" {
			if e, err := s.espacioRepo.FindByID(ctx, ses.EspacioID()); err == nil && e != nil {
				n.EspacioCodigo, n.EspacioNombre = e.Codigo, e.Nombre
				espacios[ses.EspacioID()] = [2]string{e.Codigo, e.Nombre}
			}
		}
		for _, id := range ses.DocenteIDs() {
			nombre, ok := docentes[id]
			if !ok && s.usuarioRepo != nil {
				if u, err := s.usuarioRepo.FindByID(ctx, id); err == nil && u != nil {
					nombre = strings.TrimSpace(u.Nombre + " " + u.Apellido)
				}
				docentes[id] = nombre
			}
			if nombre != "" {
				n.Docentes = append(n.Docentes, nombre)
			}
		}
		res[ses.ID()] = n
	}
	return res
}
