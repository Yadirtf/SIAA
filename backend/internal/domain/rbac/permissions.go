// Package rbac implementa el control de acceso basado en roles y permisos granulares.
// US-ROL-01: permisos con formato "recurso:acción".
// ADR-02: evaluación como función pura en domain/rbac.
package rbac

// Permission representa un permiso granular con formato "recurso:acción".
type Permission string

// ─────────────────────────────────────────────────────────────
// Catálogo completo de permisos — Matriz SRS §3.2
// Regla: PROHIBIDO usar literales de cadena en handlers (T-ROL-01.1)
// ─────────────────────────────────────────────────────────────

const (
	// Marcaje
	PermMarcajeCrear   Permission = "marcaje:crear"
	PermMarcajeLeer    Permission = "marcaje:leer"
	PermMarcajeAjustar Permission = "marcaje:ajustar"
	PermMarcajeAnular  Permission = "marcaje:anular"

	// Aulas / Espacios
	PermAulaLeer            Permission = "aula:leer"
	PermAulaCrear           Permission = "aula:crear"
	PermAulaEditar          Permission = "aula:editar"
	PermAulaEditarGeometria Permission = "aula:editar-geometria"
	PermAulaEliminar        Permission = "aula:eliminar"

	// Sede y Bloque
	PermSedeAdministrar   Permission = "sede:administrar"
	PermBloqueAdministrar Permission = "bloque:administrar"

	// Horarios y asignaciones
	PermHorarioCrear     Permission = "horario:crear"
	PermHorarioLeer      Permission = "horario:leer"
	PermAsignacionCrear  Permission = "asignacion:crear"
	PermAsignacionEditar Permission = "asignacion:editar"

	// Parámetros
	PermParametroLeer   Permission = "parametro:leer"
	PermParametroEditar Permission = "parametro:editar"

	// Usuarios
	PermUsuarioCrear    Permission = "usuario:crear"
	PermUsuarioEditar   Permission = "usuario:editar"
	PermUsuarioLeer     Permission = "usuario:leer"
	PermUsuarioEliminar Permission = "usuario:eliminar"

	// Justificaciones
	PermJustificacionCrear   Permission = "justificacion:crear"
	PermJustificacionAprobar Permission = "justificacion:aprobar"
	PermJustificacionLeer    Permission = "justificacion:leer"

	// Reportes
	PermReporteExportar Permission = "reporte:exportar"
	PermReporteLeer     Permission = "reporte:leer"

	// Auditoría
	PermAuditoriaLeer Permission = "auditoria:leer"

	// Roles
	PermRolCrear  Permission = "rol:crear"
	PermRolEditar Permission = "rol:editar"
	PermRolLeer   Permission = "rol:leer"
)

// ─────────────────────────────────────────────
// Roles predefinidos del sistema — SRS §3.2
// ─────────────────────────────────────────────

type RoleName string

const (
	RolSuperadmin  RoleName = "SUPERADMIN"
	RolAdminInst   RoleName = "ADMIN_INSTITUCIONAL"
	RolCoordinador RoleName = "COORDINADOR"
	RolDocente     RoleName = "DOCENTE"
	RolEstudiante  RoleName = "ESTUDIANTE"
	RolMonitor     RoleName = "MONITOR"
	RolAuditor     RoleName = "AUDITOR"
)

