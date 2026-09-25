// Package parametro implementa la entidad de parámetro y la cascada de herencia jerárquica.
// US-PAR-01: parámetros base con valores por defecto del SRS §3.5.
// US-PAR-02: herencia Global → Sede → Facultad → Bloque → Aula → Asignación.
// ADR-02: dominio puro, sin dependencias externas.
package parametro

import (
	"errors"
	"time"
)

// Ambito identifica el nivel jerárquico de un parámetro (de menos a más específico).
type Ambito string

const (
	AmbitoGlobal     Ambito = "GLOBAL"
	AmbitoSede       Ambito = "SEDE"
	AmbitoFacultad   Ambito = "FACULTAD"
	AmbitoBloque     Ambito = "BLOQUE"
	AmbitoAula       Ambito = "AULA"
	AmbitoAsignacion Ambito = "ASIGNACION"
)

// Clave identifica de forma única un parámetro configurable.
type Clave string

const (
	// Holguras de entrada (minutos)
	ClaveHolguraEntradaAntes   Clave = "holgura_entrada_antes_min"
	ClaveHolguraEntradaDespues Clave = "holgura_entrada_despues_min"

	// Umbral de tardanza (minutos desde inicio)
	ClaveUmbralTardanzaMin Clave = "umbral_tardanza_min"

	// Holguras de salida (minutos)
	ClaveHolguraSalidaAntes   Clave = "holgura_salida_antes_min"
	ClaveHolguraSalidaDespues Clave = "holgura_salida_despues_min"

	// GPS
	ClavePrecisionGpsMaxMetros   Clave = "precision_gps_max_metros"
	ClaveBufferPerimetralMetros  Clave = "buffer_perimetral_metros"
	ClavePromedioLecturasVertice Clave = "promedio_lecturas_vertice"

	// Interruptores de comportamiento
	ClaveSalidaObligatoria          Clave = "salida_obligatoria" // "OBLIGATORIO"|"OPCIONAL"|"DESACTIVADO"
	ClaveOfflinePermitido           Clave = "offline_permitido"
	ClaveBloqueoMockLocation        Clave = "bloqueo_mock_location"
	ClaveBloqueoDispositivoRooteado Clave = "bloqueo_dispositivo_rooteado"
	ClaveVerificacionComplementaria Clave = "verificacion_complementaria"
)

// ValoresPorDefecto retorna la tabla de defaults del SRS §3.5 (US-PAR-01 AC-01).
// Esta función pura es la única fuente de verdad para los valores iniciales.
func ValoresPorDefecto() map[Clave]interface{} {
	return map[Clave]interface{}{
		ClaveHolguraEntradaAntes:        15,
		ClaveHolguraEntradaDespues:      15,
		ClaveUmbralTardanzaMin:          10,
		ClaveHolguraSalidaAntes:         10,
		ClaveHolguraSalidaDespues:       20,
		ClavePrecisionGpsMaxMetros:      35,
		ClaveBufferPerimetralMetros:     10,
		ClavePromedioLecturasVertice:    5,
		ClaveSalidaObligatoria:          "DESACTIVADO",
		ClaveOfflinePermitido:           true,
		ClaveBloqueoMockLocation:        true,
		ClaveBloqueoDispositivoRooteado: false,
		ClaveVerificacionComplementaria: false,
	}
}

// RangosValidos define los rangos permitidos para parámetros numéricos (US-PAR-01 AC-02).
var RangosValidos = map[Clave][2]int{
	ClaveHolguraEntradaAntes:     {0, 120},
	ClaveHolguraEntradaDespues:   {0, 120},
	ClaveUmbralTardanzaMin:       {0, 60},
	ClaveHolguraSalidaAntes:      {0, 60},
	ClaveHolguraSalidaDespues:    {0, 120},
	ClavePrecisionGpsMaxMetros:   {5, 200},
	ClaveBufferPerimetralMetros:  {0, 100},
	ClavePromedioLecturasVertice: {1, 20},
}

// ErrFueraDeRango indica que el valor no está en el rango permitido.
var ErrFueraDeRango = errors.New("valor fuera del rango permitido")

// ErrClaveInvalida indica que la clave de parámetro no existe en el catálogo.
var ErrClaveInvalida = errors.New("clave de parámetro no reconocida")

// Parametro representa una entrada de configuración en un nivel jerárquico concreto.
type Parametro struct {
	ID            string      `bson:"_id,omitempty"`
	Ambito        Ambito      `bson:"ambito"`
	AmbitoID      string      `bson:"ambito_id"` // "" cuando Ambito==GLOBAL
	Clave         Clave       `bson:"clave"`
	Valor         interface{} `bson:"valor"`
	ValorAnterior interface{} `bson:"valor_anterior,omitempty"`
	AutorID       string      `bson:"autor_id"`
	VigenteDesde  time.Time   `bson:"vigente_desde"`
	CreadoEn      time.Time   `bson:"creado_en"`
}

// Validate verifica que la clave esté en el catálogo y el valor en el rango admitido.
func (p *Parametro) Validate() error {
	defaults := ValoresPorDefecto()
	if _, ok := defaults[p.Clave]; !ok {
		return ErrClaveInvalida
	}
	if rango, ok := RangosValidos[p.Clave]; ok {
		v, ok := toInt(p.Valor)
		if !ok {
			return ErrFueraDeRango
		}
		if v < rango[0] || v > rango[1] {
			return ErrFueraDeRango
		}
	}
	return nil
}

func toInt(v interface{}) (int, bool) {
	switch x := v.(type) {
	case int:
		return x, true
	case int64:
		return int(x), true
	case float64:
		return int(x), true
	case int32:
		return int(x), true
	}
	return 0, false
}
