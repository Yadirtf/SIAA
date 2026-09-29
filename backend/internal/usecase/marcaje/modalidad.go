// Package marcaje — modalidad de la sesión según su asignación (RF-ACA-013).
package marcaje

import (
	"context"

	"github.com/siaa/backend/internal/repository"
)

// modalidadDeAsignacion devuelve PRESENCIAL, VIRTUAL o HIBRIDA. Si no hay repositorio o la
// asignación no existe se asume PRESENCIAL, que es la opción que exige geocerca.
func modalidadDeAsignacion(ctx context.Context, repo repository.AsignacionRepository, asignacionID string) string {
	if repo == nil || asignacionID == "" {
		return "PRESENCIAL"
	}
	asig, err := repo.GetByID(ctx, asignacionID)
	if err != nil || asig == nil || asig.Modalidad() == "" {
		return "PRESENCIAL"
	}
	return string(asig.Modalidad())
}
