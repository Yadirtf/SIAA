package integration

import (
	"net/http"
	"net/http/httptest"
	"strconv"
	"strings"
	"testing"
)

const kmlImportable = `<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2"><Document>
 <Placemark><name>Sala de cómputo</name>
  <ExtendedData><Data name="codigo"><value>KML-1</value></Data><Data name="capacidad"><value>20</value></Data></ExtendedData>
  <Polygon><outerBoundaryIs><LinearRing><coordinates>
   -76.6480,1.1478,0 -76.6478,1.1478,0 -76.6478,1.1476,0 -76.6480,1.1476,0 -76.6480,1.1478,0
  </coordinates></LinearRing></outerBoundaryIs></Polygon></Placemark>
 <Placemark><name>KML-2</name><description>Aula invertida</description>
  <Polygon><outerBoundaryIs><LinearRing><coordinates>
   1.1478,-76.6470 1.1478,-76.6468 1.1476,-76.6468 1.1476,-76.6470 1.1478,-76.6470
  </coordinates></LinearRing></outerBoundaryIs></Polygon></Placemark>
</Document></kml>`

// crudo ejecuta una petición con cabeceras propias y devuelve el registro completo.
func (e *entorno) crudo(metodo, ruta, tipo, cuerpo, token string, cabeceras map[string]string) *httptest.ResponseRecorder {
	e.t.Helper()
	req := httptest.NewRequest(metodo, "/api/v1"+ruta, strings.NewReader(cuerpo))
	req.Header.Set("Content-Type", tipo)
	req.Header.Set("Authorization", "Bearer "+token)
	for k, v := range cabeceras {
		req.Header.Set(k, v)
	}
	rec := httptest.NewRecorder()
	e.app.Router.ServeHTTP(rec, req)
	return rec
}

// US-GEO-11: importación KML con la misma validación que GeoJSON y exportación KML real.
func TestGeo_ImportacionYExportacionKML(t *testing.T) {
	e := nuevoEntorno(t)
	s := construirEscenario(e)

	estado, datos := e.enviarTexto(http.MethodPost, "/espacios/importar/preview", "application/vnd.google-earth.kml+xml", kmlImportable, s.admin)
	preview, _ := datos.(map[string]interface{})
	if estado != http.StatusOK || preview["formato"] != "kml" || preview["validos"] != float64(2) {
		t.Fatalf("preview KML: estado %d %v", estado, datos)
	}
	elems := elementos(preview["elementos"])
	if elems[1]["codigo"] != "KML-2" || elems[1]["coordenadasInvertidas"] != true {
		t.Fatalf("AC-04 en KML: %v", elems[1])
	}

	confirmado := e.exigir(http.MethodPost, "/espacios/importar", map[string]interface{}{
		"sedeId": s.sede, "bloqueId": s.bloque, "piso": 1, "elementos": preview["elementos"],
	}, s.admin, http.StatusCreated)
	if confirmado["totalImportados"] != float64(2) {
		t.Fatalf("confirmación KML: %v", confirmado)
	}

	rec := e.crudo(http.MethodGet, "/espacios/exportar?formato=kml&bloqueId="+s.bloque, "", "", s.admin, nil)
	cuerpo := rec.Body.String()
	if rec.Code != http.StatusOK || !strings.Contains(rec.Header().Get("Content-Type"), "kml") {
		t.Fatalf("exportar KML: %d %s %s", rec.Code, rec.Header().Get("Content-Type"), cuerpo)
	}
	for _, esperado := range []string{"<kml", "<value>KML-1</value>", "<name>Sala de cómputo</name>", "<coordinates>", "versionGeometria"} {
		if !strings.Contains(cuerpo, esperado) {
			t.Fatalf("el KML exportado no contiene %q", esperado)
		}
	}
	// El archivo exportado vuelve a entrar por la importación (códigos ya existentes advertidos).
	if estado, datos := e.enviarTexto(http.MethodPost, "/espacios/importar/preview?formato=kml", "text/xml", cuerpo, s.admin); estado != http.StatusOK {
		t.Fatalf("reimportar KML exportado: %d %v", estado, datos)
	}
	if estado, _ := e.llamar(http.MethodGet, "/espacios/exportar?formato=shp", nil, s.admin); estado != http.StatusUnprocessableEntity {
		t.Fatalf("formato desconocido: estado %d, esperado 422", estado)
	}
}

