package kml

import (
	"bytes"
	"errors"
	"strings"
	"testing"
)

const documentoAnidado = `<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document><Folder>
    <Placemark>
      <name>Aula 101</name>
      <description><![CDATA[Primer piso &amp; ventanas]]></description>
      <ExtendedData>
        <Data name="codigo"><value>A-101</value></Data>
        <SchemaData schemaUrl="#s"><SimpleData name="capacidad">30</SimpleData></SchemaData>
      </ExtendedData>
      <Polygon><outerBoundaryIs><LinearRing><coordinates>
        -76.6512,1.1478,0 -76.6510,1.1478,0
        -76.6510,1.1476 -76.6512,1.1476 -76.6512,1.1478
      </coordinates></LinearRing></outerBoundaryIs></Polygon>
    </Placemark>
    <Placemark><name>Punto</name><Point><coordinates>-76.6,1.1</coordinates></Point></Placemark>
    <Placemark><name>Roto</name><Polygon><outerBoundaryIs><LinearRing>
      <coordinates>-76.6,abc</coordinates></LinearRing></outerBoundaryIs></Polygon></Placemark>
  </Folder></Document>
</kml>`

func TestParse_PlacemarksAnidadosConDatos(t *testing.T) {
	ps, err := Parse([]byte(documentoAnidado))
	if err != nil {
		t.Fatalf("Parse: %v", err)
	}
	if len(ps) != 3 {
		t.Fatalf("esperaba 3 placemarks, obtuvo %d", len(ps))
	}
	p := ps[0]
	if p.Nombre != "Aula 101" || p.Datos["codigo"] != "A-101" || p.Datos["capacidad"] != "30" {
		t.Fatalf("datos mal leídos: %+v", p)
	}
	if p.TipoGeometria != "Polygon" || len(p.Anillo) != 5 || p.Anillo[0] != [2]float64{-76.6512, 1.1478} {
		t.Fatalf("anillo mal leído: %+v", p.Anillo)
	}
	if ps[1].TipoGeometria != "Point" {
		t.Fatalf("esperaba Point, obtuvo %q", ps[1].TipoGeometria)
	}
	if ps[2].ErrorCoordenadas == "" {
		t.Fatal("una tupla no numérica debe reportarse")
	}
}

func TestParse_RechazaNoKML(t *testing.T) {
	for _, in := range []string{`{"type":"FeatureCollection"}`, `<html><body/></html>`, `<kml><Placemark>`} {
		if _, err := Parse([]byte(in)); !errors.Is(err, ErrNoEsKML) {
			t.Fatalf("%q: esperaba ErrNoEsKML, obtuvo %v", in, err)
		}
	}
}

func TestEncode_IdaYVuelta(t *testing.T) {
	var buf bytes.Buffer
	err := Encode(&buf, "Sede", []Espacio{{
		Nombre: "Aula <1>", Descripcion: "x",
		Datos: map[string]string{"codigo": "A-1"}, Claves: []string{"codigo"},
		Anillo: [][2]float64{{-76.1, 1.1}, {-76.0, 1.1}, {-76.0, 1.0}},
	}})
	if err != nil {
		t.Fatalf("Encode: %v", err)
	}
	if !strings.Contains(buf.String(), "-76.1,1.1 -76,1.1 -76,1 -76.1,1.1") {
		t.Fatalf("el anillo debe cerrarse en el KML: %s", buf.String())
	}
	ps, err := Parse(buf.Bytes())
	if err != nil || len(ps) != 1 {
		t.Fatalf("releer KML: %v %v", ps, err)
	}
	if ps[0].Nombre != "Aula <1>" || ps[0].Datos["codigo"] != "A-1" || len(ps[0].Anillo) != 4 {
		t.Fatalf("ida y vuelta incorrecta: %+v", ps[0])
	}
}

func TestPareceKML(t *testing.T) {
	if !PareceKML([]byte("\xef\xbb\xbf  <?xml version=\"1.0\"?><kml/>")) || PareceKML([]byte(` {"a":1}`)) {
		t.Fatal("detección de KML incorrecta")
	}
}
