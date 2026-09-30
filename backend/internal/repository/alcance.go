package repository

import "github.com/siaa/backend/internal/domain/rbac"

// FiltroAlcance restringe una consulta a lo que el usuario puede ver (RF-ROL-003).
// nil significa sin restricción (roles globales).
type FiltroAlcance struct {
	// UsuarioID limita a los registros propios (docente, estudiante).
	UsuarioID string
	// Sedes y Facultades permitidas; si ambas están vacías la consulta no devuelve nada.
	Sedes      []string
	Facultades []string
}

// FiltroDeAlcance traduce el alcance del usuario al filtro de consulta.
func FiltroDeAlcance(a rbac.Alcance) *FiltroAlcance {
	if a.Global {
		return nil
	}
	if a.SoloPropios {
		return &FiltroAlcance{UsuarioID: a.UsuarioID}
	}
	return &FiltroAlcance{Sedes: a.Sedes, Facultades: a.Facultades}
}
