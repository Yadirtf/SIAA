// Package rbac — Caso de uso de gestión de roles personalizados y permisos.
// Satisface US-ROL-03, AC-01..AC-05 y RF-ROL-002/005.
package rbac

import (
	"context"
	"fmt"
	"strings"

	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/repository"
)

// Service gestiona las reglas de negocio de roles y permisos.
type Service struct {
	repo      repository.RolRepository
	auditoria repository.AuditoriaRepository
	clock     shared.Clock
}

// NewService crea un nuevo servicio de gestión de roles.
func NewService(repo repository.RolRepository, auditoria repository.AuditoriaRepository, clock shared.Clock) *Service {
	return &Service{
		repo:      repo,
		auditoria: auditoria,
		clock:     clock,
	}
}

// ListarRoles retorna todos los roles disponibles (predefinidos y personalizados).
func (s *Service) ListarRoles(ctx context.Context) ([]*rbac.Rol, error) {
	if s.repo == nil {
		// Fallback determinista a los 7 roles predefinidos del sistema
		return s.rolesPredefinidosFallback(), nil
	}

	roles, err := s.repo.Listar(ctx)
	if err != nil {
		return nil, err
	}

	if len(roles) == 0 {
		return s.rolesPredefinidosFallback(), nil
	}

	return roles, nil
}

// CrearRol crea un rol personalizado con un subconjunto de permisos del catálogo (AC-01, AC-02).
func (s *Service) CrearRol(ctx context.Context, actorID, nombre, desc string, permStrings []string) (*rbac.Rol, error) {
	nombre = strings.ToUpper(strings.TrimSpace(nombre))
	if nombre == "" {
		return nil, shared.NewValidationError("El nombre del rol es obligatorio")
	}

	// Impedir usar el nombre de un rol predefinido del sistema — AC-03
	if rbac.EsPredefinidoNombre(nombre) {
		return nil, shared.NewValidationError(
			fmt.Sprintf("No se puede crear un rol con el nombre reservado '%s'", nombre),
			shared.FieldError{Campo: "nombre", Error: "nombre_reservado"},
		)
	}

	// Verificar si ya existe un rol con ese nombre
	existente, _ := s.repo.FindByNombre(ctx, nombre)
	if existente != nil {
		return nil, shared.NewValidationError(
			fmt.Sprintf("Ya existe un rol con el nombre '%s'", nombre),
			shared.FieldError{Campo: "nombre", Error: "nombre_duplicado"},
		)
	}

	// Convertir y validar permisos contra el catálogo oficial — AC-02
	permisos := make([]rbac.Permission, len(permStrings))
	for i, ps := range permStrings {
		permisos[i] = rbac.Permission(ps)
	}
	if err := rbac.ValidarPermisos(permisos); err != nil {
		return nil, err
	}

	now := s.clock.Now()
	nuevoRol := &rbac.Rol{
		Nombre:        nombre,
		Descripcion:   desc,
		Permisos:      permisos,
		EsPredefinido: false,
		CreadoEn:      now,
		ActualizadoEn: now,
	}

	if err := s.repo.Create(ctx, nuevoRol); err != nil {
		return nil, err
	}

	// Auditoría de creación de rol con permisos asignados — AC-05
	s.registrarAuditoria(ctx, actorID, nuevoRol.ID, "ROL_CREADO", nil, nuevoRol)

	return nuevoRol, nil
}

