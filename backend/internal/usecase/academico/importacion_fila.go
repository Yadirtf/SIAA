package academico

import (
	"strconv"
	"strings"

	"github.com/siaa/backend/internal/platform/importar"
)

// FilaImportacionAcademica es una fila de la plantilla de carga masiva con su diagnóstico.
type FilaImportacionAcademica struct {
	NumeroFila       int      `json:"numeroFila"`
	PeriodoCodigo    string   `json:"periodoCodigo"`
	FacultadCodigo   string   `json:"facultadCodigo"`
	ProgramaCodigo   string   `json:"programaCodigo"`
	AsignaturaCodigo string   `json:"asignaturaCodigo"`
	AsignaturaNombre string   `json:"asignaturaNombre"`
	GrupoCodigo      string   `json:"grupoCodigo"`
	DocenteDocumento string   `json:"docenteDocumento"`
	AulaCodigo       string   `json:"aulaCodigo"`
	DiaSemana        int      `json:"diaSemana"`
	HoraInicio       string   `json:"horaInicio"`
	HoraFin          string   `json:"horaFin"`
	Modalidad        string   `json:"modalidad"`
	Valida           bool     `json:"valida"`
	Errores          []string `json:"errores,omitempty"`
	Advertencias     []string `json:"advertencias,omitempty"`
}

func (f *FilaImportacionAcademica) error(msg string) {
	f.Valida = false
	f.Errores = append(f.Errores, msg)
}

func (f *FilaImportacionAcademica) advertir(msg string) {
	f.Advertencias = append(f.Advertencias, msg)
}

// columnasPlantilla es el orden de la plantilla publicada (T-ACA-07.1); se usa cuando el
// archivo no trae encabezados reconocibles.
var columnasPlantilla = []string{"periodo", "facultad", "programa", "asignatura", "asignaturanombre",
	"grupo", "docente", "aula", "dia", "horainicio", "horafin", "modalidad"}

// aliasColumnas mapea encabezados normalizados a la columna canónica.
var aliasColumnas = map[string]string{
	"periodo": "periodo", "periodocodigo": "periodo",
	"facultad": "facultad", "facultadcodigo": "facultad",
	"programa": "programa", "programacodigo": "programa",
	"asignatura": "asignatura", "asignaturacodigo": "asignatura", "codigoasignatura": "asignatura",
	"asignaturanombre": "asignaturanombre", "nombreasignatura": "asignaturanombre",
	"grupo": "grupo", "grupocodigo": "grupo", "numerogrupo": "grupo",
	"docente": "docente", "docentedocumento": "docente", "documentodocente": "docente", "docentecorreo": "docente",
	"aula": "aula", "aulacodigo": "aula", "espacio": "aula", "espaciocodigo": "aula",
	"dia": "dia", "diasemana": "dia",
	"horainicio": "horainicio", "inicio": "horainicio",
	"horafin": "horafin", "fin": "horafin",
	"modalidad": "modalidad",
}

// indiceColumnas ubica cada columna canónica en el archivo (o usa el orden de la plantilla).
func indiceColumnas(encabezados []string) map[string]int {
	idx := map[string]int{}
	for i, h := range encabezados {
		if c, ok := aliasColumnas[importar.Normalizar(h)]; ok {
			if _, ya := idx[c]; !ya {
				idx[c] = i
			}
		}
	}
	if len(idx) < 4 {
		idx = map[string]int{}
		for i, c := range columnasPlantilla {
			idx[c] = i
		}
	}
	return idx
}

var diasSemana = map[string]int{"lunes": 1, "martes": 2, "miercoles": 3, "jueves": 4, "viernes": 5, "sabado": 6, "domingo": 7}

// parsearFila lee las celdas y valida tipos y obligatoriedad (T-ACA-07.3).
func parsearFila(f importar.Fila, idx map[string]int) FilaImportacionAcademica {
	celda := func(c string) string {
		if i, ok := idx[c]; ok && i < len(f.Celdas) {
			return f.Celdas[i]
		}
		return ""
	}
	fila := FilaImportacionAcademica{
		NumeroFila:       f.Numero,
		PeriodoCodigo:    celda("periodo"),
		FacultadCodigo:   celda("facultad"),
		ProgramaCodigo:   celda("programa"),
		AsignaturaCodigo: celda("asignatura"),
		AsignaturaNombre: celda("asignaturanombre"),
		GrupoCodigo:      celda("grupo"),
		DocenteDocumento: celda("docente"),
		AulaCodigo:       celda("aula"),
		HoraInicio:       normalizarHora(celda("horainicio")),
		HoraFin:          normalizarHora(celda("horafin")),
		Modalidad:        strings.ToUpper(importar.Normalizar(celda("modalidad"))),
		Valida:           true,
	}
	if fila.Modalidad == "" {
		fila.Modalidad = "PRESENCIAL"
	}
	switch fila.Modalidad {
	case "PRESENCIAL", "VIRTUAL", "HIBRIDA":
	default:
		fila.error("Modalidad '" + celda("modalidad") + "' no reconocida (PRESENCIAL, VIRTUAL o HIBRIDA)")
	}
	dia := importar.Normalizar(celda("dia"))
	if n, err := strconv.Atoi(dia); err == nil && n >= 1 && n <= 7 {
		fila.DiaSemana = n
	} else if n, ok := diasSemana[dia]; ok {
		fila.DiaSemana = n
	} else {
		fila.error("Día de la semana inválido: use 1 (lunes) a 7 (domingo) o el nombre del día")
	}
	obligatorias := []struct{ valor, nombre string }{
		{fila.PeriodoCodigo, "periodo"}, {fila.AsignaturaCodigo, "asignatura"}, {fila.GrupoCodigo, "grupo"},
		{fila.DocenteDocumento, "docente"}, {fila.HoraInicio, "hora de inicio"}, {fila.HoraFin, "hora de fin"},
	}
	for _, o := range obligatorias {
		if o.valor == "" {
			fila.error("La columna " + o.nombre + " es obligatoria")
		}
	}
	if fila.AulaCodigo == "" && fila.Modalidad != "VIRTUAL" {
		fila.error("El aula es obligatoria para la modalidad " + fila.Modalidad)
	}
	return fila
}

// normalizarHora acepta 7:00, 07:00, 0700 o la fracción de día que guarda Excel.
func normalizarHora(h string) string {
	h = strings.TrimSpace(h)
	if h == "" {
		return ""
	}
	if f, err := strconv.ParseFloat(h, 64); err == nil && f > 0 && f < 1 {
		min := int(f*24*60 + 0.5)
		return dosDigitos(min/60) + ":" + dosDigitos(min%60)
	}
	if len(h) == 4 && !strings.Contains(h, ":") {
		h = h[:2] + ":" + h[2:]
	}
	partes := strings.SplitN(h, ":", 3)
	if len(partes) >= 2 {
		hh, err1 := strconv.Atoi(partes[0])
		mm, err2 := strconv.Atoi(partes[1])
		if err1 == nil && err2 == nil {
			return dosDigitos(hh) + ":" + dosDigitos(mm)
		}
	}
	return h
}

func dosDigitos(n int) string {
	if n < 10 {
		return "0" + strconv.Itoa(n)
	}
	return strconv.Itoa(n)
}
