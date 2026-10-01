package exportar

import (
	"github.com/siaa/backend/internal/domain/shared"

	"bytes"
	"fmt"

	"github.com/go-pdf/fpdf"
)

// PDF genera el documento horizontal con marca de agua institucional en cada página,
// sello de fecha de generación y huella de los datos (RF-REP-004).
func PDF(t Tabla) ([]byte, error) {
	pdf := fpdf.New("L", "mm", "A4", "")
	tr := pdf.UnicodeTranslatorFromDescriptor("cp1252")
	pdf.SetMargins(10, 12, 10)
	pdf.SetAutoPageBreak(true, 14)

	pdf.SetHeaderFunc(func() { marcaDeAgua(pdf) })
	pdf.SetFooterFunc(func() {
		pdf.SetY(-10)
		pdf.SetFont("Helvetica", "I", 7)
		pdf.SetTextColor(110, 110, 110)
		pie := fmt.Sprintf("SIAA · %s · Generado %s · Página %d/{nb}", t.Titulo,
			shared.FechaHoraLocal(t.GeneradoEn), pdf.PageNo())
		pdf.CellFormat(0, 5, tr(pie), "", 0, "C", false, 0, "")
	})
	pdf.AliasNbPages("")
	pdf.AddPage()

	pdf.SetTextColor(0, 0, 0)
	pdf.SetFont("Helvetica", "B", 14)
	pdf.CellFormat(0, 8, tr("SIAA — "+t.Titulo), "", 1, "L", false, 0, "")
	pdf.SetFont("Helvetica", "", 8)
	for _, m := range t.encabezado() {
		pdf.CellFormat(35, 4.5, tr(m[0]+":"), "", 0, "L", false, 0, "")
		pdf.CellFormat(0, 4.5, tr(m[1]), "", 1, "L", false, 0, "")
	}
	pdf.Ln(3)

	anchos := anchosColumnas(pdf, t)
	pdf.SetFont("Helvetica", "B", 7.5)
	pdf.SetFillColor(230, 236, 245)
	for i, col := range t.Columnas {
		pdf.CellFormat(anchos[i], 6, tr(col), "1", 0, "C", true, 0, "")
	}
	pdf.Ln(-1)
	pdf.SetFont("Helvetica", "", 7.5)
	for _, fila := range t.Filas {
		for i := range t.Columnas {
			v := ""
			if i < len(fila) {
				v = recortar(pdf, tr(fila[i]), anchos[i]-1.5)
			}
			pdf.CellFormat(anchos[i], 5.5, v, "1", 0, "L", false, 0, "")
		}
		pdf.Ln(-1)
	}

	var buf bytes.Buffer
	if err := pdf.Output(&buf); err != nil {
		return nil, fmt.Errorf("escribir PDF: %w", err)
	}
	return buf.Bytes(), nil
}

// marcaDeAgua dibuja el texto institucional diagonal y tenue detrás del contenido.
func marcaDeAgua(pdf *fpdf.Fpdf) {
	pdf.SetFont("Helvetica", "B", 60)
	pdf.SetTextColor(235, 235, 235)
	w, h := pdf.GetPageSize()
	pdf.TransformBegin()
	pdf.TransformRotate(30, w/2, h/2)
	pdf.Text(w/2-75, h/2, "SIAA INSTITUCIONAL")
	pdf.TransformEnd()
	pdf.SetTextColor(0, 0, 0)
	pdf.SetXY(10, 12)
}

func anchosColumnas(pdf *fpdf.Fpdf, t Tabla) []float64 {
	w, _ := pdf.GetPageSize()
	disponible := w - 20
	anchos := make([]float64, len(t.Columnas))
	total := 0.0
	for i := range t.Columnas {
		peso := 1.0
		if i < len(t.Anchos) && t.Anchos[i] > 0 {
			peso = t.Anchos[i]
		}
		anchos[i] = peso
		total += peso
	}
	for i := range anchos {
		anchos[i] = anchos[i] / total * disponible
	}
	return anchos
}

// recortar acorta el texto para que quepa en la celda.
func recortar(pdf *fpdf.Fpdf, s string, ancho float64) string {
	if pdf.GetStringWidth(s) <= ancho {
		return s
	}
	r := []rune(s)
	for len(r) > 0 && pdf.GetStringWidth(string(r)+"...") > ancho {
		r = r[:len(r)-1]
	}
	return string(r) + "..."
}