// ActualizarRol actualiza la descripción y permisos de un rol personalizado existente (AC-03, AC-05).
func (s *Service) ActualizarRol(ctx context.Context, actorID, id, desc string, permStrings []string) (*rbac.Rol, error) {
	rol, err := s.repo.FindByID(ctx, id)
	if err != nil || rol == nil {
		return nil, shared.NewNotFoundError("Rol", id)
	}

	// Impedir alterar los permisos base de roles predefinidos — AC-03
	if rol.EsPredefinido || rbac.EsPredefinidoNombre(rol.Nombre) {
		return nil, shared.NewAuthError(
			shared.ErrPermisosDenegados,
			fmt.Sprintf("Los permisos del rol predefinido '%s' están protegidos y no pueden modificarse", rol.Nombre),
		)
	}

	permisos := make([]rbac.Permission, len(permStrings))
	for i, ps := range permStrings {
		permisos[i] = rbac.Permission(ps)
	}
	if err := rbac.ValidarPermisos(permisos); err != nil {
		return nil, err
	}

	permisosAnteriores := rol.Permisos

	rol.Descripcion = desc
	rol.Permisos = permisos
	rol.ActualizadoEn = s.clock.Now()

	if err := s.repo.Update(ctx, rol); err != nil {
		return nil, err
	}

	// Auditoría con permisos anteriores y nuevos — AC-05
	s.registrarAuditoria(ctx, actorID, rol.ID, "ROL_MODIFICADO",
		map[string]interface{}{"permisos": permisosAnteriores},
		map[string]interface{}{"permisos": permisos},
	)

	return rol, nil
}

// EliminarRol elimina un rol personalizado si no está en uso y no es predefinido (AC-03, AC-04, AC-05).
func (s *Service) EliminarRol(ctx context.Context, actorID, id string) error {
	rol, err := s.repo.FindByID(ctx, id)
	if err != nil || rol == nil {
		return shared.NewNotFoundError("Rol", id)
	}

	// Impedir eliminación de roles predefinidos del sistema — AC-03
	if rol.EsPredefinido || rbac.EsPredefinidoNombre(rol.Nombre) {
		return shared.NewAuthError(
			shared.ErrPermisosDenegados,
			fmt.Sprintf("El rol predefinido '%s' es fundamental para el sistema y no puede eliminarse", rol.Nombre),
		)
	}

	// Bloquear eliminación si está en uso por al menos un usuario — AC-04
	usuariosCount, err := s.repo.CountUsuariosConRol(ctx, rol.Nombre)
	if err != nil {
		return err
	}
	if usuariosCount > 0 {
		return shared.NewValidationError(
			fmt.Sprintf("No se puede eliminar el rol '%s' porque está asignado a %d usuario(s)", rol.Nombre, usuariosCount),
			shared.FieldError{Campo: "rol", Error: "rol_en_uso"},
		)
	}

	if err := s.repo.Delete(ctx, id); err != nil {
		return err
	}

	// Auditoría de eliminación — AC-05
	s.registrarAuditoria(ctx, actorID, id, "ROL_ELIMINADO", rol, nil)

	return nil
}

func (s *Service) registrarAuditoria(ctx context.Context, actorID, recursoID, accion string, anterior, nuevo interface{}) {
	if s.auditoria != nil {
		_ = s.auditoria.Create(ctx, &repository.AuditEntry{
			Entidad:       "Rol",
			EntidadID:     recursoID,
			Accion:        accion,
			ActorID:       actorID,
			ValorAnterior: anterior,
			ValorNuevo:    nuevo,
			CreadoEn:      s.clock.Now(),
		})
	}
}

func (s *Service) rolesPredefinidosFallback() []*rbac.Rol {
	rolesOrdenados := []rbac.RoleName{
		rbac.RolSuperadmin,
		rbac.RolAdminInst,
		rbac.RolCoordinador,
		rbac.RolDocente,
		rbac.RolEstudiante,
		rbac.RolMonitor,
		rbac.RolAuditor,
	}

	res := make([]*rbac.Rol, 0, len(rolesOrdenados))
	for _, r := range rolesOrdenados {
		res = append(res, &rbac.Rol{
			Nombre:        string(r),
			Descripcion:   "Rol predefinido del sistema",
			Permisos:      rbac.DefaultPermissions[r],
			EsPredefinido: true,
		})
	}
	return res
}
