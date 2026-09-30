// Package marcaje — traducción de los parámetros congelados de la sesión al motor de marcaje.
// RN-002 / ADR-05: el motor evalúa con los parámetros efectivos congelados al generar la sesión,
// no con valores fijos en código.
package marcaje

import (
	"strings"

	domainMarcaje "github.com/siaa/backend/internal/domain/marcaje"
	dompar "github.com/siaa/backend/internal/domain/parametro"
)

// parametrosPorDefecto son los valores del SRS §3.5 usados cuando la sesión no congeló una clave.
func parametrosPorDefecto() domainMarcaje.ParametrosMarcaje {
	return domainMarcaje.ParametrosMarcaje{
		HolguraEntradaAntesMin:   15,
		HolguraEntradaDespuesMin: 15,
		HolguraSalidaAntesMin:    10,
		HolguraSalidaDespuesMin:  20,
		PrecisionGpsMaxMetros:    35.0,
		UmbralTardanzaMin:        10,
		BloquearMockLocation:     true,
		BloquearRooteado:         false,
		DesfaseRelojMaxSegundos:  300,
		MarcajeSalidaModo:        "DESACTIVADO",
	}
}

// ParametrosDesdeSesion construye los parámetros del motor a partir del mapa congelado en la
// sesión. Acepta la clave del catálogo (snake_case) y su alias camelCase del SRS, porque los
// overrides de asignación pueden venir en cualquiera de los dos formatos.
func ParametrosDesdeSesion(congelados map[string]interface{}) domainMarcaje.ParametrosMarcaje {
	p := parametrosPorDefecto()
	if len(congelados) == 0 {
		return p
	}
	// Las claves snake_case del catálogo prevalecen sobre sus alias camelCase: se cargan
	// en una segunda pasada para que el resultado no dependa del orden del mapa.
	norm := make(map[string]interface{}, len(congelados))
	for k, v := range congelados {
		if !strings.Contains(k, "_") {
			norm[normalizarClave(k)] = v
		}
	}
	for k, v := range congelados {
		if strings.Contains(k, "_") {
			norm[normalizarClave(k)] = v
		}
	}
	buscar := func(claves ...string) (interface{}, bool) {
		for _, c := range claves {
			if v, ok := norm[normalizarClave(c)]; ok {
				return v, true
			}
		}
		return nil, false
	}
	leerInt := func(destino *int, claves ...string) {
		if v, ok := buscar(claves...); ok {
			if n, ok := aEntero(v); ok {
				*destino = n
			}
		}
	}
	leerBool := func(destino *bool, claves ...string) {
		if v, ok := buscar(claves...); ok {
			if b, ok := v.(bool); ok {
				*destino = b
			}
		}
	}

	leerInt(&p.HolguraEntradaAntesMin, string(dompar.ClaveHolguraEntradaAntes))
	leerInt(&p.HolguraEntradaDespuesMin, string(dompar.ClaveHolguraEntradaDespues))
	leerInt(&p.HolguraSalidaAntesMin, string(dompar.ClaveHolguraSalidaAntes))
	leerInt(&p.HolguraSalidaDespuesMin, string(dompar.ClaveHolguraSalidaDespues))
	leerInt(&p.UmbralTardanzaMin, string(dompar.ClaveUmbralTardanzaMin))
	if v, ok := buscar(string(dompar.ClavePrecisionGpsMaxMetros)); ok {
		if f, ok := aFlotante(v); ok {
			p.PrecisionGpsMaxMetros = f
		}
	}
	leerBool(&p.BloquearMockLocation, string(dompar.ClaveBloqueoMockLocation), "bloquearMockLocation")
	leerBool(&p.BloquearRooteado, string(dompar.ClaveBloqueoDispositivoRooteado), "bloquearDispositivoRooteado")
	leerBool(&p.ExigirAttestation, string(dompar.ClaveExigirAttestation))
	leerBool(&p.VerificacionComplementaria, string(dompar.ClaveVerificacionComplementaria))
	if v, ok := buscar(string(dompar.ClaveSalidaObligatoria)); ok {
		if modo, ok := v.(string); ok && modo != "" {
			p.MarcajeSalidaModo = modo
		}
	}
	if v, ok := buscar("marcajeSalidaObligatorio"); ok {
		if b, ok := v.(bool); ok && b {
			p.MarcajeSalidaModo = "OBLIGATORIO"
		}
	}
	return p
}

// ParametrosPublicos expone al cliente los valores con los que se evaluará su marcaje.
func ParametrosPublicos(p domainMarcaje.ParametrosMarcaje) map[string]interface{} {
	return map[string]interface{}{
		"holguraEntradaAntesMin":   p.HolguraEntradaAntesMin,
		"holguraEntradaDespuesMin": p.HolguraEntradaDespuesMin,
		"umbralTardanzaMin":        p.UmbralTardanzaMin,
		"precisionGpsMaxMetros":    p.PrecisionGpsMaxMetros,
		"bloquearMockLocation":     p.BloquearMockLocation,
		"marcajeSalida":            p.MarcajeSalidaModo,
		"exigirAttestation":        p.ExigirAttestation,
	}
}

// normalizarClave reduce "holgura_entrada_antes_min" y "holguraEntradaAntesMin" a la misma forma.
func normalizarClave(k string) string {
	return strings.ToLower(strings.ReplaceAll(k, "_", ""))
}

func aEntero(v interface{}) (int, bool) {
	switch x := v.(type) {
	case int:
		return x, true
	case int32:
		return int(x), true
	case int64:
		return int(x), true
	case float64:
		return int(x), true
	case float32:
		return int(x), true
	}
	return 0, false
}

func aFlotante(v interface{}) (float64, bool) {
	switch x := v.(type) {
	case float64:
		return x, true
	case float32:
		return float64(x), true
	case int:
		return float64(x), true
	case int32:
		return float64(x), true
	case int64:
		return float64(x), true
	}
	return 0, false
}
