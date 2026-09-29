package unit

import (
	"regexp"
	"testing"

	"github.com/siaa/backend/internal/domain/shared"
	ucmarcaje "github.com/siaa/backend/internal/usecase/marcaje"
)

// RN-002 / ADR-05: el motor usa los parámetros congelados en la sesión.
func TestParametrosDesdeSesion_UsaValoresCongelados(t *testing.T) {
	p := ucmarcaje.ParametrosDesdeSesion(map[string]interface{}{
		"holgura_entrada_despues_min": int32(20),
		"precision_gps_max_metros":    int64(50),
		"umbralTardanzaMin":           float64(5),
		"bloquearMockLocation":        false,
		"marcajeSalidaObligatorio":    true,
	})
	if p.HolguraEntradaDespuesMin != 20 {
		t.Errorf("holgura después = %d, want 20", p.HolguraEntradaDespuesMin)
	}
	if p.PrecisionGpsMaxMetros != 50 {
		t.Errorf("precisión = %v, want 50", p.PrecisionGpsMaxMetros)
	}
	if p.UmbralTardanzaMin != 5 {
		t.Errorf("umbral tardanza = %d, want 5", p.UmbralTardanzaMin)
	}
	if p.BloquearMockLocation {
		t.Error("bloquear mock debería ser false")
	}
	if p.MarcajeSalidaModo != "OBLIGATORIO" {
		t.Errorf("modo salida = %q, want OBLIGATORIO", p.MarcajeSalidaModo)
	}
}

func TestParametrosDesdeSesion_SinCongeladosUsaDefectos(t *testing.T) {
	p := ucmarcaje.ParametrosDesdeSesion(nil)
	if p.HolguraEntradaAntesMin != 15 || p.PrecisionGpsMaxMetros != 35 || !p.BloquearMockLocation {
		t.Errorf("defectos inesperados: %+v", p)
	}
	pub := ucmarcaje.ParametrosPublicos(p)
	if pub["holguraEntradaDespuesMin"] != 15 {
		t.Errorf("público holguraEntradaDespuesMin = %v", pub["holguraEntradaDespuesMin"])
	}
}

// El ID de aplicación debe ser un ObjectID válido para coincidir con el _id persistido.
func TestNewID_FormatoObjectIDUnico(t *testing.T) {
	re := regexp.MustCompile(`^[0-9a-f]{24}$`)
	vistos := map[string]bool{}
	for i := 0; i < 1000; i++ {
		id := shared.NewID()
		if !re.MatchString(id) {
			t.Fatalf("ID %q no es un ObjectID hexadecimal", id)
		}
		if vistos[id] {
			t.Fatalf("ID duplicado %q", id)
		}
		vistos[id] = true
	}
}

// Una sesión con la clave del catálogo y su alias heredado usa siempre la del catálogo.
func TestParametrosDesdeSesion_ClaveCatalogoPrevaleceSobreAlias(t *testing.T) {
	for i := 0; i < 200; i++ {
		p := ucmarcaje.ParametrosDesdeSesion(map[string]interface{}{
			"holguraEntradaDespuesMin":    15,
			"holgura_entrada_despues_min": 20,
		})
		if p.HolguraEntradaDespuesMin != 20 {
			t.Fatalf("iteración %d: holgura = %d, want 20", i, p.HolguraEntradaDespuesMin)
		}
	}
}
