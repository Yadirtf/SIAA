// Package importar lee tablas de carga masiva desde CSV o XLSX y las devuelve anotadas
// (US-ACA-07 T-ACA-07.2 y T-ACA-07.4). No conoce el dominio: solo celdas y encabezados.
package importar

import (
	"bytes"
	"encoding/csv"
	"errors"
	"fmt"
	"strings"
	"unicode"
	"unicode/utf8"

	"github.com/xuri/excelize/v2"
	"golang.org/x/text/unicode/norm"
)

// Formatos admitidos.
const (
	FormatoCSV  = "CSV"
	FormatoXLSX = "XLSX"
)

// TamanoMaximo limita el archivo (un documento MongoDB admite 16 MB y se guarda el original).
const TamanoMaximo = 8 << 20

// Tabla es el contenido leído: encabezados originales y filas con su número en el archivo.
type Tabla struct {
	Formato     string
	Separador   rune
	Encabezados []string
	Filas       []Fila
}

// Fila es una fila de datos; Numero es la fila en el archivo (el encabezado es la 1).
type Fila struct {
	Numero int
	Celdas []string
}

// ErrArchivoVacio indica un archivo sin encabezado.
var ErrArchivoVacio = errors.New("el archivo está vacío o no tiene encabezado")

// Leer detecta el formato (XLSX por su firma ZIP) y devuelve la tabla sin filas vacías.
func Leer(contenido []byte) (*Tabla, error) {
	if len(contenido) > TamanoMaximo {
		return nil, fmt.Errorf("el archivo supera %d MB", TamanoMaximo>>20)
	}
	if bytes.HasPrefix(contenido, []byte("PK\x03\x04")) {
		return leerXLSX(contenido)
	}
	return leerCSV(contenido)
}

func leerCSV(contenido []byte) (*Tabla, error) {
	texto := aUTF8(bytes.TrimPrefix(contenido, []byte("\xef\xbb\xbf")))
	sep := detectarSeparador(texto)
	r := csv.NewReader(strings.NewReader(texto))
	r.Comma = sep
	r.FieldsPerRecord = -1
	r.TrimLeadingSpace = true
	r.LazyQuotes = true
	registros, err := r.ReadAll()
	if err != nil {
		return nil, fmt.Errorf("CSV mal formado: %w", err)
	}
	t := armar(registros)
	if t == nil {
		return nil, ErrArchivoVacio
	}
	t.Formato, t.Separador = FormatoCSV, sep
	return t, nil
}

func leerXLSX(contenido []byte) (*Tabla, error) {
	f, err := excelize.OpenReader(bytes.NewReader(contenido))
	if err != nil {
		return nil, fmt.Errorf("XLSX ilegible: %w", err)
	}
	defer func() { _ = f.Close() }()
	hojas := f.GetSheetList()
	if len(hojas) == 0 {
		return nil, ErrArchivoVacio
	}
	registros, err := f.GetRows(hojas[0])
	if err != nil {
		return nil, fmt.Errorf("XLSX ilegible: %w", err)
	}
	t := armar(registros)
	if t == nil {
		return nil, ErrArchivoVacio
	}
	t.Formato = FormatoXLSX
	return t, nil
}

// armar toma la primera fila no vacía como encabezado y descarta filas vacías.
func armar(registros [][]string) *Tabla {
	t := &Tabla{}
	for i, reg := range registros {
		if vacia(reg) {
			continue
		}
		if t.Encabezados == nil {
			t.Encabezados = recortar(reg)
			continue
		}
		t.Filas = append(t.Filas, Fila{Numero: i + 1, Celdas: recortar(reg)})
	}
	if t.Encabezados == nil {
		return nil
	}
	return t
}

func recortar(reg []string) []string {
	out := make([]string, len(reg))
	for i, c := range reg {
		out[i] = strings.TrimSpace(c)
	}
	return out
}

func vacia(reg []string) bool {
	for _, c := range reg {
		if strings.TrimSpace(c) != "" {
			return false
		}
	}
	return true
}

// detectarSeparador elige entre coma, punto y coma y tabulador según la primera línea.
func detectarSeparador(texto string) rune {
	linea, _, _ := strings.Cut(texto, "\n")
	mejor, max := ',', 0
	for _, c := range []rune{',', ';', '\t'} {
		if n := strings.Count(linea, string(c)); n > max {
			mejor, max = c, n
		}
	}
	return mejor
}

// aUTF8 convierte archivos guardados en Latin-1/Windows-1252 (Excel en español).
func aUTF8(b []byte) string {
	if utf8.Valid(b) {
		return string(b)
	}
	runas := make([]rune, len(b))
	for i, c := range b {
		runas[i] = rune(c)
	}
	return string(runas)
}

// Normalizar deja un encabezado comparable: minúsculas, sin tildes ni separadores.
func Normalizar(s string) string {
	var b strings.Builder
	for _, r := range norm.NFD.String(strings.ToLower(s)) {
		if unicode.Is(unicode.Mn, r) || r == ' ' || r == '_' || r == '-' || r == '.' {
			continue
		}
		b.WriteRune(r)
	}
	return b.String()
}
