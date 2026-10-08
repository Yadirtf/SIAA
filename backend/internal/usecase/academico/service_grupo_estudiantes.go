// Package academico — integrantes (estudiantes) de cada grupo (US-MAR-13, US-MAR-14).
// Quien no esté en el grupo no puede marcar en sus sesiones ni aparece en su lista manual.
package academico

import (
	"context"
	"errors"
	"sort"
	"strconv"
	"strings"
	"time"

	domainAca "github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/domain/user"
	"github.com/siaa/backend/internal/repository"
)

// ErrEstudiantesGrupoNoDisponible indica que el despliegue no tiene configurado el repositorio.
var ErrEstudiantesGrupoNoDisponible = errors.New("la gestión de estudiantes del grupo no está disponible")

// EstudianteGrupoDTO describe a un integrante del grupo con sus datos de contacto.
type EstudianteGrupoDTO struct {
	ID        string `json:"id"`
	Nombre    string `json:"nombre"`
	Correo    string `json:"correo"`
	Documento string `json:"documento,omitempty"`
}

// ResultadoEstudiantesGrupo informa qué identificadores quedaron en el grupo y cuáles no.
type ResultadoEstudiantesGrupo struct {
	Estudiantes   []EstudianteGrupoDTO `json:"estudiantes"`
	NoEncontrados []string             `json:"noEncontrados"`
	NoEstudiantes []string             `json:"noEstudiantes"`
}

// WithEstudiantesGrupo habilita la gestión de integrantes de grupo.
func (s *Service) WithEstudiantesGrupo(repo repository.GrupoEstudiantesRepository) *Service {
	s.grupoEstRepo = repo
	return s
}

// ListarEstudiantesGrupo devuelve los integrantes del grupo, ordenados por nombre.
func (s *Service) ListarEstudiantesGrupo(ctx context.Context, actor ContextoActor, grupoID string) ([]EstudianteGrupoDTO, error) {
	if _, err := s.grupoEnAlcance(ctx, actor, grupoID); err != nil {
		return nil, err
	}
	ids, err := s.grupoEstRepo.Listar(ctx, grupoID)
	if err != nil {
		return nil, err
	}
	res := make([]EstudianteGrupoDTO, 0, len(ids))
	for _, id := range ids {
		if u, err := s.usuarioRepo.FindByID(ctx, id); err == nil && u != nil {
			res = append(res, estudianteDTO(u))
		}
	}
	ordenarEstudiantes(res)
	return res, nil
}

// ReemplazarEstudiantesGrupo deja en el grupo exactamente a los estudiantes indicados. Cada
// identificador puede ser el id, el documento o el correo; los que no existen o no tienen el
// rol Estudiante vigente se informan y no se agregan. Queda auditado.
func (s *Service) ReemplazarEstudiantesGrupo(ctx context.Context, actor ContextoActor, grupoID string, identificadores []string) (*ResultadoEstudiantesGrupo, error) {
	grupo, err := s.grupoEnAlcance(ctx, actor, grupoID)
	if err != nil {
		return nil, err
	}
	res := &ResultadoEstudiantesGrupo{Estudiantes: []EstudianteGrupoDTO{}, NoEncontrados: []string{}, NoEstudiantes: []string{}}
	ids := make([]string, 0, len(identificadores))
	vistos := map[string]bool{}
	ahora := s.clk.Now()
	for _, ident := range identificadores {
		ident = strings.TrimSpace(ident)
		if ident == "" {
			continue
		}
		u := s.buscarUsuario(ctx, ident)
		switch {
		case u == nil:
			res.NoEncontrados = append(res.NoEncontrados, ident)
		case !esEstudianteVigente(u, ahora):
			res.NoEstudiantes = append(res.NoEstudiantes, ident)
		case !vistos[u.ID]:
			vistos[u.ID] = true
			ids = append(ids, u.ID)
			res.Estudiantes = append(res.Estudiantes, estudianteDTO(u))
		}
	}
	if grupo.Cupo() > 0 && len(ids) > grupo.Cupo() {
		return nil, shared.NewValidationError("El grupo tiene cupo para " + strconv.Itoa(grupo.Cupo()) +
			" estudiantes y se enviaron " + strconv.Itoa(len(ids)))
	}
	anteriores, _ := s.grupoEstRepo.Listar(ctx, grupoID)
	if err := s.grupoEstRepo.Reemplazar(ctx, grupoID, ids, actor.UsuarioID, ahora); err != nil {
		return nil, err
	}
	ordenarEstudiantes(res.Estudiantes)
	if s.auditoriaRepo != nil {
		_ = s.auditoriaRepo.Create(ctx, &repository.AuditEntry{
			Entidad: "grupos", EntidadID: grupoID, Accion: "ESTUDIANTES_GRUPO_ACTUALIZADOS",
			ActorID: actor.UsuarioID, RolActivo: actor.Rol,
			ValorAnterior: map[string]interface{}{"estudianteIds": anteriores},
			ValorNuevo:    map[string]interface{}{"estudianteIds": ids},
			CreadoEn:      ahora,
		})
	}
	return res, nil
}

// grupoEnAlcance obtiene el grupo y exige que su facultad esté en el ámbito del actor.
func (s *Service) grupoEnAlcance(ctx context.Context, actor ContextoActor, grupoID string) (*domainAca.Grupo, error) {
	if s.grupoEstRepo == nil {
		return nil, ErrEstudiantesGrupoNoDisponible
	}
	grupo, err := s.estructuraRepo.GetGrupoByID(ctx, grupoID)
	if err != nil || grupo == nil {
		return nil, ErrGrupoNoEncontrado
	}
	if !actor.porAmbito() {
		return grupo, nil
	}
	asig, err := s.estructuraRepo.GetAsignaturaByID(ctx, grupo.AsignaturaID())
	if err != nil || asig == nil {
		return nil, ErrAsignaturaNoEncontrada
	}
	prog, err := s.estructuraRepo.GetProgramaByID(ctx, asig.ProgramaID())
	if err != nil || prog == nil {
		return nil, ErrProgramaNoEncontrado
	}
	return grupo, s.exigirFacultad(ctx, actor, prog.FacultadID())
}

func (s *Service) buscarUsuario(ctx context.Context, ident string) *user.Usuario {
	if u, err := s.usuarioRepo.FindByID(ctx, ident); err == nil && u != nil && !u.Eliminado {
		return u
	}
	if strings.Contains(ident, "@") {
		if u, err := s.usuarioRepo.FindByCorreo(ctx, strings.ToLower(ident)); err == nil && u != nil {
			return u
		}
		return nil
	}
	if u, err := s.usuarioRepo.FindByDocumento(ctx, ident); err == nil && u != nil {
		return u
	}
	return nil
}

func esEstudianteVigente(u *user.Usuario, ahora time.Time) bool {
	if !u.Activo || u.Eliminado {
		return false
	}
	for _, r := range u.Roles {
		if r.Nombre == rbac.RolEstudiante && r.IsVigente(ahora) {
			return true
		}
	}
	return false
}

func ordenarEstudiantes(lista []EstudianteGrupoDTO) {
	sort.SliceStable(lista, func(i, j int) bool { return strings.ToLower(lista[i].Nombre) < strings.ToLower(lista[j].Nombre) })
}

func estudianteDTO(u *user.Usuario) EstudianteGrupoDTO {
	return EstudianteGrupoDTO{ID: u.ID, Nombre: strings.TrimSpace(u.Nombre + " " + u.Apellido), Correo: u.Correo, Documento: u.Documento}
}
