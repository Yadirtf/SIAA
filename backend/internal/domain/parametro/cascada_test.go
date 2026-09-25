// Pruebas unitarias de la cascada de herencia jerárquica de parámetros.
// US-PAR-02 AC-04: debe existir una batería que cubra cada nivel y sus combinaciones.
// ADR-02: función pura, cero dependencias externas.
package parametro_test

import (
	"testing"
	"time"

	"github.com/siaa/backend/internal/domain/parametro"
)

func makeParam(clave parametro.Clave, valor interface{}) *parametro.Parametro {
	return &parametro.Parametro{
		Clave:        clave,
		Valor:        valor,
		CreadoEn:     time.Now(),
		VigenteDesde: time.Now(),
	}
}

// TestResolverCascada_SinCapas verifica que sin capas se devuelven los valores por defecto (AC-02).
func TestResolverCascada_SinCapas(t *testing.T) {
	snap := parametro.ResolverCascada(nil)
	defaults := parametro.ValoresPorDefecto()

	for clave, valorEsperado := range defaults {
		pe, ok := snap[clave]
		if !ok {
			t.Errorf("clave %q ausente en snapshot sin capas", clave)
			continue
		}
		if pe.Origen.Nivel != parametro.AmbitoGlobal {
			t.Errorf("clave %q: nivel esperado GLOBAL, obtenido %q", clave, pe.Origen.Nivel)
		}
		if pe.Origen.Valor != valorEsperado {
			t.Errorf("clave %q: valor esperado %v, obtenido %v", clave, valorEsperado, pe.Origen.Valor)
		}
	}
}

// TestResolverCascada_SedeOverrideGlobal verifica que Sede sobreescribe Global (AC-01).
func TestResolverCascada_SedeOverrideGlobal(t *testing.T) {
	capas := []parametro.CapaNivel{
		{
			Ambito:   parametro.AmbitoSede,
			AmbitoID: "sede-001",
			Parametros: []*parametro.Parametro{
				makeParam(parametro.ClavePrecisionGpsMaxMetros, 50),
			},
		},
	}

	snap := parametro.ResolverCascada(capas)
	pe := snap[parametro.ClavePrecisionGpsMaxMetros]

	if pe.Origen.Nivel != parametro.AmbitoSede {
		t.Errorf("nivel esperado SEDE, obtenido %q", pe.Origen.Nivel)
	}
	if pe.Origen.NivelID != "sede-001" {
		t.Errorf("nivelID esperado 'sede-001', obtenido %q", pe.Origen.NivelID)
	}
	v, _ := pe.Origen.Valor.(int)
	if v != 50 {
		t.Errorf("valor esperado 50, obtenido %v", pe.Origen.Valor)
	}
}

// TestResolverCascada_AulaGanaFacultad verifica que Aula prevalece sobre Facultad (AC-01, AC-03).
func TestResolverCascada_AulaGanaFacultad(t *testing.T) {
	capas := []parametro.CapaNivel{
		{
			Ambito:   parametro.AmbitoFacultad,
			AmbitoID: "fac-ing",
			Parametros: []*parametro.Parametro{
				makeParam(parametro.ClaveBufferPerimetralMetros, 15),
			},
		},
		{
			Ambito:   parametro.AmbitoAula,
			AmbitoID: "aula-301",
			Parametros: []*parametro.Parametro{
				makeParam(parametro.ClaveBufferPerimetralMetros, 20),
			},
		},
	}

	snap := parametro.ResolverCascada(capas)
	pe := snap[parametro.ClaveBufferPerimetralMetros]

	if pe.Origen.Nivel != parametro.AmbitoAula {
		t.Errorf("nivel esperado AULA, obtenido %q", pe.Origen.Nivel)
	}
	v, _ := pe.Origen.Valor.(int)
	if v != 20 {
		t.Errorf("valor esperado 20, obtenido %v", pe.Origen.Valor)
	}
}

// TestResolverCascada_SoloUnaClaveOverride verifica que un nivel sobreescribe solo su clave (AC-03).
func TestResolverCascada_SoloUnaClaveOverride(t *testing.T) {
	capas := []parametro.CapaNivel{
		{
			Ambito:   parametro.AmbitoSede,
			AmbitoID: "sede-001",
			Parametros: []*parametro.Parametro{
				makeParam(parametro.ClaveUmbralTardanzaMin, 5),
			},
		},
	}

	snap := parametro.ResolverCascada(capas)

	// La clave override debe venir de Sede
	pe := snap[parametro.ClaveUmbralTardanzaMin]
	if pe.Origen.Nivel != parametro.AmbitoSede {
		t.Errorf("clave overrideada: nivel esperado SEDE, obtenido %q", pe.Origen.Nivel)
	}

	// El resto de claves deben venir de GLOBAL
	for clave, pe := range snap {
		if clave == parametro.ClaveUmbralTardanzaMin {
			continue
		}
		if pe.Origen.Nivel != parametro.AmbitoGlobal {
			t.Errorf("clave %q sin override debería venir de GLOBAL, obtenida de %q", clave, pe.Origen.Nivel)
		}
	}
}

