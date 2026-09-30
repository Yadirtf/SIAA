package exportar

import (
	"bytes"
	"fmt"

	"github.com/xuri/excelize/v2"
)

const hoja = "Reporte"

// XLSX genera el libro con el encabezado institucional y la tabla con filtros automáticos.
func XLSX(t Tabla) ([]byte, error) {
	f := excelize.NewFile()
	defer func() { _ = f.Close() }()
	if err := f.SetSheetName("Sheet1", hoja); err != nil {
		return nil, err
	}
	negrita, err := f.NewStyle(&excelize.Style{Font: &excelize.Font{Bold: true}})
	if err != nil {
		return nil, err
	}
	titulo, err := f.NewStyle(&excelize.Style{Font: &excelize.Font{Bold: true, Size: 14}})
	if err != nil {
		return nil, err
	}

	_ = f.SetCellValue(hoja, "A1", "SIAA — "+t.Titulo)
	_ = f.SetCellStyle(hoja, "A1", "A1", titulo)
	fila := 2
	for _, m := range t.encabezado() {
		_ = f.SetCellValue(hoja, fmt.Sprintf("A%d", fila), m[0])
		_ = f.SetCellValue(hoja, fmt.Sprintf("B%d", fila), m[1])
		_ = f.SetCellStyle(hoja, fmt.Sprintf("A%d", fila), fmt.Sprintf("A%d", fila), negrita)
		fila++
	}
	fila++

	inicio := fila
	for c, col := range t.Columnas {
		celda, _ := excelize.CoordinatesToCellName(c+1, fila)
		_ = f.SetCellValue(hoja, celda, col)
		_ = f.SetCellStyle(hoja, celda, celda, negrita)
	}
	for _, datos := range t.Filas {
		fila++
		for c, v := range datos {
			celda, _ := excelize.CoordinatesToCellName(c+1, fila)
			_ = f.SetCellValue(hoja, celda, v)
		}
	}
	if len(t.Columnas) > 0 {
		ultima, _ := excelize.CoordinatesToCellName(len(t.Columnas), fila)
		primera, _ := excelize.CoordinatesToCellName(1, inicio)
		_ = f.AutoFilter(hoja, primera+":"+ultima, nil)
		fin, _ := excelize.ColumnNumberToName(len(t.Columnas))
		_ = f.SetColWidth(hoja, "A", fin, 18)
	}

	var buf bytes.Buffer
	if err := f.Write(&buf); err != nil {
		return nil, fmt.Errorf("escribir XLSX: %w", err)
	}
	return buf.Bytes(), nil
}
