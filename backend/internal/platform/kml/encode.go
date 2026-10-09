package kml

import (
	"encoding/xml"
	"fmt"
	"io"
	"strconv"
	"strings"
)

// Espacio describe un polígono a exportar: identificación, metadatos y anillo [lon, lat].
type Espacio struct {
	Nombre      string
	Descripcion string
	// Datos se escribe como ExtendedData/Data en el orden de Claves.
	Datos  map[string]string
	Claves []string
	Anillo [][2]float64
}

type docKML struct {
	XMLName   xml.Name `xml:"kml"`
	Namespace string   `xml:"xmlns,attr"`
	Documento struct {
		Nombre     string         `xml:"name"`
		Placemarks []placemarkOut `xml:"Placemark"`
	} `xml:"Document"`
}

type dataOut struct {
	Nombre string `xml:"name,attr"`
	Valor  string `xml:"value"`
}

type placemarkOut struct {
	Nombre       string `xml:"name"`
	Descripcion  string `xml:"description,omitempty"`
	ExtendedData *struct {
		Data []dataOut `xml:"Data"`
	} `xml:"ExtendedData,omitempty"`
	Poligono struct {
		Exterior struct {
			Anillo struct {
				Coordenadas string `xml:"coordinates"`
			} `xml:"LinearRing"`
		} `xml:"outerBoundaryIs"`
	} `xml:"Polygon"`
}

// Encode escribe un documento KML 2.2 con un Placemark por espacio. El anillo se cierra si
// no lo está, como exige el estándar para LinearRing.
func Encode(w io.Writer, nombreDocumento string, espacios []Espacio) error {
	doc := docKML{Namespace: "http://www.opengis.net/kml/2.2"}
	doc.Documento.Nombre = nombreDocumento
	doc.Documento.Placemarks = make([]placemarkOut, 0, len(espacios))
	for _, e := range espacios {
		var p placemarkOut
		p.Nombre = e.Nombre
		p.Descripcion = e.Descripcion
		if len(e.Claves) > 0 {
			p.ExtendedData = &struct {
				Data []dataOut `xml:"Data"`
			}{}
			for _, k := range e.Claves {
				p.ExtendedData.Data = append(p.ExtendedData.Data, dataOut{Nombre: k, Valor: e.Datos[k]})
			}
		}
		p.Poligono.Exterior.Anillo.Coordenadas = FormatearCoordenadas(e.Anillo)
		doc.Documento.Placemarks = append(doc.Documento.Placemarks, p)
	}
	if _, err := io.WriteString(w, xml.Header); err != nil {
		return err
	}
	enc := xml.NewEncoder(w)
	enc.Indent("", "  ")
	if err := enc.Encode(doc); err != nil {
		return fmt.Errorf("codificar KML: %w", err)
	}
	return enc.Flush()
}

// FormatearCoordenadas serializa un anillo como "lon,lat lon,lat ..." cerrándolo si hace falta.
func FormatearCoordenadas(anillo [][2]float64) string {
	if len(anillo) == 0 {
		return ""
	}
	puntos := anillo
	if anillo[0] != anillo[len(anillo)-1] {
		puntos = append(append([][2]float64{}, anillo...), anillo[0])
	}
	partes := make([]string, 0, len(puntos))
	for _, c := range puntos {
		partes = append(partes, strconv.FormatFloat(c[0], 'f', -1, 64)+","+strconv.FormatFloat(c[1], 'f', -1, 64))
	}
	return strings.Join(partes, " ")
}
