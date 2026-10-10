// Package kml lee y escribe documentos KML 2.2 (OGC) con la biblioteca estándar encoding/xml.
// Solo modela lo que SIAA necesita para la cartografía (US-GEO-11): Placemark con nombre,
// descripción, ExtendedData y un Polygon cuyo anillo exterior trae "lon,lat[,alt]".
package kml

import (
	"bytes"
	"encoding/xml"
	"errors"
	"fmt"
	"io"
	"strconv"
	"strings"
)

// Placemark es un elemento del documento KML ya normalizado a tipos de Go.
type Placemark struct {
	Nombre      string
	Descripcion string
	// Datos agrupa ExtendedData/Data y SchemaData/SimpleData por nombre.
	Datos map[string]string
	// TipoGeometria es el primer tipo encontrado: Polygon, Point, LineString o vacío.
	TipoGeometria string
	// Anillo es el anillo exterior del polígono en orden [lon, lat], tal como viene en el archivo.
	Anillo [][2]float64
	// ErrorCoordenadas describe una tupla ilegible; el elemento debe reportarse inválido.
	ErrorCoordenadas string
}

type xmlCoordenadas struct {
	Texto string `xml:"coordinates"`
}

type xmlPoligono struct {
	Exterior struct {
		Anillo xmlCoordenadas `xml:"LinearRing"`
	} `xml:"outerBoundaryIs"`
}

type xmlPlacemark struct {
	Nombre       string `xml:"name"`
	Descripcion  string `xml:"description"`
	ExtendedData struct {
		Data []struct {
			Nombre string `xml:"name,attr"`
			Valor  string `xml:"value"`
		} `xml:"Data"`
		SchemaData []struct {
			SimpleData []struct {
				Nombre string `xml:"name,attr"`
				Valor  string `xml:",chardata"`
			} `xml:"SimpleData"`
		} `xml:"SchemaData"`
	} `xml:"ExtendedData"`
	Poligono      *xmlPoligono `xml:"Polygon"`
	MultiGeometry *struct {
		Poligonos []xmlPoligono `xml:"Polygon"`
	} `xml:"MultiGeometry"`
	Punto *xmlCoordenadas `xml:"Point"`
	Linea *xmlCoordenadas `xml:"LineString"`
}

// ErrNoEsKML indica que el contenido no es XML o no contiene un elemento raíz kml.
var ErrNoEsKML = errors.New("el contenido no es un documento KML")

// Parse recorre el documento y devuelve cada Placemark en orden de aparición, sin importar
// cuántos Document/Folder lo anidan. Un error solo se devuelve si el XML está mal formado.
func Parse(data []byte) ([]Placemark, error) {
	dec := xml.NewDecoder(bytes.NewReader(data))
	dec.Strict = true
	dec.Entity = xml.HTMLEntity
	raizKML := false
	var res []Placemark
	for {
		tok, err := dec.Token()
		if errors.Is(err, io.EOF) {
			break
		}
		if err != nil {
			return nil, fmt.Errorf("%w: %v", ErrNoEsKML, err)
		}
		inicio, ok := tok.(xml.StartElement)
		if !ok {
			continue
		}
		if strings.EqualFold(inicio.Name.Local, "kml") {
			raizKML = true
			continue
		}
		if inicio.Name.Local != "Placemark" {
			continue
		}
		var x xmlPlacemark
		if err := dec.DecodeElement(&x, &inicio); err != nil {
			return nil, fmt.Errorf("%w: %v", ErrNoEsKML, err)
		}
		res = append(res, normalizar(x))
	}
	if !raizKML {
		return nil, ErrNoEsKML
	}
	return res, nil
}

func normalizar(x xmlPlacemark) Placemark {
	p := Placemark{
		Nombre:      strings.TrimSpace(x.Nombre),
		Descripcion: strings.TrimSpace(x.Descripcion),
		Datos:       map[string]string{},
	}
	for _, d := range x.ExtendedData.Data {
		p.Datos[strings.TrimSpace(d.Nombre)] = strings.TrimSpace(d.Valor)
	}
	for _, sd := range x.ExtendedData.SchemaData {
		for _, d := range sd.SimpleData {
			p.Datos[strings.TrimSpace(d.Nombre)] = strings.TrimSpace(d.Valor)
		}
	}

	var poligono *xmlPoligono
	switch {
	case x.Poligono != nil:
		poligono = x.Poligono
	case x.MultiGeometry != nil && len(x.MultiGeometry.Poligonos) > 0:
		poligono = &x.MultiGeometry.Poligonos[0]
	case x.Punto != nil:
		p.TipoGeometria = "Point"
		return p
	case x.Linea != nil:
		p.TipoGeometria = "LineString"
		return p
	default:
		return p
	}
	p.TipoGeometria = "Polygon"
	anillo, err := ParseCoordenadas(poligono.Exterior.Anillo.Texto)
	if err != nil {
		p.ErrorCoordenadas = err.Error()
	}
	p.Anillo = anillo
	return p
}

// ParseCoordenadas interpreta el contenido de <coordinates>: tuplas "lon,lat[,alt]" separadas
// por espacios en blanco. La altitud se descarta (la cartografía es planimétrica).
func ParseCoordenadas(texto string) ([][2]float64, error) {
	campos := strings.Fields(texto)
	res := make([][2]float64, 0, len(campos))
	for _, tupla := range campos {
		partes := strings.Split(tupla, ",")
		if len(partes) < 2 || len(partes) > 3 {
			return res, fmt.Errorf("tupla de coordenadas inválida %q: se espera lon,lat[,alt]", tupla)
		}
		lon, errLon := strconv.ParseFloat(partes[0], 64)
		lat, errLat := strconv.ParseFloat(partes[1], 64)
		if errLon != nil || errLat != nil {
			return res, fmt.Errorf("tupla de coordenadas no numérica %q", tupla)
		}
		res = append(res, [2]float64{lon, lat})
	}
	return res, nil
}

// PareceKML indica si el contenido empieza como un documento XML (tras BOM y espacios).
// Sirve para elegir el lector cuando el cliente no declara el formato.
func PareceKML(data []byte) bool {
	d := bytes.TrimPrefix(data, []byte("\xef\xbb\xbf"))
	d = bytes.TrimSpace(d)
	return len(d) > 0 && d[0] == '<'
}
