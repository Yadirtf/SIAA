package importar

import (
	"bytes"
	"encoding/csv"
	"fmt"

	"github.com/xuri/excelize/v2"
)

// ColumnaDiagnostico es el encabezado de la columna que se agrega al archivo (US-ACA-07 AC-02).
const ColumnaDiagnostico = "diagnostico"

// Anotar devuelve el mismo archivo, en su formato original, con una columna adicional de
// diagnóstico por fila. diagnosticos va indexado por número de fila del archivo.
func Anotar(t *Tabla, diagnosticos map[int]string) ([]byte, string, error) {
	return escribir(t, diagnosticos)
}

// escribir serializa la tabla en su formato; con diagnosticos != nil agrega la columna.
func escribir(t *Tabla, diagnosticos map[int]string) ([]byte, string, error) {
	registros := make([][]string, 0, len(t.Filas)+1)
	encabezado := append([]string{}, t.Encabezados...)
	if diagnosticos != nil {
		encabezado = append(encabezado, ColumnaDiagnostico)
	}
	registros = append(registros, encabezado)
	ancho := len(t.Encabezados)
	for _, f := range t.Filas {
		celdas := make([]string, ancho, ancho+1)
		copy(celdas, f.Celdas)
		if diagnosticos != nil {
			diag := diagnosticos[f.Numero]
			if diag == "" {
				diag = "OK"
			}
			celdas = append(celdas, diag)
		}
		registros = append(registros, celdas)
	}
	if t.Formato == FormatoXLSX {
		b, err := escribirXLSX(registros)
		return b, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", err
	}
	var buf bytes.Buffer
	buf.WriteString("\xef\xbb\xbf") // BOM para que Excel abra las tildes correctamente
	w := csv.NewWriter(&buf)
	if t.Separador != 0 {
		w.Comma = t.Separador
	}
	if err := w.WriteAll(registros); err != nil {
		return nil, "", fmt.Errorf("escribir CSV: %w", err)
	}
	return buf.Bytes(), "text/csv; charset=utf-8", nil
}

func escribirXLSX(registros [][]string) ([]byte, error) {
	f := excelize.NewFile()
	defer func() { _ = f.Close() }()
	const hoja = "Sheet1"
	for i, reg := range registros {
		for j, v := range reg {
			celda, _ := excelize.CoordinatesToCellName(j+1, i+1)
			_ = f.SetCellValue(hoja, celda, v)
		}
	}
	var buf bytes.Buffer
	if err := f.Write(&buf); err != nil {
		return nil, fmt.Errorf("escribir XLSX: %w", err)
	}
	return buf.Bytes(), nil
}
