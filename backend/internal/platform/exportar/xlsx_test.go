package exportar

import (
	"bytes"
	"testing"
	"time"

	"github.com/xuri/excelize/v2"
)

// US-REP-02 AC-01: los números se escriben como número y las fechas como fecha.
func TestXLSX_CeldasTipadas(t *testing.T) {
	tabla := Tabla{
		Titulo:     "Prueba",
		Metadatos:  [][2]string{{"Desde", "2026-10-01"}},
		Columnas:   []string{"Nombre", "Sesiones", "Horas", "%", "Fecha", "Documento"},
		Tipos:      []TipoColumna{Texto, Entero, Decimal, Porcentaje, Fecha, Texto},
		Filas:      [][]string{{"Ana", "12", "7.50", "85.5%", "2026-10-02", "00123"}, {"TOTAL", "", "", "", "", ""}},
		GeneradoEn: time.Date(2026, 10, 9, 15, 0, 0, 0, time.UTC),
	}
	contenido, err := XLSX(tabla)
	if err != nil {
		t.Fatal(err)
	}
	f, err := excelize.OpenReader(bytes.NewReader(contenido))
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = f.Close() }()
	filas, _ := f.GetRows(hoja)
	fila := 0
	for i, r := range filas {
		if len(r) > 0 && r[0] == "Ana" {
			fila = i + 1
		}
	}
	if fila == 0 {
		t.Fatalf("no se encontró la fila de datos: %v", filas)
	}
	tipos := map[string]excelize.CellType{}
	for c, col := range tabla.Columnas {
		celda, _ := excelize.CoordinatesToCellName(c+1, fila)
		tipo, err := f.GetCellType(hoja, celda)
		if err != nil {
			t.Fatal(err)
		}
		tipos[col] = tipo
	}
	for _, col := range []string{"Sesiones", "Horas", "%", "Fecha"} {
		if tipos[col] != excelize.CellTypeUnset && tipos[col] != excelize.CellTypeNumber {
			t.Fatalf("la columna %s debe ser numérica, es %v", col, tipos[col])
		}
	}
	if tipos["Documento"] != excelize.CellTypeSharedString && tipos["Documento"] != excelize.CellTypeInlineString {
		t.Fatalf("el documento debe conservarse como texto, es %v", tipos["Documento"])
	}
	sesiones, _ := excelize.CoordinatesToCellName(2, fila)
	if v, _ := f.GetCellValue(hoja, sesiones, excelize.Options{RawCellValue: true}); v != "12" {
		t.Fatalf("sesiones: %q", v)
	}
	pct, _ := excelize.CoordinatesToCellName(4, fila)
	if v, _ := f.GetCellValue(hoja, pct, excelize.Options{RawCellValue: true}); v != "0.855" {
		t.Fatalf("el porcentaje se guarda como fracción: %q", v)
	}
	fecha, _ := excelize.CoordinatesToCellName(5, fila)
	if v, _ := f.GetCellValue(hoja, fecha); v != "2026-10-02" {
		t.Fatalf("la fecha se muestra con formato de fecha: %q", v)
	}
	if v, _ := f.GetCellValue(hoja, fecha, excelize.Options{RawCellValue: true}); v == "2026-10-02" {
		t.Fatalf("la fecha debe guardarse como número de serie, no como texto")
	}
}
