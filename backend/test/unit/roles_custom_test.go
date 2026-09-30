// Package unit_test — Pruebas unitarias para EP-02: Roles personalizados y ABAC.
// Satisface US-ROL-01, US-ROL-02 (AC-01..AC-06), US-ROL-03 (AC-01..AC-05).
package unit_test

import (
	"context"
	"testing"
	"time"

	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/domain/shared"
	usecaseRbac "github.com/siaa/backend/internal/usecase/rbac"
)

// Mock RolRepository
type mockRolRepo struct {
	roles map[string]*rbac.Rol
}

func newMockRolRepo() *mockRolRepo {
	return &mockRolRepo{roles: make(map[string]*rbac.Rol)}
}

func (m *mockRolRepo) Listar(ctx context.Context) ([]*rbac.Rol, error) {
	var list []*rbac.Rol
	for _, r := range m.roles {
		list = append(list, r)
	}
	return list, nil
}

func (m *mockRolRepo) FindByID(ctx context.Context, id string) (*rbac.Rol, error) {
	if r, ok := m.roles[id]; ok {
		return r, nil
	}
	return nil, nil
}

func (m *mockRolRepo) FindByNombre(ctx context.Context, nombre string) (*rbac.Rol, error) {
	for _, r := range m.roles {
		if r.Nombre == nombre {
			return r, nil
		}
	}
	return nil, nil
}

func (m *mockRolRepo) Create(ctx context.Context, rol *rbac.Rol) error {
	rol.ID = "rol-" + rol.Nombre
	m.roles[rol.ID] = rol
	return nil
}

func (m *mockRolRepo) Update(ctx context.Context, rol *rbac.Rol) error {
	m.roles[rol.ID] = rol
	return nil
}

func (m *mockRolRepo) Delete(ctx context.Context, id string) error {
	delete(m.roles, id)
	return nil
}

func (m *mockRolRepo) CountUsuariosConRol(ctx context.Context, nombre string) (int, error) {
	if nombre == "ROL_EN_USO" {
		return 3, nil
	}
	return 0, nil
}