// TestResolverCascada_AsignacionGanaTodo verifica que Asignación prevalece sobre todos (AC-01).
func TestResolverCascada_AsignacionGanaTodo(t *testing.T) {
	capas := []parametro.CapaNivel{
		{Ambito: parametro.AmbitoGlobal, Parametros: []*parametro.Parametro{
			makeParam(parametro.ClaveHolguraEntradaAntes, 20),
		}},
		{Ambito: parametro.AmbitoSede, AmbitoID: "s1", Parametros: []*parametro.Parametro{
			makeParam(parametro.ClaveHolguraEntradaAntes, 18),
		}},
		{Ambito: parametro.AmbitoFacultad, AmbitoID: "f1", Parametros: []*parametro.Parametro{
			makeParam(parametro.ClaveHolguraEntradaAntes, 12),
		}},
		{Ambito: parametro.AmbitoAsignacion, AmbitoID: "asig-999", Parametros: []*parametro.Parametro{
			makeParam(parametro.ClaveHolguraEntradaAntes, 7),
		}},
	}

	snap := parametro.ResolverCascada(capas)
	pe := snap[parametro.ClaveHolguraEntradaAntes]

	if pe.Origen.Nivel != parametro.AmbitoAsignacion {
		t.Errorf("nivel esperado ASIGNACION, obtenido %q", pe.Origen.Nivel)
	}
	v, _ := pe.Origen.Valor.(int)
	if v != 7 {
		t.Errorf("valor esperado 7, obtenido %v", pe.Origen.Valor)
	}
}

// TestValidate_FueraDeRango verifica que parámetros con valores inválidos fallan (US-PAR-01 AC-02).
func TestValidate_FueraDeRango(t *testing.T) {
	casos := []struct {
		clave  parametro.Clave
		valor  interface{}
		debeOk bool
	}{
		{parametro.ClavePrecisionGpsMaxMetros, 35, true},
		{parametro.ClavePrecisionGpsMaxMetros, 4, false},   // menor que mínimo
		{parametro.ClavePrecisionGpsMaxMetros, 201, false}, // mayor que máximo
		{parametro.ClaveUmbralTardanzaMin, 0, true},
		{parametro.ClaveUmbralTardanzaMin, 61, false},
		{parametro.ClaveBufferPerimetralMetros, 10, true},
		{parametro.ClaveBufferPerimetralMetros, 101, false},
	}

	for _, c := range casos {
		p := &parametro.Parametro{
			Clave:    c.clave,
			Valor:    c.valor,
			AutorID:  "usr-01",
			Ambito:   parametro.AmbitoGlobal,
			CreadoEn: time.Now(),
		}
		err := p.Validate()
		if c.debeOk && err != nil {
			t.Errorf("clave=%q valor=%v: esperado ok, error=%v", c.clave, c.valor, err)
		}
		if !c.debeOk && err == nil {
			t.Errorf("clave=%q valor=%v: esperado error, no se obtuvo", c.clave, c.valor)
		}
	}
}

// TestValidate_ClaveInvalida verifica que claves desconocidas son rechazadas (US-PAR-01 AC-02).
func TestValidate_ClaveInvalida(t *testing.T) {
	p := &parametro.Parametro{
		Clave:   "clave_inexistente",
		Valor:   99,
		AutorID: "usr-01",
		Ambito:  parametro.AmbitoGlobal,
	}
	if err := p.Validate(); err == nil {
		t.Error("se esperaba error por clave inválida")
	}
}

// TestExtraerValores verifica que ExtraerValores devuelve el mapa simple correcto.
func TestExtraerValores(t *testing.T) {
	snap := parametro.ResolverCascada(nil)
	m := parametro.ExtraerValores(snap)
	defaults := parametro.ValoresPorDefecto()

	if len(m) != len(defaults) {
		t.Errorf("tamaños no coinciden: %d vs %d", len(m), len(defaults))
	}
	for k, v := range defaults {
		if m[k] != v {
			t.Errorf("clave %q: esperado %v, obtenido %v", k, v, m[k])
		}
	}
}