// Precondición optimista sobre PUT /espacios/{id}/geometria: If-Match o versionEsperada.
func TestGeo_GeometriaConPrecondicionDeVersion(t *testing.T) {
	e := nuevoEntorno(t)
	s := construirEscenario(e)
	ruta := "/espacios/" + s.espacio2 + "/geometria"
	actual := e.exigir(http.MethodGet, "/espacios/"+s.espacio2, nil, s.admin, http.StatusOK)
	version := int(actual["versionGeometria"].(float64))

	cuerpo := func(lon float64, extra string) string {
		return `{"metodoCaptura":"TOQUE_MAPA","coordenadas":[[` + ftoa(lon) + `,1.1485],[` + ftoa(lon+0.0002) + `,1.1485],[` +
			ftoa(lon+0.0002) + `,1.1483],[` + ftoa(lon) + `,1.1483]]` + extra + `}`
	}
	rec := e.crudo(http.MethodPut, ruta, "application/json", cuerpo(-76.6440, ""), s.admin, map[string]string{"If-Match": `"` + itoa(version) + `"`})
	if rec.Code != http.StatusOK || rec.Header().Get("ETag") != `"`+itoa(version+1)+`"` {
		t.Fatalf("If-Match vigente: %d ETag=%s %s", rec.Code, rec.Header().Get("ETag"), rec.Body.String())
	}
	// Mismo If-Match (ya desactualizado) → 409 CONFLICTO_VERSION.
	rec = e.crudo(http.MethodPut, ruta, "application/json", cuerpo(-76.6430, ""), s.admin, map[string]string{"If-Match": `"` + itoa(version) + `"`})
	if rec.Code != http.StatusConflict || !strings.Contains(rec.Body.String(), "CONFLICTO_VERSION") {
		t.Fatalf("If-Match obsoleto: %d %s", rec.Code, rec.Body.String())
	}
	// Variante en el cuerpo, como la usa la consola web.
	rec = e.crudo(http.MethodPut, ruta, "application/json", cuerpo(-76.6430, `,"versionEsperada":`+itoa(version)), s.admin, nil)
	if rec.Code != http.StatusConflict {
		t.Fatalf("versionEsperada obsoleta: %d %s", rec.Code, rec.Body.String())
	}
	rec = e.crudo(http.MethodPut, ruta, "application/json", cuerpo(-76.6430, `,"versionEsperada":`+itoa(version+1)), s.admin, nil)
	if rec.Code != http.StatusOK {
		t.Fatalf("versionEsperada vigente: %d %s", rec.Code, rec.Body.String())
	}
	// Sin precondición se mantiene la compatibilidad con clientes que aún no la envían.
	if rec = e.crudo(http.MethodPut, ruta, "application/json", cuerpo(-76.6420, ""), s.admin, nil); rec.Code != http.StatusOK {
		t.Fatalf("sin precondición: %d %s", rec.Code, rec.Body.String())
	}
	versiones := e.exigir(http.MethodGet, "/espacios/"+s.espacio2, nil, s.admin, http.StatusOK)["versionGeometria"]
	if versiones != float64(version+3) {
		t.Fatalf("los conflictos no deben crear versiones: %v, esperado %d", versiones, version+3)
	}
}

func ftoa(f float64) string { return strconv.FormatFloat(f, 'f', -1, 64) }

func itoa(i int) string { return strconv.Itoa(i) }