func TestUS_ROL_03_CustomRolesLifecycle(t *testing.T) {
	ctx := context.Background()
	rolRepo := newMockRolRepo()
	auditRepo := &mockAuditoriaRepo{}
	clk := shared.NewFakeClock(time.Date(2026, 9, 25, 10, 0, 0, 0, time.UTC))

	svc := usecaseRbac.NewService(rolRepo, auditRepo, clk)

	t.Run("AC-01 & AC-02: Crear rol personalizado con permisos válidos", func(t *testing.T) {
		rol, err := svc.CrearRol(ctx, "admin-1", "ASISTENTE_DOCENTE", "Asistente de docencia", []string{"marcaje:leer", "aula:leer"})
		if err != nil {
			t.Fatalf("error inesperado al crear rol: %v", err)
		}
		if rol.Nombre != "ASISTENTE_DOCENTE" {
			t.Errorf("esperaba nombre ASISTENTE_DOCENTE, obtuvo %s", rol.Nombre)
		}
		if rol.EsPredefinido {
			t.Error("rol personalizado no debe ser marcado como predefinido")
		}
		if len(rol.Permisos) != 2 {
			t.Errorf("esperaba 2 permisos, obtuvo %d", len(rol.Permisos))
		}
	})

	t.Run("AC-02: Rechazar permiso inexistente en el catálogo oficial", func(t *testing.T) {
		_, err := svc.CrearRol(ctx, "admin-1", "ROL_INVALIDO", "Desc", []string{"permiso:inexistente"})
		if err == nil {
			t.Fatal("esperaba error por permiso inexistente, obtuvo nil")
		}
	})

	t.Run("AC-03: Prohibir creación de rol con nombre predefinido del sistema", func(t *testing.T) {
		_, err := svc.CrearRol(ctx, "admin-1", "DOCENTE", "Desc", []string{"marcaje:leer"})
		if err == nil {
			t.Fatal("esperaba error al intentar crear rol con nombre predefinido DOCENTE")
		}
		valErr, ok := err.(*shared.DomainError)
		if !ok || valErr.Fields[0].Error != "nombre_reservado" {
			t.Fatalf("esperaba error nombre_reservado, obtuvo %v", err)
		}
	})

	t.Run("AC-03 & AC-05: Modificar rol personalizado exitosamente", func(t *testing.T) {
		rol, err := svc.CrearRol(ctx, "admin-1", "GESTOR_AULAS", "Gestor", []string{"aula:leer"})
		if err != nil {
			t.Fatalf("error creando rol: %v", err)
		}

		updated, err := svc.ActualizarRol(ctx, "admin-1", rol.ID, "Gestor de aulas modificado", []string{"aula:leer", "aula:crear"})
		if err != nil {
			t.Fatalf("error actualizando rol: %v", err)
		}
		if len(updated.Permisos) != 2 {
			t.Errorf("esperaba 2 permisos, obtuvo %d", len(updated.Permisos))
		}
	})

	t.Run("AC-04: Impedir eliminar un rol que está asignado a usuarios", func(t *testing.T) {
		// Crear rol con nombre que el mock reportará asignado a 3 usuarios
		rol, err := svc.CrearRol(ctx, "admin-1", "ROL_EN_USO", "En uso", []string{"aula:leer"})
		if err != nil {
			t.Fatalf("error creando rol: %v", err)
		}

		err = svc.EliminarRol(ctx, "admin-1", rol.ID)
		if err == nil {
			t.Fatal("esperaba error al intentar eliminar un rol en uso")
		}
		valErr, ok := err.(*shared.DomainError)
		if !ok || valErr.Fields[0].Error != "rol_en_uso" {
			t.Fatalf("esperaba error rol_en_uso, obtuvo %v", err)
		}
	})

	t.Run("AC-05: Eliminar rol personalizado no utilizado", func(t *testing.T) {
		rol, err := svc.CrearRol(ctx, "admin-1", "ROL_TEMPORAL", "Temp", []string{"aula:leer"})
		if err != nil {
			t.Fatalf("error creando rol: %v", err)
		}

		err = svc.EliminarRol(ctx, "admin-1", rol.ID)
		if err != nil {
			t.Fatalf("error inesperado al eliminar rol: %v", err)
		}

		// Verificar que no existe
		encontrado, _ := rolRepo.FindByID(ctx, rol.ID)
		if encontrado != nil {
			t.Error("rol eliminado todavía existe en repositorio")
		}
	})
}

func TestUS_ROL_02_ABAC_ScopeEnforcement(t *testing.T) {
	t.Run("Usuario con ámbito SEDE-001 accede a su sede pero no a SEDE-002", func(t *testing.T) {
		userScopes := []rbac.Scope{
			{Tipo: rbac.ScopeSede, ID: "SEDE-001"},
		}

		// Recurso en la misma sede
		if !rbac.IsInScope(userScopes, rbac.ScopeSede, "SEDE-001") {
			t.Error("debe tener acceso a recurso en SEDE-001")
		}

		// Recurso en otra sede -> 403 / denegado
		if rbac.IsInScope(userScopes, rbac.ScopeSede, "SEDE-002") {
			t.Error("NO debe tener acceso a recurso en SEDE-002")
		}
	})

	t.Run("Usuario con ámbito FAC-ING accede a su facultad pero no a FAC-MED", func(t *testing.T) {
		userScopes := []rbac.Scope{
			{Tipo: rbac.ScopeFacultad, ID: "FAC-ING"},
		}

		if !rbac.IsInScope(userScopes, rbac.ScopeFacultad, "FAC-ING") {
			t.Error("debe tener acceso a FAC-ING")
		}
		if rbac.IsInScope(userScopes, rbac.ScopeFacultad, "FAC-MED") {
			t.Error("NO debe tener acceso a FAC-MED")
		}
	})

	t.Run("Superadmin sin ámbitos explícitos tiene acceso irrestricto", func(t *testing.T) {
		superadminScopes := []rbac.Scope{}

		if !rbac.IsInScope(superadminScopes, rbac.ScopeSede, "CUALQUIER-SEDE") {
			t.Error("superadmin debe tener acceso a cualquier sede")
		}
		if !rbac.IsInScope(superadminScopes, rbac.ScopeFacultad, "CUALQUIER-FACULTAD") {
			t.Error("superadmin debe tener acceso a cualquier facultad")
		}
	})
}
