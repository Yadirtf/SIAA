// Pruebas unitarias del dominio — T-PLT-02.2 (cobertura ≥ 90% en domain)
// Las pruebas de dominio son PURAS: sin MongoDB, sin red, sin reloj real.
package unit_test

import (
	"testing"

	"github.com/siaa/backend/internal/domain/rbac"
)

func TestHasPermission(t *testing.T) {
	t.Run("retorna true si el permiso está presente", func(t *testing.T) {
		perms := []rbac.Permission{rbac.PermMarcajeCrear, rbac.PermMarcajeLeer}
		if !rbac.HasPermission(perms, rbac.PermMarcajeCrear) {
			t.Error("esperaba true, obtuvo false")
		}
	})

	t.Run("retorna false si el permiso no está presente", func(t *testing.T) {
		perms := []rbac.Permission{rbac.PermMarcajeLeer}
		if rbac.HasPermission(perms, rbac.PermMarcajeAnular) {
			t.Error("esperaba false, obtuvo true")
		}
	})

	t.Run("retorna false con lista vacía", func(t *testing.T) {
		if rbac.HasPermission([]rbac.Permission{}, rbac.PermMarcajeCrear) {
			t.Error("esperaba false, obtuvo true")
		}
	})
}

func TestHasAnyPermission(t *testing.T) {
	t.Run("retorna true si tiene al menos uno", func(t *testing.T) {
		perms := []rbac.Permission{rbac.PermMarcajeLeer}
		if !rbac.HasAnyPermission(perms, rbac.PermMarcajeCrear, rbac.PermMarcajeLeer) {
			t.Error("esperaba true")
		}
	})

	t.Run("retorna false si no tiene ninguno", func(t *testing.T) {
		perms := []rbac.Permission{rbac.PermAulaLeer}
		if rbac.HasAnyPermission(perms, rbac.PermMarcajeCrear, rbac.PermMarcajeAnular) {
			t.Error("esperaba false")
		}
	})
}

func TestIsInScope(t *testing.T) {
	t.Run("ámbitos vacíos significa acceso total (superadmin)", func(t *testing.T) {
		if !rbac.IsInScope([]rbac.Scope{}, rbac.ScopeSede, "SEDE-001") {
			t.Error("superadmin debe tener acceso total")
		}
	})

	t.Run("retorna true si la sede está en los ámbitos", func(t *testing.T) {
		scopes := []rbac.Scope{
			{Tipo: rbac.ScopeSede, ID: "SEDE-001"},
			{Tipo: rbac.ScopeSede, ID: "SEDE-002"},
		}
		if !rbac.IsInScope(scopes, rbac.ScopeSede, "SEDE-001") {
			t.Error("esperaba acceso a SEDE-001")
		}
	})

	t.Run("retorna false si la sede no está en los ámbitos", func(t *testing.T) {
		scopes := []rbac.Scope{
			{Tipo: rbac.ScopeSede, ID: "SEDE-001"},
		}
		if rbac.IsInScope(scopes, rbac.ScopeSede, "SEDE-999") {
			t.Error("no debe tener acceso a SEDE-999")
		}
	})

	t.Run("no confunde tipo de ámbito diferente", func(t *testing.T) {
		scopes := []rbac.Scope{
			{Tipo: rbac.ScopeFacultad, ID: "FAC-001"},
		}
		if rbac.IsInScope(scopes, rbac.ScopeSede, "FAC-001") {
			t.Error("Sede != Facultad aunque el ID sea igual")
		}
	})
}

func TestDefaultPermissionsIntegrity(t *testing.T) {
	// Verificar que los roles críticos tienen los permisos mínimos esperados
	critical := map[rbac.RoleName][]rbac.Permission{
		rbac.RolDocente: {
			rbac.PermMarcajeCrear,
			rbac.PermMarcajeLeer,
		},
		rbac.RolEstudiante: {
			rbac.PermMarcajeCrear,
			rbac.PermMarcajeLeer,
		},
		rbac.RolAuditor: {
			rbac.PermAuditoriaLeer,
			rbac.PermReporteLeer,
		},
	}

	for rol, expectedPerms := range critical {
		granted := rbac.DefaultPermissions[rol]
		for _, expected := range expectedPerms {
			found := false
			for _, g := range granted {
				if g == expected {
					found = true
					break
				}
			}
			if !found {
				t.Errorf("Rol %s debe tener permiso %s", rol, expected)
			}
		}
	}
}

func TestSuperadminHasAllPermissions(t *testing.T) {
	superPerms := rbac.DefaultPermissions[rbac.RolSuperadmin]
	allPerms := []rbac.Permission{
		rbac.PermMarcajeCrear, rbac.PermMarcajeLeer, rbac.PermMarcajeAjustar, rbac.PermMarcajeAnular,
		rbac.PermAulaLeer, rbac.PermAulaCrear, rbac.PermAulaEditar, rbac.PermAulaEliminar,
		rbac.PermSedeAdministrar, rbac.PermBloqueAdministrar,
		rbac.PermParametroLeer, rbac.PermParametroEditar,
		rbac.PermUsuarioCrear, rbac.PermUsuarioEditar, rbac.PermUsuarioLeer, rbac.PermUsuarioEliminar,
		rbac.PermAuditoriaLeer,
		rbac.PermReporteExportar, rbac.PermReporteLeer,
	}

	for _, perm := range allPerms {
		if !rbac.HasPermission(superPerms, perm) {
			t.Errorf("Superadmin debe tener el permiso %s", perm)
		}
	}
}
