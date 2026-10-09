// Package app — cableado de la cascada de parámetros hacia académico, reportes y alertas.
package app

import (
	"context"

	dompar "github.com/siaa/backend/internal/domain/parametro"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/repository"
	usecaseAca "github.com/siaa/backend/internal/usecase/academico"
	usecasePar "github.com/siaa/backend/internal/usecase/parametro"
)

// resolutorAcademico entrega a la generación de sesiones los valores efectivos de la cascada (RN-002).
func resolutorAcademico(svc *usecasePar.UseCase) func(context.Context, usecaseAca.AmbitoParametros) (map[string]interface{}, error) {
	return func(ctx context.Context, a usecaseAca.AmbitoParametros) (map[string]interface{}, error) {
		snap, err := svc.ResolverEfectivos(ctx, usecasePar.EspecCascada{
			SedeID:       a.SedeID,
			FacultadID:   a.FacultadID,
			BloqueID:     a.BloqueID,
			EspacioID:    a.EspacioID,
			AsignacionID: a.AsignacionID,
		})
		if err != nil {
			return nil, err
		}
		valores := make(map[string]interface{}, len(snap))
		for clave, efectivo := range snap {
			valores[string(clave)] = efectivo.Origen.Valor
		}
		return valores, nil
	}
}

// fuenteAmbitos deriva sede, facultad, bloque y aula de una asignación (US-PAR-03 AC-01).
func fuenteAmbitos(asignaciones repository.AsignacionRepository, periodos repository.PeriodoRepository, espacios repository.EspacioRepository) usecasePar.FuenteAmbitos {
	return func(ctx context.Context, asignacionID string) (usecasePar.EspecCascada, error) {
		asig, err := asignaciones.GetByID(ctx, asignacionID)
		if err != nil || asig == nil {
			return usecasePar.EspecCascada{}, shared.NewNotFoundError("Asignacion", asignacionID)
		}
		spec := usecasePar.EspecCascada{FacultadID: asig.FacultadID(), EspacioID: asig.EspacioID()}
		if p, errP := periodos.GetByID(ctx, asig.PeriodoID()); errP == nil && p != nil {
			spec.SedeID = p.SedeID()
		}
		if asig.EspacioID() != "" {
			if esp, errE := espacios.FindByID(ctx, asig.EspacioID()); errE == nil && esp != nil {
				if esp.SedeID != "" {
					spec.SedeID = esp.SedeID
				}
				if esp.BloqueID != nil {
					spec.BloqueID = *esp.BloqueID
				}
			}
		}
		return spec, nil
	}
}

// umbralAsistencia resuelve porcentaje_minimo_asistencia para una facultad (y su sede), o el
// global cuando no se indica facultad (US-PAR-04 AC-01).
func umbralAsistencia(svc *usecasePar.UseCase, estructura repository.EstructuraRepository) func(context.Context, string) float64 {
	return func(ctx context.Context, facultadID string) float64 {
		spec := usecasePar.EspecCascada{FacultadID: facultadID}
		if facultadID != "" {
			if f, err := estructura.GetFacultadByID(ctx, facultadID); err == nil && f != nil {
				spec.SedeID = f.SedeID()
			}
		}
		snap, err := svc.ResolverEfectivos(ctx, spec)
		if err == nil {
			if v, ok := numero(snap[dompar.ClavePorcentajeMinimoAsistencia].Origen.Valor); ok {
				return v
			}
		}
		return 80
	}
}

// umbralInasistencias resuelve inasistencias_consecutivas_alerta de la facultad (US-PAR-04 AC-02).
func umbralInasistencias(svc *usecasePar.UseCase, estructura repository.EstructuraRepository) func(context.Context, string) int {
	return func(ctx context.Context, facultadID string) int {
		spec := usecasePar.EspecCascada{FacultadID: facultadID}
		if f, err := estructura.GetFacultadByID(ctx, facultadID); err == nil && f != nil {
			spec.SedeID = f.SedeID()
		}
		if snap, err := svc.ResolverEfectivos(ctx, spec); err == nil {
			if v, ok := numero(snap[dompar.ClaveInasistenciasConsecutivasAlerta].Origen.Valor); ok {
				return int(v)
			}
		}
		return 3
	}
}

func numero(v interface{}) (float64, bool) {
	switch x := v.(type) {
	case int:
		return float64(x), true
	case int32:
		return float64(x), true
	case int64:
		return float64(x), true
	case float64:
		return x, true
	}
	return 0, false
}
