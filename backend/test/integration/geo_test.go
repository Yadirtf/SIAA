package integration

import (
	"net/http"
	"testing"
)

// EP-03: administración de sedes, bloques y espacios con su geometría versionada.
func TestGeo_AdministracionDeEspacios(t *testing.T) {
	e := nuevoEntorno(t)
	s := construirEscenario(e)
	a := s.admin

	if _, sedes := e.sinErrorInterno(http.MethodGet, "/sedes", nil, a); len(elementos(sedes)) == 0 {
		t.Fatalf("GET /sedes vacío: %v", sedes)
	}
	e.exigir(http.MethodGet, "/sedes/"+s.sede, nil, a, http.StatusOK)
	e.exigir(http.MethodGet, "/bloques?sedeId="+s.sede, nil, a, http.StatusOK)
	e.exigir(http.MethodGet, "/bloques/"+s.bloque, nil, a, http.StatusOK)
	e.sinErrorInterno(http.MethodGet, "/espacios?sedeId="+s.sede+"&bloqueId="+s.bloque, nil, a)
	e.exigir(http.MethodGet, "/espacios/"+s.espacio, nil, a, http.StatusOK)

	// Recursos inexistentes → 404, no 500.
	for _, r := range []string{"/sedes/", "/bloques/", "/espacios/"} {
		if estado, _ := e.llamar(http.MethodGet, r+"000000000000000000000000", nil, a); estado != http.StatusNotFound {
			t.Fatalf("GET %s inexistente: estado %d, esperado 404", r, estado)
		}
	}
	// Validación: sede sin código.
	if estado, _ := e.llamar(http.MethodPost, "/sedes", map[string]interface{}{"nombre": "Sin código"}, a); estado < 400 || estado >= 500 {
		t.Fatalf("sede inválida: estado %d", estado)
	}
	// Código de sede duplicado.
	e.sinErrorInterno(http.MethodPost, "/sedes", map[string]interface{}{"codigo": "SC", "nombre": "Duplicada"}, a)

	// Edición de datos y buffer perimetral.
	e.sinErrorInterno(http.MethodPatch, "/espacios/"+s.espacio2, map[string]interface{}{"nombre": "Aula 302 renovada", "capacidad": 40}, a)
	e.sinErrorInterno(http.MethodPatch, "/espacios/"+s.espacio2+"/buffer", map[string]interface{}{"bufferMetros": 5}, a)
	if estado, _ := e.llamar(http.MethodPatch, "/espacios/"+s.espacio2+"/buffer", map[string]interface{}{"bufferMetros": 500}, a); estado < 400 || estado >= 500 {
		t.Fatalf("buffer fuera de rango: estado %d", estado)
	}

	// Nueva versión de geometría y su historial.
	e.sinErrorInterno(http.MethodPut, "/espacios/"+s.espacio2+"/geometria", map[string]interface{}{
		"coordenadas": [][2]float64{
			{-76.65005, 1.14785}, {-76.64975, 1.14785}, {-76.64975, 1.14755}, {-76.65005, 1.14755}, {-76.65005, 1.14785},
		},
		"metodoCaptura": "RECORRIDO_PERIMETRAL", "precisionPromedioMetros": 5.0,
	}, a)
	e.sinErrorInterno(http.MethodGet, "/espacios/"+s.espacio2+"/geometria/versiones", nil, a)
	e.sinErrorInterno(http.MethodGet, "/espacios/"+s.espacio2+"/geometria/versiones/1", nil, a)
	e.sinErrorInterno(http.MethodGet, "/espacios/"+s.espacio2+"/geometria/versiones/99", nil, a)

	// Geometría solapada con el aula principal: se advierte y solo se acepta confirmando.
	e.sinErrorInterno(http.MethodPut, "/espacios/"+s.espacio2+"/geometria", map[string]interface{}{
		"coordenadas": poligonoAula, "metodoCaptura": "RECORRIDO_PERIMETRAL", "precisionPromedioMetros": 5.0,
	}, a)
	e.sinErrorInterno(http.MethodPut, "/espacios/"+s.espacio2+"/geometria", map[string]interface{}{
		"coordenadas": poligonoAula, "metodoCaptura": "RECORRIDO_PERIMETRAL", "precisionPromedioMetros": 5.0,
		"confirmarSolapamiento": true, "motivoSolapamiento": "Aulas contiguas con muro compartido",
	}, a)
	e.sinErrorInterno(http.MethodGet, "/espacios/solapamientos?sedeId="+s.sede, nil, a)

	// Validación topológica previa (US-GEO-04): polígono válido y autointersección.
	e.exigir(http.MethodPost, "/espacios/validar-geometria", map[string]interface{}{"coordenadas": poligonoAula}, a, http.StatusOK)
	e.sinErrorInterno(http.MethodPost, "/espacios/validar-geometria", map[string]interface{}{
		"coordenadas": [][2]float64{{-76.6512, 1.1478}, {-76.6510, 1.1476}, {-76.6510, 1.1478}, {-76.6512, 1.1476}, {-76.6512, 1.1478}},
	}, a)

	// Clonado de piso (US-GEO-08) e importación/exportación GeoJSON (US-GEO-11).
	e.sinErrorInterno(http.MethodPost, "/bloques/"+s.bloque+"/clonar-piso", map[string]interface{}{"pisoOrigen": 3, "pisoDestino": 2, "prefijoCodigo": "P2-"}, a)
	e.sinErrorInterno(http.MethodGet, "/espacios/exportar?sedeId="+s.sede, nil, a)
	e.sinErrorInterno(http.MethodGet, "/espacios/exportar?bloqueId="+s.bloque, nil, a)
	geojson := map[string]interface{}{
		"type": "FeatureCollection",
		"features": []map[string]interface{}{{
			"type":       "Feature",
			"properties": map[string]interface{}{"codigo": "LAB-1", "nombre": "Laboratorio 1", "tipo": "LABORATORIO", "piso": 1},
			"geometry": map[string]interface{}{"type": "Polygon", "coordinates": [][][2]float64{{
				{-76.6490, 1.1478}, {-76.6488, 1.1478}, {-76.6488, 1.1476}, {-76.6490, 1.1476}, {-76.6490, 1.1478},
			}}},
		}},
	}
	preview := e.exigir(http.MethodPost, "/espacios/importar/preview", geojson, a, http.StatusOK)
	e.sinErrorInterno(http.MethodPost, "/espacios/importar", map[string]interface{}{
		"sedeId": s.sede, "bloqueId": s.bloque, "piso": 1, "elementos": preview["elementos"],
	}, a)
	e.sinErrorInterno(http.MethodPost, "/espacios/importar/preview", map[string]interface{}{"type": "Invalido"}, a)

	// El docente no administra espacios.
	if estado, _ := e.llamar(http.MethodPost, "/sedes", map[string]interface{}{"codigo": "X", "nombre": "X"}, s.docente); estado != http.StatusForbidden {
		t.Fatalf("POST /sedes como docente: estado %d, esperado 403", estado)
	}

	// Un espacio con sesiones futuras no se elimina a ciegas; uno sin uso sí.
	e.sinErrorInterno(http.MethodDelete, "/espacios/"+s.espacio, nil, a)
	libre := e.exigir(http.MethodPost, "/espacios", map[string]interface{}{
		"sedeId": s.sede, "bloqueId": s.bloque, "piso": 1, "codigo": "BOD-1", "nombre": "Bodega", "capacidad": 1, "tipo": "AULA",
	}, a, http.StatusCreated)
	e.sinErrorInterno(http.MethodDelete, "/espacios/"+texto(libre["id"]), nil, a)
}
