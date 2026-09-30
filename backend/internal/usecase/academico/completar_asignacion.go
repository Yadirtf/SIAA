package academico

import (
	"context"
	"strings"

	"github.com/siaa/backend/internal/domain/geo"
	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/domain/shared"
)

// completarAsignacion deriva en el servidor lo que antes escribía a mano el usuario (US-ACA-03):
// asignatura y facultad salen del grupo, el nombre del docente de su cuenta y el del aula del
// espacio. Rechaza docentes inexistentes, inactivos o sin rol DOCENTE y aulas de otra sede.
func (s *Service) completarAsignacion(ctx context.Context, cmd *CrearAsignacionCmd, sedePeriodo string) error {
	if err := s.completarEstructura(ctx, cmd); err != nil {
		return err
	}
	if err := s.completarDocentes(ctx, cmd); err != nil {
		return err
	}
	return s.completarEspacio(ctx, cmd, sedePeriodo)
}

func invalido(campo, mensaje string) error {
	return shared.NewValidationError(mensaje, shared.FieldError{Campo: campo, Error: "INVALIDO"})
}

func (s *Service) completarEstructura(ctx context.Context, cmd *CrearAsignacionCmd) error {
	if s.estructuraRepo == nil || cmd.GrupoID == "" {
		return nil
	}
	grupo, err := s.estructuraRepo.GetGrupoByID(ctx, cmd.GrupoID)
	if err != nil || grupo == nil {
		return ErrGrupoNoEncontrado
	}
	if grupo.PeriodoID() != "" && grupo.PeriodoID() != cmd.PeriodoID {
		return invalido("grupoId", "El grupo pertenece a otro periodo académico")
	}
	if cmd.AsignaturaID == "" {
		cmd.AsignaturaID = grupo.AsignaturaID()
	} else if cmd.AsignaturaID != grupo.AsignaturaID() {
		return invalido("asignaturaId", "La asignatura no corresponde al grupo")
	}
	asignatura, err := s.estructuraRepo.GetAsignaturaByID(ctx, cmd.AsignaturaID)
	if err != nil || asignatura == nil {
		return ErrAsignaturaNoEncontrada
	}
	programa, err := s.estructuraRepo.GetProgramaByID(ctx, asignatura.ProgramaID())
	if err != nil || programa == nil {
		return ErrProgramaNoEncontrado
	}
	if cmd.FacultadID == "" {
		cmd.FacultadID = programa.FacultadID()
	} else if cmd.FacultadID != programa.FacultadID() {
		return invalido("facultadId", "La facultad no corresponde al programa de la asignatura")
	}
	return nil
}

func (s *Service) completarDocentes(ctx context.Context, cmd *CrearAsignacionCmd) error {
	vistos := map[string]bool{}
	ids := make([]string, 0, len(cmd.DocenteIDs))
	for _, id := range cmd.DocenteIDs {
		if id = strings.TrimSpace(id); id != "" && !vistos[id] {
			vistos[id] = true
			ids = append(ids, id)
		}
	}
	if len(ids) == 0 {
		return shared.NewValidationError("Seleccione al menos un docente", shared.FieldError{Campo: "docenteIds", Error: "REQUERIDO"})
	}
	cmd.DocenteIDs = ids
	if s.usuarioRepo == nil {
		return nil
	}
	nombres := make([]string, 0, len(ids))
	for _, id := range ids {
		nombre, err := s.nombreDocente(ctx, id)
		if err != nil {
			return err
		}
		nombres = append(nombres, nombre)
	}
	cmd.DocenteNombre = strings.Join(nombres, ", ")
	return nil
}

// nombreDocente verifica que el usuario exista, esté activo y tenga el rol DOCENTE.
func (s *Service) nombreDocente(ctx context.Context, id string) (string, error) {
	u, err := s.usuarioRepo.FindByID(ctx, id)
	if err != nil || u == nil || u.Eliminado {
		return "", invalido("docenteIds", "El docente seleccionado no existe")
	}
	if !u.Activo {
		return "", invalido("docenteIds", "El docente "+u.Correo+" está inactivo")
	}
	for _, r := range u.Roles {
		if r.Nombre == rbac.RolDocente {
			if nombre := strings.TrimSpace(u.Nombre + " " + u.Apellido); nombre != "" {
				return nombre, nil
			}
			return u.Correo, nil
		}
	}
	return "", invalido("docenteIds", "El usuario "+u.Correo+" no tiene el rol DOCENTE")
}

func (s *Service) completarEspacio(ctx context.Context, cmd *CrearAsignacionCmd, sedePeriodo string) error {
	if s.espacioRepo == nil || cmd.EspacioID == "" {
		return nil
	}
	espacio, err := s.espacioRepo.FindByID(ctx, cmd.EspacioID)
	if err != nil || espacio == nil {
		return invalido("espacioId", "El aula seleccionada no existe")
	}
	if sedePeriodo != "" && espacio.SedeID != sedePeriodo {
		return invalido("espacioId", "El aula "+espacio.Codigo+" no pertenece a la sede del periodo")
	}
	if espacio.Estado == geo.EstadoInactivo {
		return invalido("espacioId", "El aula "+espacio.Codigo+" está inactiva")
	}
	cmd.EspacioNombre = strings.TrimSpace(espacio.Codigo + " · " + espacio.Nombre)
	return nil
}
