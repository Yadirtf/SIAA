// Package unit_test — US-GEO-11 (KML) y precondición optimista de geometría (US-GEO-06/07).
package unit_test

import (
	"bytes"
	"context"
	"errors"
	"strings"
	"testing"

	"github.com/siaa/backend/internal/domain/geo"
	"github.com/siaa/backend/internal/domain/shared"
	usecaseGeo "github.com/siaa/backend/internal/usecase/geo"
)

const kmlCartografia = `<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2"><Document><Folder>
 <Placemark><name>Laboratorio de redes</name>
  <ExtendedData><Data name="codigo"><value>LAB-9</value></Data>
   <Data name="tipo"><value>laboratorio</value></Data><Data name="capacidad"><value>25</value></Data></ExtendedData>
  <Polygon><outerBoundaryIs><LinearRing><coordinates>
   -74.0650,4.6500,0 -74.0648,4.6500,0 -74.0648,4.6502,0 -74.0650,4.6502,0 -74.0650,4.6500,0
  </coordinates></LinearRing></outerBoundaryIs></Polygon></Placemark>
 <Placemark><name>A-202</name><description>Aula 202</description>
  <Polygon><outerBoundaryIs><LinearRing><coordinates>
   4.6500,-74.0640 4.6500,-74.0638 4.6502,-74.0638 4.6502,-74.0640 4.6500,-74.0640
  </coordinates></LinearRing></outerBoundaryIs></Polygon></Placemark>
 <Placemark><name>Cruzado</name><Polygon><outerBoundaryIs><LinearRing><coordinates>
   -74.0630,4.6500 -74.0628,4.6502 -74.0628,4.6500 -74.0630,4.6502 -74.0630,4.6500
  </coordinates></LinearRing></outerBoundaryIs></Polygon></Placemark>
 <Placemark><name>Poste</name><Point><coordinates>-74.06,4.65</coordinates></Point></Placemark>
</Folder></Document></kml>`

func TestUS_GEO_11_KML_PreviewValidaComoGeoJSON(t *testing.T) {
	svc, _, _, _, _, _ := setupGeoService()
	prev, err := svc.PreviewImportar(context.Background(), []byte(kmlCartografia), "")
	if err != nil {
		t.Fatalf("preview KML: %v", err)
	}
	if prev.Formato != usecaseGeo.FormatoKML || prev.TotalElementos != 4 || prev.Validos != 2 || prev.Invalidos != 2 {
		t.Fatalf("resumen inesperado: %+v", prev)
	}
	lab := prev.Elementos[0]
	if lab.Codigo != "LAB-9" || lab.Nombre != "Laboratorio de redes" || lab.Tipo != "LABORATORIO" || lab.Capacidad != 25 {
		t.Fatalf("metadatos de ExtendedData mal leídos: %+v", lab)
	}
	aula := prev.Elementos[1]
	if aula.Codigo != "A-202" || aula.Nombre != "Aula 202" {
		t.Fatalf("código/nombre desde name/description mal leídos: %+v", aula)
	}
	if !aula.CoordenadasInvert || !aula.Valido || aula.Vertices[0][0] > 0 {
		t.Fatalf("AC-04: debió detectar y normalizar [lat, lon]: %+v", aula)
	}
	if prev.Elementos[2].Valido || !strings.Contains(strings.Join(prev.Elementos[2].Errores, " "), geo.MotivoPoligonoNoSimple) {
		t.Fatalf("US-GEO-04: la autointersección debe invalidar el elemento: %+v", prev.Elementos[2])
	}
	if prev.Elementos[3].Valido {
		t.Fatal("un Point no es un espacio importable")
	}
}

func TestUS_GEO_11_KML_ArchivoInvalidoYFormatoDesconocido(t *testing.T) {
	svc, _, _, _, _, _ := setupGeoService()
	ctx := context.Background()
	for _, caso := range []struct{ datos, formato, codigo string }{
		{"<kml><Placemark>", "kml", "FORMATO_KML_INVALIDO"},
		{"{}", "shp", "FORMATO_NO_SOPORTADO"},
	} {
		_, err := svc.PreviewImportar(ctx, []byte(caso.datos), caso.formato)
		var de *shared.DomainError
		if !errors.As(err, &de) || de.Code != shared.ErrValidacion || de.Fields[0].Error != caso.codigo {
			t.Fatalf("%s: esperaba %s, obtuvo %v", caso.formato, caso.codigo, err)
		}
	}
}

