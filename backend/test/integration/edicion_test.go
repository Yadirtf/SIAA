package integration

import (
	"net/http"
	"testing"
	"time"
)

// Editar una asignación a mitad de semestre cambia solo las sesiones que aún no ocurren; las
// pasadas y la de hoy (ventana abierta) se conservan. Eliminarla cancela las futuras.
func TestAsignacion_EdicionReemplazaSoloSesionesFuturas(t *testing.T) {
	e := nuevoEntorno(t)
	s := construirEscenario(e)
	ahora := time.Now()

	sesiones := func() (pasadas, futuras []map[string]interface{}) {
		_, crudo := e.llamar(http.MethodGet, "/sesiones?asignacionId="+s.asignacion, nil, s.admin)
		for _, ses := range elementos(crudo) {
			abre, _ := time.Parse(time.RFC3339, texto(ses["ventanaEntradaAbre"]))
			if abre.After(ahora) {
				futuras = append(futuras, ses)
			} else {
				pasadas = append(pasadas, ses)
			}
		}
		return
	}
	pasadasAntes, futurasAntes := sesiones()
	if len(pasadasAntes) == 0 || len(futurasAntes) == 0 {
		t.Fatalf("el escenario debe tener sesiones pasadas y futuras: %d/%d", len(pasadasAntes), len(futurasAntes))
	}

	_, crudo := e.llamar(http.MethodGet, "/asignaciones", nil, s.admin)
	franja, _ := elementos(crudo)[0]["franja"].(map[string]interface{})
	diaNuevo := int(franja["diaSemana"].(float64))%7 + 1
	editada := e.exigir(http.MethodPut, "/asignaciones/"+s.asignacion, map[string]interface{}{
		"grupoId": s.grupo, "docenteIds": []string{s.docenteID}, "espacioId": s.espacio2, "modalidad": "PRESENCIAL",
		"franja": map[string]interface{}{"diaSemana": diaNuevo, "horaInicio": franja["horaInicio"], "horaFin": franja["horaFin"]},
	}, s.admin, http.StatusOK)
	if int(editada["sesionesReemplazadas"].(float64)) != len(futurasAntes) || editada["sesionesGeneradas"].(float64) < 1 {
		t.Fatalf("debe reemplazar las %d sesiones futuras: %v", len(futurasAntes), editada)
	}
	if editada["espacioNombre"] != "A-302 · Aula 302" {
		t.Fatalf("el aula editada debe guardarse: %v", editada)
	}

	pasadas, futuras := sesiones()
	if len(pasadas) != len(pasadasAntes) {
		t.Fatalf("las sesiones pasadas no se tocan: antes %d, ahora %d", len(pasadasAntes), len(pasadas))
	}
	for _, ses := range pasadas {
		if ses["espacioId"] != s.espacio {
			t.Fatalf("una sesión pasada cambió de aula: %v", ses)
		}
	}
	for _, ses := range futuras {
		fecha, _ := time.Parse("2006-01-02", texto(ses["fecha"]))
		if ses["espacioId"] != s.espacio2 || int(fecha.Weekday()+6)%7+1 != diaNuevo {
			t.Fatalf("las sesiones futuras deben seguir la asignación editada: %v", ses)
		}
	}

	// Eliminar la asignación cancela las sesiones futuras con un motivo legible.
	e.exigir(http.MethodDelete, "/asignaciones/"+s.asignacion, nil, s.admin, http.StatusNoContent)
	_, futuras = sesiones()
	for _, ses := range futuras {
		if ses["estado"] != "CANCELADA" || ses["motivoCancelacion"] != "Asignación eliminada" {
			t.Fatalf("una sesión futura de una asignación eliminada debe quedar cancelada: %v", ses)
		}
	}
}

// Sedes, bloques y la estructura curricular se corrigen sin recrearlos.
func TestEdicion_EstructuraSedesYBloques(t *testing.T) {
	e := nuevoEntorno(t)
	s := construirEscenario(e)
	put := func(ruta string, cuerpo map[string]interface{}) map[string]interface{} {
		return e.exigir(http.MethodPut, ruta, cuerpo, s.admin, http.StatusOK)
	}

	if f := put("/facultades/"+s.facultad, map[string]interface{}{"codigo": "FING", "nombre": "Facultad de Ingeniería"}); f["nombre"] != "Facultad de Ingeniería" || f["sedeId"] != s.sede {
		t.Fatalf("facultad: %v", f)
	}
	if p := put("/programas/"+s.programa, map[string]interface{}{"codigo": "SIS", "nombre": "Ingeniería de Sistemas"}); p["nombre"] != "Ingeniería de Sistemas" {
		t.Fatalf("programa: %v", p)
	}
	if a := put("/asignaturas/"+s.asignatura, map[string]interface{}{"codigo": "MAT1", "nombre": "Cálculo I", "creditos": 4}); a["nombre"] != "Cálculo I" || a["creditos"].(float64) != 4 {
		t.Fatalf("asignatura: %v", a)
	}
	if g := put("/grupos/"+s.grupo, map[string]interface{}{"numero": "01A", "cupo": 40}); g["numero"] != "01A" || g["periodoId"] != s.periodo {
		t.Fatalf("grupo: %v", g)
	}
	e.exigir(http.MethodPut, "/asignaturas/"+s.asignatura, map[string]interface{}{"codigo": "", "nombre": "x"}, s.admin, http.StatusBadRequest)

	if sede := put("/sedes/"+s.sede, map[string]interface{}{"codigo": "SC", "nombre": "Sede Centro", "direccion": "Calle 5"}); sede["nombre"] != "Sede Centro" {
		t.Fatalf("sede: %v", sede)
	}
	otra := texto(e.exigir(http.MethodPost, "/sedes", map[string]interface{}{"codigo": "SN", "nombre": "Norte"}, s.admin, http.StatusCreated)["id"])
	e.exigir(http.MethodPut, "/sedes/"+otra, map[string]interface{}{"codigo": "SC", "nombre": "Norte"}, s.admin, http.StatusConflict)

	b := put("/bloques/"+s.bloque, map[string]interface{}{"codigo": "B1", "nombre": "Bloque Principal", "pisos": []int{4}})
	if pisos, _ := b["pisos"].([]interface{}); b["nombre"] != "Bloque Principal" || len(pisos) != 4 {
		t.Fatalf("el bloque conserva sus pisos y agrega los nuevos: %v", b)
	}
}