// DefaultPermissions define los permisos de cada rol predefinido según §3.2.
var DefaultPermissions = map[RoleName][]Permission{
	RolSuperadmin: {
		PermMarcajeCrear, PermMarcajeLeer, PermMarcajeAjustar, PermMarcajeAnular,
		PermAulaLeer, PermAulaCrear, PermAulaEditar, PermAulaEditarGeometria, PermAulaEliminar,
		PermSedeAdministrar, PermBloqueAdministrar,
		PermHorarioCrear, PermHorarioLeer, PermAsignacionCrear, PermAsignacionEditar,
		PermParametroLeer, PermParametroEditar,
		PermUsuarioCrear, PermUsuarioEditar, PermUsuarioLeer, PermUsuarioEliminar,
		PermJustificacionCrear, PermJustificacionAprobar, PermJustificacionLeer,
		PermReporteExportar, PermReporteLeer,
		PermAuditoriaLeer,
		PermRolCrear, PermRolEditar, PermRolLeer,
	},
	RolAdminInst: {
		PermMarcajeLeer, PermMarcajeAjustar, PermMarcajeAnular,
		PermAulaLeer, PermAulaCrear, PermAulaEditar, PermAulaEditarGeometria, PermAulaEliminar,
		PermSedeAdministrar, PermBloqueAdministrar,
		PermHorarioCrear, PermHorarioLeer, PermAsignacionCrear, PermAsignacionEditar,
		PermParametroLeer, PermParametroEditar,
		PermUsuarioCrear, PermUsuarioEditar, PermUsuarioLeer,
		PermJustificacionAprobar, PermJustificacionLeer,
		PermReporteExportar, PermReporteLeer,
		PermAuditoriaLeer,
		PermRolLeer,
	},
	RolCoordinador: {
		PermMarcajeLeer,
		PermAulaLeer,
		PermHorarioCrear, PermHorarioLeer, PermAsignacionCrear, PermAsignacionEditar,
		PermParametroLeer,
		PermUsuarioLeer,
		PermJustificacionAprobar, PermJustificacionLeer,
		PermReporteExportar, PermReporteLeer,
	},
	RolDocente: {
		PermMarcajeCrear, PermMarcajeLeer,
		PermHorarioLeer,
		PermJustificacionCrear, PermJustificacionLeer,
	},
	RolEstudiante: {
		PermMarcajeCrear, PermMarcajeLeer,
		PermHorarioLeer,
	},
	RolMonitor: {
		PermMarcajeLeer,
		PermHorarioLeer,
		PermReporteLeer,
	},
	RolAuditor: {
		PermMarcajeLeer,
		PermAulaLeer,
		PermHorarioLeer,
		PermJustificacionLeer,
		PermReporteExportar, PermReporteLeer,
		PermAuditoriaLeer,
	},
}

// ─────────────────────────────────────────────
// Evaluador de permisos (función pura, ADR-02)
// ─────────────────────────────────────────────

// HasPermission comprueba si la lista de permisos del usuario incluye el permiso requerido.
// Es una función pura: sin base de datos, sin red.
func HasPermission(userPerms []Permission, required Permission) bool {
	for _, p := range userPerms {
		if p == required {
			return true
		}
	}
	return false
}

// HasAnyPermission comprueba si el usuario tiene al menos uno de los permisos requeridos.
func HasAnyPermission(userPerms []Permission, required ...Permission) bool {
	set := make(map[Permission]struct{}, len(userPerms))
	for _, p := range userPerms {
		set[p] = struct{}{}
	}
	for _, r := range required {
		if _, ok := set[r]; ok {
			return true
		}
	}
	return false
}

// ─────────────────────────────────────────────
// Ámbito ABAC — US-ROL-02
// ─────────────────────────────────────────────

// ScopeType define los tipos de ámbito de un usuario.
type ScopeType string

const (
	ScopeSede     ScopeType = "SEDE"
	ScopeFacultad ScopeType = "FACULTAD"
	ScopeBloque   ScopeType = "BLOQUE"
)

// Scope representa un par tipo+id de ámbito ABAC.
type Scope struct {
	Tipo ScopeType `json:"tipo" bson:"tipo"`
	ID   string    `json:"id"   bson:"id"`
}

// IsInScope comprueba si un recurso identificado por tipo+id cae dentro de los ámbitos del usuario.
// Un superadmin con ámbitos vacíos tiene acceso total.
func IsInScope(userScopes []Scope, resourceType ScopeType, resourceID string) bool {
	if len(userScopes) == 0 {
		// Sin ámbitos = acceso total (superadmin, ADR-02)
		return true
	}
	for _, s := range userScopes {
		if s.Tipo == resourceType && s.ID == resourceID {
			return true
		}
	}
	return false
}
