// Package parametro — función pura de resolución de la cascada jerárquica.
// US-PAR-02: herencia Global → Sede → Facultad → Bloque → Aula → Asignación.
// ADR-02: función pura, cero dependencias externas, 100% probable sin red.
package parametro

// OrigenResolucion describe de qué nivel vino el valor resuelto para una clave.
type OrigenResolucion struct {
	Nivel   Ambito      `json:"nivel"`
	NivelID string      `json:"nivel_id"` // "" para GLOBAL
	Valor   interface{} `json:"valor"`
}

// ParametroEfectivo es el resultado de resolver la cascada para un ámbito específico.
// US-PAR-03 AC-01: cada clave incluye su valor y el nivel de origen.
type ParametroEfectivo struct {
	Clave  Clave            `json:"clave"`
	Origen OrigenResolucion `json:"origen"`
}

// Snapshot es la vista completa de parámetros efectivos para un ámbito dado.
// Se construye como una función pura sin efectos secundarios.
type Snapshot map[Clave]ParametroEfectivo

// NivelJerarquia define la precedencia de menor a mayor especificidad.
// El orden de esta slice determina qué nivel sobreescribe a cuál.
var NivelJerarquia = []Ambito{
	AmbitoGlobal,
	AmbitoSede,
	AmbitoFacultad,
	AmbitoBloque,
	AmbitoAula,
	AmbitoAsignacion,
}

// ResolverCascada implementa la función pura de herencia jerárquica (US-PAR-02).
//
// Recibe una lista de capas, cada una asociada a un ámbito y su conjunto de parámetros.
// Aplica resolución clave por clave: el valor del nivel más específico prevalece.
// Si ningún nivel define la clave, se usa el valor por defecto global (US-PAR-02 AC-02).
//
// Parámetros:
//
//	capas — slice de PorNivel ordenado de menor a mayor especificidad.
//
// La función es determinista y no tiene efectos secundarios.
func ResolverCascada(capas []CapaNivel) Snapshot {
	defaults := ValoresPorDefecto()
	resultado := make(Snapshot, len(defaults))

	// Inicializar con valores por defecto (nivel GLOBAL implícito)
	for clave, valor := range defaults {
		resultado[clave] = ParametroEfectivo{
			Clave: clave,
			Origen: OrigenResolucion{
				Nivel:   AmbitoGlobal,
				NivelID: "",
				Valor:   valor,
			},
		}
	}

	// Aplicar capas de menor a mayor especificidad (US-PAR-02 AC-01, AC-03).
	// Cada nivel sobreescribe solo las claves que define explícitamente.
	for _, capa := range capas {
		for _, p := range capa.Parametros {
			resultado[p.Clave] = ParametroEfectivo{
				Clave: p.Clave,
				Origen: OrigenResolucion{
					Nivel:   capa.Ambito,
					NivelID: capa.AmbitoID,
					Valor:   p.Valor,
				},
			}
		}
	}

	return resultado
}

// CapaNivel agrupa los parámetros definidos explícitamente para un nivel jerárquico.
type CapaNivel struct {
	Ambito     Ambito
	AmbitoID   string
	Parametros []*Parametro
}

// ExtraerValores convierte un Snapshot al mapa simple clave→valor
// que se congela en la sesión (RN-002, US-ACA-05 AC-02).
func ExtraerValores(s Snapshot) map[Clave]interface{} {
	m := make(map[Clave]interface{}, len(s))
	for k, v := range s {
		m[k] = v.Origen.Valor
	}
	return m
}
