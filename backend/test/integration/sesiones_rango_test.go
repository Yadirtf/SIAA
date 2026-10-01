package integration

import (
	"net/http"
	"testing"
	"time"
)

// La tabla de sesiones de la consola consulta una semana a la vez y ubica cada clase por
// aula, bloque y sede con nombres legibles.
func TestSesiones_RangoDeFechasYUbicacion(t *testing.T) {
	e := nuevoEntorno(t)
	s := construirEscenario(e)
	hoy := time.Now().In(bogota)
	dia := func(d int) string { return hoy.AddDate(0, 0, d).Format("2006-01-02") }

	semana := e.exigirLista("/sesiones?periodoId="+s.periodo+"&desde="+dia(-3)+"&hasta="+dia(3), s.admin)
	if len(semana) != 1 {
		t.Fatalf("en una semana la franja semanal ocurre una vez, hubo %d: %v", len(semana), semana)
	}
	clase := semana[0]
	if clase["fecha"] != dia(0) {
		t.Fatalf("la sesión de la semana debe ser la de hoy: %v", clase)
	}
	esperado := map[string]string{
		"asignaturaNombre": "Cálculo", "grupoNumero": "01", "espacioCodigo": "A-301",
		"bloqueId": s.bloque, "bloqueNombre": "Bloque 1", "sedeId": s.sede, "sedeNombre": "Sede Central",
	}
	for clave, valor := range esperado {
		if clase[clave] != valor {
			t.Fatalf("%s = %v, esperado %q", clave, clase[clave], valor)
		}
	}

	todas := e.exigirLista("/sesiones?periodoId="+s.periodo, s.admin)
	if len(todas) <= len(semana) {
		t.Fatalf("sin rango deben venir todas las sesiones del periodo: %d", len(todas))
	}
	if vacio := e.exigirLista("/sesiones?periodoId="+s.periodo+"&desde="+dia(1)+"&hasta="+dia(1), s.admin); len(vacio) != 0 {
		t.Fatalf("mañana no hay clase: %v", vacio)
	}

	for _, consulta := range []string{"desde=ayer", "desde=" + dia(3) + "&hasta=" + dia(-3), "desde=" + dia(0) + "&hasta=" + dia(400)} {
		e.exigir(http.MethodGet, "/sesiones?"+consulta, nil, s.admin, http.StatusUnprocessableEntity)
	}
}
