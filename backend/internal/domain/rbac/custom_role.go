// Package rbac — Entidad y validaciones de roles personalizados.
// Satisface US-ROL-03, AC-01..AC-05 y RF-ROL-002.
package rbac

import (
	"fmt"
	"strings"
	"time"

	"github.com/siaa/backend/internal/domain/shared"
)

// Rol representa un rol del sistema, ya sea predefinido o personalizado (US-ROL-03).
type Rol struct {
	ID            string       `json:"id" bson:"_id,omitempty"`
	Nombre        string       `json:"nombre" bson:"nombre"`
	Descripcion   string       `json:"descripcion" bson:"descripcion"`
	Permisos      []Permission `json:"permisos" bson:"permisos"`
	EsPredefinido bool         `json:"esPredefinido" bson:"esPredefinido"`
	CreadoEn      time.Time    `json:"creadoEn" bson:"creadoEn"`
	ActualizadoEn time.Time    `json:"actualizadoEn" bson:"actualizadoEn"`
}

// EsPredefinidoNombre comprueba si el nombre corresponde a un rol fijo del sistema (AC-03).
func EsPredefinidoNombre(nombre string) bool {
	upper := strings.ToUpper(strings.TrimSpace(nombre))
	switch RoleName(upper) {
	case RolSuperadmin, RolAdminInst, RolCoordinador, RolDocente, RolEstudiante, RolMonitor, RolAuditor:
		return true
	default:
		return false
	}
}

// ValidarPermisos valida que cada permiso solicitado pertenezca estrictamente al catálogo oficial (AC-02).
func ValidarPermisos(perms []Permission) error {
	catalog := make(map[Permission]struct{}, len(AllPermissions))
	for _, p := range AllPermissions {
		catalog[p] = struct{}{}
	}

	for _, p := range perms {
		if _, exists := catalog[p]; !exists {
			return shared.NewValidationError(
				fmt.Sprintf("El permiso '%s' no existe en el catálogo oficial de permisos del sistema", p),
				shared.FieldError{Campo: "permisos", Error: "permiso_inexistente"},
			)
		}
	}
	return nil
}
