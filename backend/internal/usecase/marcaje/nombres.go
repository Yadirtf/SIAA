// Package marcaje — nombres legibles y fecha institucional de las sesiones del docente.
package marcaje

import (
	"context"
	"time"

	"github.com/siaa/backend/internal/repository"
)

// zonaInstitucional es la zona en la que se programan las sesiones (franjas en hora de Colombia).
// Con UTC, a partir de las 7 p. m. la "fecha de hoy" pasaba a ser la del día siguiente y el
// docente dejaba de ver sus clases nocturnas.
var zonaInstitucional = cargarZona()

func cargarZona() *time.Location {
	if loc, err := time.LoadLocation("America/Bogota"); err == nil {
		return loc
	}
	return time.FixedZone("COT", -5*60*60)
}

// fechaInstitucional devuelve la fecha (AAAA-MM-DD) del instante en la zona institucional.
func fechaInstitucional(t time.Time) string {
	return t.In(zonaInstitucional).Format("2006-01-02")
}

// WithEstructura permite mostrar nombres de asignatura y grupo en lugar de identificadores.
func (uc *SesionActivaUseCase) WithEstructura(r repository.EstructuraRepository) *SesionActivaUseCase {
	uc.estructuraRepo = r
	return uc
}

// nombreAsignatura devuelve el nombre de la asignatura, o su identificador si no se encuentra.
func (uc *SesionActivaUseCase) nombreAsignatura(ctx context.Context, id string) string {
	if uc.estructuraRepo != nil && id != "" {
		if a, err := uc.estructuraRepo.GetAsignaturaByID(ctx, id); err == nil && a != nil {
			return a.Nombre()
		}
	}
	return id
}

// numeroGrupo devuelve el número visible del grupo, o su identificador si no se encuentra.
func (uc *SesionActivaUseCase) numeroGrupo(ctx context.Context, id string) string {
	if uc.estructuraRepo != nil && id != "" {
		if g, err := uc.estructuraRepo.GetGrupoByID(ctx, id); err == nil && g != nil {
			return g.Numero()
		}
	}
	return id
}
