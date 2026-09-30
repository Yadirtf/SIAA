package integration

import (
	"bytes"
	"net/http"
	"testing"
	"time"

	"github.com/xuri/excelize/v2"
)

var pdfMinimo = []byte("%PDF-1.4\n1 0 obj << /Type /Catalog >> endobj\ntrailer << /Root 1 0 R >>\n%%EOF\n")

// Criterio de aceptación de la fase 2: el docente justifica una ausencia desde mobile, el
// coordinador la aprueba en web y el reporte del periodo lo refleja en el archivo exportado.
func TestJustificacion_AprobadaSeReflejaEnReporteExportado(t *testing.T) {
	// La sesión justificada es de hace una semana; el plazo amplio evita depender del día de la semana.
	t.Setenv("JUSTIFICACION_PLAZO_DIAS", "10")
	e := nuevoEntorno(t)
	s := construirEscenario(e)

	pasada, futura := sesionesDePrueba(e, s)
	radicar := func(sesionID string, soportes []soporte) (int, map[string]interface{}) {
		return e.enviarMultipart("/justificaciones", map[string]string{
			"sesionId": sesionID, "tipo": "INCAPACIDAD", "descripcion": "Incapacidad médica por tres días",
		}, soportes, s.docente)
	}

	// Validaciones de radicación (RF-JUS-001).
	if estado, _ := radicar(pasada, nil); estado != http.StatusUnprocessableEntity {
		t.Fatalf("sin soporte: estado %d, esperado 422", estado)
	}
	if estado, _ := radicar(pasada, []soporte{{"nota.txt", []byte("texto plano, no es imagen ni PDF")}}); estado != http.StatusUnprocessableEntity {
		t.Fatalf("soporte de tipo no permitido: estado %d, esperado 422", estado)
	}
	if estado, _ := radicar(futura, []soporte{{"incapacidad.pdf", pdfMinimo}}); estado != http.StatusUnprocessableEntity {
		t.Fatalf("sesión futura: estado %d, esperado 422", estado)
	}
	estado, j := radicar(pasada, []soporte{{"incapacidad.pdf", pdfMinimo}})
	if estado != http.StatusCreated || j["estado"] != "RADICADA" {
		t.Fatalf("radicar: estado %d: %v", estado, j)
	}
	id := texto(j["id"])
	if estado, _ := radicar(pasada, []soporte{{"otra.pdf", pdfMinimo}}); estado != http.StatusConflict {
		t.Fatalf("segunda justificación de la misma sesión: estado %d, esperado 409", estado)
	}

	// El coordinador de la facultad revisa en web (RF-JUS-002).
	coord := coordinadorDeFacultad(e, s)
	bandeja := e.exigirLista("/justificaciones?estado=RADICADA", coord)
	if len(bandeja) != 1 || bandeja[0]["id"] != id {
		t.Fatalf("la bandeja del coordinador debe mostrar la justificación: %v", bandeja)
	}
	adjuntos, _ := j["adjuntos"].([]interface{})
	adjunto, _ := adjuntos[0].(map[string]interface{})
	rec := e.descargar("/justificaciones/"+id+"/soportes/"+texto(adjunto["id"]), coord, http.StatusOK)
	if !bytes.Equal(rec.Body.Bytes(), pdfMinimo) || rec.Header().Get("Content-Type") != "application/pdf" {
		t.Fatalf("el soporte descargado no coincide con el radicado (%s)", rec.Header().Get("Content-Type"))
	}
	e.exigir(http.MethodPatch, "/justificaciones/"+id, map[string]interface{}{"estado": "APROBADA"}, s.docente, http.StatusForbidden)
	e.exigir(http.MethodPatch, "/justificaciones/"+id, map[string]interface{}{"estado": "RECHAZADA"}, coord, http.StatusUnprocessableEntity)
	e.exigir(http.MethodPatch, "/justificaciones/"+id, map[string]interface{}{"estado": "EN_REVISION"}, coord, http.StatusOK)
	aprobada := e.exigir(http.MethodPatch, "/justificaciones/"+id, map[string]interface{}{
		"estado": "APROBADA", "observaciones": "Soporte médico verificado",
	}, coord, http.StatusOK)
	if aprobada["estado"] != "APROBADA" || len(aprobada["historial"].([]interface{})) != 3 {
		t.Fatalf("la aprobación debe quedar en el historial: %v", aprobada)
	}
	e.exigir(http.MethodPatch, "/justificaciones/"+id, map[string]interface{}{"estado": "RECHAZADA", "observaciones": "Cambio de decisión tardío"}, coord, http.StatusUnprocessableEntity)
	if n := e.auditorias("JUSTIFICACION_APROBADA", id); n != 1 {
		t.Fatalf("se esperaba una auditoría de aprobación, hay %d", n)
	}
	propias := e.exigirLista("/justificaciones", s.docente)
	if len(propias) != 1 || propias[0]["estado"] != "APROBADA" {
		t.Fatalf("el docente debe ver su justificación aprobada: %v", propias)
	}

	// El reporte del periodo refleja la ausencia justificada (RF-JUS-004, RF-REP-001).
	e.exigir(http.MethodGet, "/reportes/cumplimiento?periodoId="+s.periodo, nil, s.docente, http.StatusForbidden)
	e.exigir(http.MethodGet, "/reportes/cumplimiento", nil, coord, http.StatusUnprocessableEntity)
	rep := e.exigir(http.MethodGet, "/reportes/cumplimiento?periodoId="+s.periodo, nil, coord, http.StatusOK)
	fila := filaDocente(t, rep, s.docenteID)
	if fila["ausenciasJustificadas"] != float64(1) || fila["ausenciasInjustificadas"].(float64) < 1 {
		t.Fatalf("el reporte debe tener una ausencia justificada y las demás injustificadas: %v", fila)
	}
	if fila["horasJustificadas"].(float64) <= 0 || fila["porcentajeCumplimiento"].(float64) >= 100 {
		t.Fatalf("horas justificadas y cumplimiento inconsistentes: %v", fila)
	}

	// El archivo exportado lleva el mismo dato (RF-REP-004).
	xlsx := e.descargar("/reportes/cumplimiento/exportar?formato=xlsx&periodoId="+s.periodo, coord, http.StatusOK)
	if got := columnaEnXLSX(t, xlsx.Body.Bytes(), "Aus. justificadas", "TOTAL"); got != "1" {
		t.Fatalf("el XLSX exportado debe reflejar la ausencia justificada, tiene %q", got)
	}
	pdf := e.descargar("/reportes/cumplimiento/exportar?formato=pdf&periodoId="+s.periodo, coord, http.StatusOK)
	if !bytes.HasPrefix(pdf.Body.Bytes(), []byte("%PDF")) {
		t.Fatalf("el PDF exportado no es válido")
	}
	e.exigir(http.MethodGet, "/reportes/cumplimiento/exportar?formato=csv&periodoId="+s.periodo, nil, coord, http.StatusUnprocessableEntity)
	if n := e.auditorias("REPORTE_EXPORTADO", ""); n != 2 {
		t.Fatalf("cada exportación debe auditarse, hay %d", n)
	}
}

