package integration

import (
	"bytes"
	"math"
	"net/http"
	"testing"
	"time"

	"github.com/xuri/excelize/v2"

	"github.com/siaa/backend/internal/domain/marcaje"
)

// sesionesTerminadas devuelve los ids de las sesiones del periodo anteriores a hoy.
func sesionesTerminadas(e *entorno, s *escenario) []string {
	e.t.Helper()
	hoy := time.Now().In(bogota).Format("2006-01-02")
	var ids []string
	for _, se := range e.exigirLista("/sesiones?periodoId="+s.periodo, s.admin) {
		if texto(se["fecha"]) < hoy {
			ids = append(ids, texto(se["id"]))
		}
	}
	if len(ids) == 0 {
		e.t.Fatal("el escenario debe tener sesiones terminadas")
	}
	return ids
}

// US-REP-04 AC-01..AC-03: horas programadas, horas con asistencia confirmada y utilización
// por aula, bloque o sede, con exportación tipada y auditada.
func TestReportes_OcupacionDeEspacios(t *testing.T) {
	e := nuevoEntorno(t)
	s := construirEscenario(e)
	terminadas := sesionesTerminadas(e, s)
	entradaConsolidada(e, terminadas[0], s.docenteID, marcaje.RolDocente)
	n := float64(len(terminadas))
	esperado := math.Round(1/n*1000) / 10

	e.exigir(http.MethodGet, "/reportes/ocupacion?periodoId="+s.periodo, nil, s.docente, http.StatusForbidden)
	e.exigir(http.MethodGet, "/reportes/ocupacion", nil, s.admin, http.StatusUnprocessableEntity)
	e.exigir(http.MethodGet, "/reportes/ocupacion?periodoId="+s.periodo+"&agrupacion=piso", nil, s.admin, http.StatusUnprocessableEntity)

	nombres := map[string]string{"aula": "A-301 · Aula 301", "bloque": "B1 · Bloque 1", "sede": "Sede Central"}
	for agrupacion, nombre := range nombres {
		rep := e.exigir(http.MethodGet, "/reportes/ocupacion?periodoId="+s.periodo+"&agrupacion="+agrupacion, nil, s.admin, http.StatusOK)
		filas := elementos(rep["filas"])
		if len(filas) != 1 || filas[0]["nombre"] != nombre {
			t.Fatalf("%s: filas inesperadas: %v", agrupacion, filas)
		}
		f := filas[0]
		if f["sesiones"] != n || f["sesionesConfirmadas"] != float64(1) || f["porcentajeUtilizacion"] != esperado ||
			f["horasProgramadas"].(float64) <= f["horasConfirmadas"].(float64) || f["espacios"] != float64(1) {
			t.Fatalf("%s: ocupación inesperada (n=%v, esperado %v%%): %v", agrupacion, n, esperado, f)
		}
		if tot := rep["totales"].(map[string]interface{}); tot["porcentajeUtilizacion"] != esperado {
			t.Fatalf("%s: totales inesperados: %v", agrupacion, tot)
		}
	}
	// Ámbito: un coordinador de otra facultad no ve el uso de estas aulas.
	otro := coordinadorDeOtraFacultad(e, s)
	if rep := e.exigir(http.MethodGet, "/reportes/ocupacion?periodoId="+s.periodo, nil, otro, http.StatusOK); len(elementos(rep["filas"])) != 0 {
		t.Fatalf("fuera del ámbito no hay filas: %v", rep)
	}

	// Exportación (US-REP-02): números como número, auditada con el filtro y los registros.
	xlsx := e.descargar("/reportes/ocupacion/exportar?formato=xlsx&agrupacion=sede&periodoId="+s.periodo, s.admin, http.StatusOK)
	if got := columnaEnXLSX(t, xlsx.Body.Bytes(), "Sesiones con asistencia", "TOTAL"); got != "1" {
		t.Fatalf("el XLSX debe tener la sesión confirmada, tiene %q", got)
	}
	celdaNumerica(t, xlsx.Body.Bytes(), "% utilización", "TOTAL")
	pdf := e.descargar("/reportes/ocupacion/exportar?formato=pdf&periodoId="+s.periodo, s.admin, http.StatusOK)
	if !bytes.HasPrefix(pdf.Body.Bytes(), []byte("%PDF")) {
		t.Fatal("el PDF exportado no es válido")
	}
	e.descargar("/reportes/ocupacion/exportar?formato=xlsx&periodoId="+s.periodo, s.docente, http.StatusForbidden)
	if n := e.auditorias("REPORTE_EXPORTADO", "ocupacion"); n != 2 {
		t.Fatalf("cada exportación de ocupación debe auditarse, hay %d", n)
	}
	// El cumplimiento también exporta los números tipados (US-REP-02 AC-01).
	cumplimiento := e.descargar("/reportes/cumplimiento/exportar?formato=xlsx&periodoId="+s.periodo, s.admin, http.StatusOK)
	celdaNumerica(t, cumplimiento.Body.Bytes(), "Horas programadas", "TOTAL")
	celdaNumerica(t, cumplimiento.Body.Bytes(), "Salidas faltantes", "TOTAL")
}

// celdaNumerica exige que la celda de la columna en la fila clave sea un número, no texto.
func celdaNumerica(t *testing.T, contenido []byte, columna, clave string) {
	t.Helper()
	f, err := excelize.OpenReader(bytes.NewReader(contenido))
	if err != nil {
		t.Fatalf("abrir XLSX: %v", err)
	}
	defer func() { _ = f.Close() }()
	hoja := f.GetSheetName(0)
	filas, _ := f.GetRows(hoja)
	col, fila := -1, -1
	for i, r := range filas {
		for j, v := range r {
			if v == columna {
				col = j
			}
		}
		if len(r) > 0 && r[0] == clave {
			fila = i
		}
	}
	if col < 0 || fila < 0 {
		t.Fatalf("no se encontró %q / %q", columna, clave)
	}
	celda, _ := excelize.CoordinatesToCellName(col+1, fila+1)
	tipo, err := f.GetCellType(hoja, celda)
	if err != nil || (tipo != excelize.CellTypeUnset && tipo != excelize.CellTypeNumber) {
		t.Fatalf("la columna %q debe ser numérica (tipo %v, err %v)", columna, tipo, err)
	}
}
