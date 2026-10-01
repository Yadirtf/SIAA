package academico

import (
	"context"
	"strings"

	domainAca "github.com/siaa/backend/internal/domain/academico"
)

// Búsquedas de nombres legibles de una entidad. Si la entidad no existe devuelven "" y quien
// llama decide el texto por defecto; nunca devuelven un identificador.

func (s *Service) nombreAsignatura(ctx context.Context, id string) string {
	if s.estructuraRepo == nil || id == "" {
		return ""
	}
	a, err := s.estructuraRepo.GetAsignaturaByID(ctx, id)
	if err != nil || a == nil {
		return ""
	}
	return a.Nombre()
}

func (s *Service) numeroGrupo(ctx context.Context, id string) string {
	if s.estructuraRepo == nil || id == "" {
		return ""
	}
	g, err := s.estructuraRepo.GetGrupoByID(ctx, id)
	if err != nil || g == nil {
		return ""
	}
	return g.Numero()
}

// nombreAula prefiere el código y nombre actuales del espacio; si no lo encuentra usa el
// nombre guardado en la asignación.
func (s *Service) nombreAula(ctx context.Context, id, guardado string) string {
	if s.espacioRepo != nil && id != "" {
		if e, err := s.espacioRepo.FindByID(ctx, id); err == nil && e != nil {
			return strings.TrimSpace(e.Codigo + " · " + e.Nombre)
		}
	}
	return guardado
}

func (s *Service) nombreUsuario(ctx context.Context, id string) string {
	if s.usuarioRepo == nil || id == "" {
		return ""
	}
	u, err := s.usuarioRepo.FindByID(ctx, id)
	if err != nil || u == nil {
		return ""
	}
	if n := strings.TrimSpace(u.Nombre + " " + u.Apellido); n != "" {
		return n
	}
	return u.Correo
}

func (s *Service) nombreDocentes(ctx context.Context, a *domainAca.Asignacion) string {
	if a.DocenteNombre() != "" {
		return a.DocenteNombre()
	}
	var nombres []string
	for _, id := range a.DocenteIDs() {
		if n := s.nombreUsuario(ctx, id); n != "" {
			nombres = append(nombres, n)
		}
	}
	return strings.Join(nombres, ", ")
}

// NombresAsignacion son los nombres que la lista de asignaciones muestra en lugar de ids.
type NombresAsignacion struct {
	AsignaturaCodigo string
	AsignaturaNombre string
	GrupoNumero      string
}

// NombresDeAsignaciones resuelve asignatura y grupo de un lote, consultando cada entidad una vez.
func (s *Service) NombresDeAsignaciones(ctx context.Context, lista []domainAca.Asignacion) map[string]NombresAsignacion {
	res := make(map[string]NombresAsignacion, len(lista))
	if s.estructuraRepo == nil {
		return res
	}
	asignaturas := map[string][2]string{}
	grupos := map[string]string{}
	for i := range lista {
		a := &lista[i]
		asig, ok := asignaturas[a.AsignaturaID()]
		if !ok {
			if x, err := s.estructuraRepo.GetAsignaturaByID(ctx, a.AsignaturaID()); err == nil && x != nil {
				asig = [2]string{x.Codigo(), x.Nombre()}
			}
			asignaturas[a.AsignaturaID()] = asig
		}
		grupo, ok := grupos[a.GrupoID()]
		if !ok {
			grupo = s.numeroGrupo(ctx, a.GrupoID())
			grupos[a.GrupoID()] = grupo
		}
		res[a.ID()] = NombresAsignacion{AsignaturaCodigo: asig[0], AsignaturaNombre: asig[1], GrupoNumero: grupo}
	}
	return res
}
