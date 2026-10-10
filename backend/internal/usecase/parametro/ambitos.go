// Package parametro — completar la cadena de ámbitos a partir de una asignación.
// US-PAR-03 AC-01: consultar los efectivos "para cualquier asignación" debe aplicar también
// la sede, la facultad, el bloque y el aula de esa asignación, sin que el cliente los envíe.
package parametro

import "context"

// FuenteAmbitos devuelve la cadena de ámbitos (sede, facultad, bloque, aula) de una asignación.
type FuenteAmbitos func(ctx context.Context, asignacionID string) (EspecCascada, error)

// WithFuenteAmbitos habilita la resolución completa a partir de solo asignacion_id.
func (uc *UseCase) WithFuenteAmbitos(f FuenteAmbitos) *UseCase {
	uc.ambitos = f
	return uc
}

// completarEspec rellena los ámbitos que el cliente no envió con los de la asignación.
// Lo que el cliente sí envió se respeta.
func (uc *UseCase) completarEspec(ctx context.Context, spec EspecCascada) EspecCascada {
	if uc.ambitos == nil || spec.AsignacionID == "" {
		return spec
	}
	derivada, err := uc.ambitos(ctx, spec.AsignacionID)
	if err != nil {
		return spec
	}
	rellenar := func(destino *string, valor string) {
		if *destino == "" {
			*destino = valor
		}
	}
	rellenar(&spec.SedeID, derivada.SedeID)
	rellenar(&spec.FacultadID, derivada.FacultadID)
	rellenar(&spec.BloqueID, derivada.BloqueID)
	rellenar(&spec.EspacioID, derivada.EspacioID)
	return spec
}
