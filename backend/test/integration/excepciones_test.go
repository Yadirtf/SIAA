package integration

import (
	"net/http"
	"testing"
)

// US-ACA-04 AC-03/AC-04/AC-05: una excepción posterior a la generación cancela las sesiones
// afectadas con motivo; al eliminarla se ofrece regenerar y la regeneración las recupera.
func TestExcepciones_CancelanYRecuperanSesiones(t *testing.T) {
	e := nuevoEntorno(t)
	s := construirEscenario(e)
	a := s.admin
	_, datos := e.llamar(http.MethodGet, "/sesiones?periodoId="+s.periodo, nil, a)
	lista := elementos(datos)
	if len(lista) < 2 {
		t.Fatalf("se esperaban sesiones generadas: %v", datos)
	}
	futura := lista[len(lista)-1]
	fecha := texto(futura["fecha"])
	excepcion := func(ambito, ambitoID string) map[string]interface{} {
		return e.exigir(http.MethodPost, "/calendario-excepciones", map[string]interface{}{
			"nombre": "Paro " + ambito, "tipo": "PARO", "ambito": ambito, "ambitoId": ambitoID,
			"fechaInicio": fecha, "fechaFin": fecha,
		}, a, http.StatusCreated)
	}
	estadoSesion := func() map[string]interface{} {
		return e.exigir(http.MethodGet, "/sesiones/"+texto(futura["id"]), nil, a, http.StatusOK)
	}

	// AC-05: una excepción de otra facultad no toca la sesión.
	if r := excepcion("FACULTAD", "000000000000000000000000"); r["sesionesCanceladas"] != float64(0) {
		t.Fatalf("excepción de otra facultad no debe cancelar: %v", r)
	}
	// AC-03: la excepción de su facultad la cancela con motivo.
	exc := excepcion("FACULTAD", s.facultad)
	if exc["sesionesCanceladas"] != float64(1) {
		t.Fatalf("se esperaba 1 sesión cancelada: %v", exc)
	}
	ses := estadoSesion()
	if ses["estado"] != "CANCELADA" || texto(ses["motivoCancelacion"]) != "Excepción de calendario: Paro FACULTAD (PARO)" {
		t.Fatalf("la sesión debe quedar cancelada con motivo: %v", ses)
	}

	// AC-04: eliminar ofrece regenerar, sin hacerlo automáticamente.
	lib := e.exigir(http.MethodDelete, "/calendario-excepciones/"+texto(exc["id"]), nil, a, http.StatusOK)
	if lib["sesionesReactivables"] != float64(1) || estadoSesion()["estado"] != "CANCELADA" {
		t.Fatalf("eliminar debe ofrecer regenerar sin reactivar solo: %v", lib)
	}
	gen := e.exigir(http.MethodPost, "/periodos/"+s.periodo+"/generar-sesiones", map[string]interface{}{}, a, http.StatusOK)
	if gen["sesionesReactivadas"] != float64(1) || estadoSesion()["estado"] != "PROGRAMADA" {
		t.Fatalf("regenerar debe recuperar la sesión: %v", gen)
	}
}
