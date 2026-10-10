package rbac

// ─────────────────────────────────────────────
// Alcance efectivo de un usuario — RF-ROL-003, CA-010
// ─────────────────────────────────────────────

// Alcance resume qué datos operativos puede ver y operar un usuario según su rol activo,
// sus permisos y sus ámbitos. Se evalúa siempre en el backend (RF-ROL-003).
//
//   - Global: superadmin, administrador institucional y auditor ven toda la institución.
//   - SoloPropios: quien marca asistencia sin poder ajustarla (docente, estudiante) solo ve
//     sus propios registros.
//   - Por ámbito: el resto (coordinador, monitor, roles personalizados) ve únicamente las
//     sedes y facultades asignadas. Sin ámbitos asignados no ve nada.
type Alcance struct {
	Global      bool
	SoloPropios bool
	UsuarioID   string
	Sedes       []string
	Facultades  []string
	Bloques     []string
}

// rolesGlobales operan sobre toda la institución (matriz de permisos base, §3.2).
var rolesGlobales = map[RoleName]bool{
	RolSuperadmin: true,
	RolAdminInst:  true,
	RolAuditor:    true,
}

// EsRolGlobal indica si el rol opera sobre toda la institución sin ámbitos asignados
// (superadministrador, administrador institucional y auditor).
func EsRolGlobal(rol string) bool { return rolesGlobales[RoleName(rol)] }

// NuevoAlcance calcula el alcance a partir del rol activo, los permisos y los ámbitos.
func NuevoAlcance(rolActivo string, permisos []Permission, usuarioID string, ambitos []Scope) Alcance {
	a := Alcance{UsuarioID: usuarioID}
	if rolesGlobales[RoleName(rolActivo)] {
		a.Global = true
		return a
	}
	if HasPermission(permisos, PermMarcajeCrear) && !HasPermission(permisos, PermMarcajeAjustar) {
		a.SoloPropios = true
		return a
	}
	for _, s := range ambitos {
		switch s.Tipo {
		case ScopeSede:
			a.Sedes = append(a.Sedes, s.ID)
		case ScopeFacultad:
			a.Facultades = append(a.Facultades, s.ID)
		case ScopeBloque:
			a.Bloques = append(a.Bloques, s.ID)
		}
	}
	return a
}

// PorAmbito indica que el acceso depende de sedes y facultades asignadas.
func (a Alcance) PorAmbito() bool { return !a.Global && !a.SoloPropios }

// PermiteSede indica si la sede está asignada directamente al usuario.
func (a Alcance) PermiteSede(sedeID string) bool {
	return a.Global || (sedeID != "" && contiene(a.Sedes, sedeID))
}

// PermiteFacultad indica si una facultad (que pertenece a sedeID) está dentro del alcance:
// por asignación directa de la facultad o por tener asignada su sede completa.
func (a Alcance) PermiteFacultad(facultadID, sedeID string) bool {
	if a.Global {
		return true
	}
	return (facultadID != "" && contiene(a.Facultades, facultadID)) || (sedeID != "" && contiene(a.Sedes, sedeID))
}

// PermiteRegistroDe indica si el usuario puede ver un registro operativo (sesión, marcaje)
// de otro usuario, ubicado en la facultad y sede dadas.
func (a Alcance) PermiteRegistroDe(duenoID, facultadID, sedeID string) bool {
	if a.SoloPropios {
		return duenoID == a.UsuarioID
	}
	return a.PermiteFacultad(facultadID, sedeID)
}

func contiene(lista []string, v string) bool {
	for _, x := range lista {
		if x == v {
			return true
		}
	}
	return false
}

// PermiteSesion indica si una sesión (con sus docentes, facultad y sede) está en el alcance.
func (a Alcance) PermiteSesion(docenteIDs []string, facultadID, sedeID string) bool {
	if a.SoloPropios {
		return contiene(docenteIDs, a.UsuarioID)
	}
	return a.PermiteFacultad(facultadID, sedeID)
}