func TestUS_GEO_11_ConfirmarRevalidaEnServidorYExportaKML(t *testing.T) {
	svc, _, _, repo, _, _ := setupGeoService()
	ctx := context.Background()
	prev, err := svc.PreviewImportar(ctx, []byte(kmlCartografia), "kml")
	if err != nil {
		t.Fatalf("preview: %v", err)
	}
	// Un cliente manipulado marca como válido el polígono cruzado: el backend lo vuelve a validar.
	elementos := prev.Elementos
	elementos[2].Valido = true
	res, err := svc.ConfirmarImportarGeoJSON(ctx, usecaseGeo.ConfirmarImportarGeoJSONCmd{SedeID: "sede-kml", Elementos: elementos})
	if err != nil {
		t.Fatalf("confirmar: %v", err)
	}
	if res.TotalImportados != 2 || len(res.Omitidos) != 2 {
		t.Fatalf("esperaba 2 importados y 2 omitidos: %+v", res)
	}
	if len(repo.espacios) != 2 {
		t.Fatalf("se persistieron %d espacios", len(repo.espacios))
	}

	var buf bytes.Buffer
	if err := svc.ExportarEspaciosKML(ctx, &buf, "sede-kml", ""); err != nil {
		t.Fatalf("exportar KML: %v", err)
	}
	salida := buf.String()
	for _, esperado := range []string{"<kml", "<Placemark>", `<Data name="codigo">`, "<value>LAB-9</value>", "<coordinates>", "versionGeometria"} {
		if !strings.Contains(salida, esperado) {
			t.Fatalf("el KML exportado no contiene %q:\n%s", esperado, salida)
		}
	}
	// Ida y vuelta: el KML exportado se puede volver a importar con los mismos códigos.
	re, err := svc.PreviewImportar(ctx, buf.Bytes(), "")
	if err != nil || re.Validos != 2 {
		t.Fatalf("reimportar el KML exportado: %+v %v", re, err)
	}
}

// repoCASPerdedor simula que otro guardado concurrente ganó el compare-and-set.
type repoCASPerdedor struct{ *mockEspacioRepo }

func (r repoCASPerdedor) UpdateSiVersion(context.Context, *geo.Espacio, int) (bool, error) {
	return false, nil
}

func cuadradoGeo(t *testing.T, lon float64) []geo.GeoPoint {
	return []geo.GeoPoint{
		makePoint(t, lon, 4.6500), makePoint(t, lon+0.0002, 4.6500),
		makePoint(t, lon+0.0002, 4.6502), makePoint(t, lon, 4.6502),
	}
}

func TestGeometria_PrecondicionOptimista(t *testing.T) {
	svc, _, repo, espacioID := setupGeoVersionadoTest()
	ctx := context.Background()
	guardar := func(s *usecaseGeo.Service, lon float64, esperada *int) (*geo.Espacio, error) {
		return s.GuardarGeometriaEspacio(ctx, usecaseGeo.GuardarGeometriaCmd{
			EspacioID: espacioID, Vertices: cuadradoGeo(t, lon), MetodoCaptura: geo.MetodoToqueMapa, VersionEsperada: esperada,
		})
	}
	v0 := 0
	esp, err := guardar(svc, -74.0650, &v0)
	if err != nil || esp.VersionGeometria != 1 {
		t.Fatalf("primer guardado con versión correcta: %v %v", esp, err)
	}
	// Sin precondición se mantiene el comportamiento previo (clientes móviles actuales).
	if esp, err = guardar(svc, -74.0660, nil); err != nil || esp.VersionGeometria != 2 {
		t.Fatalf("guardado sin precondición: %v %v", esp, err)
	}
	// Precondición vieja → 409 CONFLICTO_VERSION y la geometría no cambia.
	v1 := 1
	_, err = guardar(svc, -74.0670, &v1)
	var de *shared.DomainError
	if !errors.As(err, &de) || de.Code != shared.ErrConflictoVersion || de.Contexto["versionVigente"] != "2" {
		t.Fatalf("esperaba CONFLICTO_VERSION con versión vigente 2, obtuvo %v", err)
	}
	if repo.espacios[espacioID].VersionGeometria != 2 {
		t.Fatal("un conflicto no debe alterar la geometría")
	}

	// Carrera: la precondición coincide al leer pero otro guardado gana el compare-and-set.
	svcCAS := usecaseGeo.NewService(newMockSedeRepo(), newMockBloqueRepo(), repoCASPerdedor{repo}, nil, nil, nil, shared.NewFakeClock(esp.ActualizadoEn), nil)
	v2 := 2
	if _, err = guardar(svcCAS, -74.0680, &v2); !errors.As(err, &de) || de.Code != shared.ErrConflictoVersion {
		t.Fatalf("esperaba CONFLICTO_VERSION por compare-and-set perdido, obtuvo %v", err)
	}
}