// RF-AUD-003: la bitácora se consulta con filtros y se exporta; la exportación queda auditada.
func TestAuditoria_ConsultaYExportacion(t *testing.T) {
	e := nuevoEntorno(t)
	s := construirEscenario(e)

	lista := e.exigirLista("/auditoria?entidad=periodo&limite=5", s.admin)
	if len(lista) == 0 || lista[0]["entidad"] != "periodo" || lista[0]["actorNombre"] == "" {
		t.Fatalf("la bitácora filtrada debe traer los periodos con su actor: %v", lista)
	}
	hoy := time.Now().In(bogota).Format("2006-01-02")
	if len(e.exigirLista("/auditoria?desde="+hoy+"&hasta="+hoy, s.admin)) == 0 {
		t.Fatalf("la bitácora de hoy no debe estar vacía")
	}
	if len(e.exigirLista("/auditoria?hasta=2000-01-01", s.admin)) != 0 {
		t.Fatalf("no debe haber registros anteriores al año 2000")
	}
	e.exigir(http.MethodGet, "/auditoria?desde=ayer", nil, s.admin, http.StatusUnprocessableEntity)
	e.exigir(http.MethodGet, "/auditoria", nil, s.docente, http.StatusForbidden)

	xlsx := e.descargar("/auditoria/exportar?formato=xlsx&entidad=periodo", s.admin, http.StatusOK)
	if !bytes.HasPrefix(xlsx.Body.Bytes(), []byte("PK")) {
		t.Fatalf("el XLSX de auditoría no es válido")
	}
	pdf := e.descargar("/auditoria/exportar?formato=pdf", s.admin, http.StatusOK)
	if !bytes.HasPrefix(pdf.Body.Bytes(), []byte("%PDF")) {
		t.Fatalf("el PDF de auditoría no es válido")
	}
	if n := e.auditorias("AUDITORIA_EXPORTADA", ""); n != 2 {
		t.Fatalf("cada exportación de la bitácora debe auditarse, hay %d", n)
	}
}

// sesionesDePrueba devuelve una sesión de hace una semana (terminada) y una futura.
func sesionesDePrueba(e *entorno, s *escenario) (pasada, futura string) {
	e.t.Helper()
	haceSemana := time.Now().In(bogota).AddDate(0, 0, -7).Format("2006-01-02")
	lista := e.exigirLista("/sesiones?periodoId="+s.periodo, s.admin)
	for _, se := range lista {
		if se["fecha"] == haceSemana {
			pasada = texto(se["id"])
		}
	}
	if pasada == "" || len(lista) < 2 {
		e.t.Fatalf("no se encontró la sesión de hace una semana (%s): %v", haceSemana, lista)
	}
	return pasada, texto(lista[len(lista)-1]["id"])
}

// coordinadorDeFacultad crea un coordinador con ámbito en la facultad del escenario.
func coordinadorDeFacultad(e *entorno, s *escenario) string {
	e.t.Helper()
	e.exigir(http.MethodPost, "/usuarios", map[string]interface{}{
		"correo": "coord.ing@siaa.edu.co", "nombre": "Camila", "apellido": "Rojas", "password": "Coordinadora2026*",
		"roles": []map[string]interface{}{{"nombre": "COORDINADOR"}}, "ambitos": []map[string]interface{}{{"tipo": "FACULTAD", "id": s.facultad}},
	}, s.admin, http.StatusCreated)
	return e.token("coord.ing@siaa.edu.co", "Coordinadora2026*")
}

func (e *entorno) exigirLista(ruta, token string) []map[string]interface{} {
	e.t.Helper()
	estado, datos := e.llamar(http.MethodGet, ruta, nil, token)
	if estado != http.StatusOK {
		e.t.Fatalf("GET %s: estado %d: %v", ruta, estado, datos)
	}
	return elementos(datos)
}

func filaDocente(t *testing.T, rep map[string]interface{}, docenteID string) map[string]interface{} {
	t.Helper()
	for _, d := range elementos(map[string]interface{}{"items": rep["docentes"]}) {
		if d["docenteId"] == docenteID {
			return d
		}
	}
	t.Fatalf("el reporte no incluye al docente %s: %v", docenteID, rep)
	return nil
}

// columnaEnXLSX devuelve el valor de la columna en la fila cuyo primer valor es clave.
func columnaEnXLSX(t *testing.T, contenido []byte, columna, clave string) string {
	t.Helper()
	f, err := excelize.OpenReader(bytes.NewReader(contenido))
	if err != nil {
		t.Fatalf("abrir XLSX: %v", err)
	}
	defer func() { _ = f.Close() }()
	filas, err := f.GetRows(f.GetSheetName(0))
	if err != nil {
		t.Fatalf("leer XLSX: %v", err)
	}
	indice := -1
	for _, fila := range filas {
		for i, v := range fila {
			if v == columna {
				indice = i
			}
		}
		if indice >= 0 && len(fila) > indice && len(fila) > 0 && fila[0] == clave {
			return fila[indice]
		}
	}
	t.Fatalf("no se encontró %q/%q en el XLSX: %v", columna, clave, filas)
	return ""
}
