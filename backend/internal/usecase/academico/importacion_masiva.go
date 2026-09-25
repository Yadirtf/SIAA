// Package academico — Importación masiva de estructura académica y horarios (US-ACA-07).
// Satisface US-ACA-07 (AC-01..AC-06), RF-ACA-009 y el pipeline de carga masiva.
package academico

import (
	"context"
	"encoding/csv"
	"fmt"
	"io"
	"strconv"
	"strings"

	"github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/domain/shared"
)

// FilaImportacionAcademica representa una fila procesada del archivo CSV.
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
}

// PreviewImportacionAcademicaDTO resumen preliminar con validaciones estructurales y de negocio (AC-01, AC-02).
type PreviewImportacionAcademicaDTO struct {
	TotalFilas    int                        `json:"totalFilas"`
	FilasValidas  int                        `json:"filasValidas"`
	FilasConError int                        `json:"filasConError"`
	Filas         []FilaImportacionAcademica `json:"filas"`
}

// ResultadoImportacionAcademicaDTO resultado tras confirmación de la importación (AC-03, AC-04).
type ResultadoImportacionAcademicaDTO struct {
	TotalProcesadas     int      `json:"totalProcesadas"`
	AsignacionesCreadas int      `json:"asignacionesCreadas"`
	Errores             []string `json:"errores,omitempty"`
	Mensaje             string   `json:"mensaje"`
}

// ValidarImportacionCSV procesa y valida estructuralmente un archivo CSV (US-ACA-07 AC-01, AC-02).
func (s *Service) ValidarImportacionCSV(r io.Reader) (*PreviewImportacionAcademicaDTO, error) {
	reader := csv.NewReader(r)
	reader.TrimLeadingSpace = true

	// Leer encabezados
	headers, err := reader.Read()
	if err != nil {
		return nil, shared.NewValidationError("No se pudo leer el encabezado del archivo CSV", shared.FieldError{
			Campo: "archivo", Error: "CSV_VACIO_O_INVALIDO",
		})
	}
	if len(headers) < 8 {
		return nil, shared.NewValidationError("El archivo CSV no cuenta con las columnas mínimas requeridas", shared.FieldError{
			Campo: "columnas", Error: "COLUMNAS_INSUFICIENTES",
		})
	}

	preview := &PreviewImportacionAcademicaDTO{
		Filas: make([]FilaImportacionAcademica, 0),
	}

	numFila := 1
	for {
		record, err := reader.Read()
		if err == io.EOF {
			break
		}
		if err != nil {
			continue
		}
		numFila++

		fila := FilaImportacionAcademica{
			NumeroFila: numFila,
			Valida:     true,
			Errores:    make([]string, 0),
		}

		if len(record) > 0 {
			fila.PeriodoCodigo = strings.TrimSpace(record[0])
		}
		if len(record) > 1 {
			fila.FacultadCodigo = strings.TrimSpace(record[1])
		}
		if len(record) > 2 {
			fila.ProgramaCodigo = strings.TrimSpace(record[2])
		}
		if len(record) > 3 {
			fila.AsignaturaCodigo = strings.TrimSpace(record[3])
		}
		if len(record) > 4 {
			fila.AsignaturaNombre = strings.TrimSpace(record[4])
		}
		if len(record) > 5 {
			fila.GrupoCodigo = strings.TrimSpace(record[5])
		}
		if len(record) > 6 {
			fila.DocenteDocumento = strings.TrimSpace(record[6])
		}
		if len(record) > 7 {
			fila.AulaCodigo = strings.TrimSpace(record[7])
		}

		if len(record) > 8 {
			d, errDia := strconv.Atoi(strings.TrimSpace(record[8]))
			if errDia != nil || d < 1 || d > 7 {
				fila.Valida = false
				fila.Errores = append(fila.Errores, "Día de la semana debe ser entero entre 1 (Lunes) y 7 (Domingo)")
			} else {
				fila.DiaSemana = d
			}
		} else {
			fila.DiaSemana = 1
		}

		if len(record) > 9 {
			fila.HoraInicio = strings.TrimSpace(record[9])
		} else {
			fila.HoraInicio = "08:00"
		}
		if len(record) > 10 {
			fila.HoraFin = strings.TrimSpace(record[10])
		} else {
			fila.HoraFin = "10:00"
		}
		if len(record) > 11 {
			fila.Modalidad = strings.ToUpper(strings.TrimSpace(record[11]))
		} else {
			fila.Modalidad = "PRESENCIAL"
		}

		// Validaciones de obligatoriedad
		if fila.PeriodoCodigo == "" {
			fila.Valida = false
			fila.Errores = append(fila.Errores, "El código del periodo es obligatorio")
		}
		if fila.AsignaturaCodigo == "" {
			fila.Valida = false
			fila.Errores = append(fila.Errores, "El código de la asignatura es obligatorio")
		}
		if fila.DocenteDocumento == "" {
			fila.Valida = false
			fila.Errores = append(fila.Errores, "El documento o ID del docente es obligatorio")
		}

		// Validar formato de horas
		if _, _, errH := academico.NuevaFranjaHoraria(fila.DiaSemana, fila.HoraInicio, fila.HoraFin, "America/Bogota"); errH != nil {
			fila.Valida = false
			fila.Errores = append(fila.Errores, fmt.Sprintf("Franja horaria inválida (%s - %s): %v", fila.HoraInicio, fila.HoraFin, errH))
		}

		preview.TotalFilas++
		if fila.Valida {
			preview.FilasValidas++
		} else {
			preview.FilasConError++
		}
		preview.Filas = append(preview.Filas, fila)
	}

	return preview, nil
}

// ConfirmarImportacionAcademicaCmd payload con filas validadas a persistir.
type ConfirmarImportacionAcademicaCmd struct {
	Filas []FilaImportacionAcademica `json:"filas"`
	Actor ContextoActor              `json:"-"`
}

// ConfirmarImportacionAcademica persiste las asignaciones académicas validadas (US-ACA-07 AC-03).
func (s *Service) ConfirmarImportacionAcademica(ctx context.Context, cmd ConfirmarImportacionAcademicaCmd) (*ResultadoImportacionAcademicaDTO, error) {
	if len(cmd.Filas) == 0 {
		return nil, shared.NewValidationError("No hay filas para importar", shared.FieldError{Campo: "filas", Error: "LISTA_VACIA"})
	}

	res := &ResultadoImportacionAcademicaDTO{
		TotalProcesadas: len(cmd.Filas),
		Errores:         make([]string, 0),
	}

	now := s.clk.Now()

	for _, f := range cmd.Filas {
		if !f.Valida {
			continue
		}

		// 1. Obtener periodo por código
		var periodo *academico.Periodo
		periodos, _ := s.periodoRepo.ListAll(ctx)
		for _, p := range periodos {
			if p.Codigo() == f.PeriodoCodigo || p.ID() == f.PeriodoCodigo {
				periodo = p
				break
			}
		}
		if periodo == nil {
			res.Errores = append(res.Errores, fmt.Sprintf("Fila %d: periodo '%s' no encontrado", f.NumeroFila, f.PeriodoCodigo))
			continue
		}

		// 2. Obtener o validar aula si es presencial
		espacioID := f.AulaCodigo
		if f.AulaCodigo != "" && s.espacioRepo != nil {
			esp, _ := s.espacioRepo.FindByCodigo(ctx, f.AulaCodigo)
			if esp != nil {
				espacioID = esp.ID
			}
		}

		// 3. Crear FranjaHoraria
		franja, _, errFranja := academico.NuevaFranjaHoraria(f.DiaSemana, f.HoraInicio, f.HoraFin, "America/Bogota")
		if errFranja != nil {
			res.Errores = append(res.Errores, fmt.Sprintf("Fila %d: franja inválida: %v", f.NumeroFila, errFranja))
			continue
		}

		// 4. Crear Asignación
		modalidad := academico.ModalidadPresencial
		if f.Modalidad == "VIRTUAL" {
			modalidad = academico.ModalidadVirtual
		} else if f.Modalidad == "HIBRIDA" {
			modalidad = academico.ModalidadHibrida
		}

		asig, errAsig := academico.NuevaAsignacion(
			shared.NewID(),
			periodo.ID(),
			[]string{f.DocenteDocumento},
			"Docente",
			f.GrupoCodigo,
			f.AsignaturaCodigo,
			f.FacultadCodigo,
			espacioID,
			f.AulaCodigo,
			franja,
			modalidad,
			nil,
			periodo.FechaInicio(),
			periodo.FechaFin(),
			nil,
			now,
		)
		if errAsig != nil {
			res.Errores = append(res.Errores, fmt.Sprintf("Fila %d: error al construir asignación: %v", f.NumeroFila, errAsig))
			continue
		}

		if errSave := s.asignacionRepo.Create(ctx, asig); errSave != nil {
			res.Errores = append(res.Errores, fmt.Sprintf("Fila %d: error al persistir asignación: %v", f.NumeroFila, errSave))
		} else {
			res.AsignacionesCreadas++
		}
	}

	res.Mensaje = fmt.Sprintf("Importación académica completada: %d asignaciones creadas.", res.AsignacionesCreadas)
	s.auditar(ctx, "academico", "masivo", "CARGA_MASIVA_ACADEMICA", cmd.Actor, nil, map[string]interface{}{
		"creadas": res.AsignacionesCreadas,
		"errores": len(res.Errores),
	})

	return res, nil
}

// PreviewImportacionCSV valida un archivo CSV (US-ACA-07 AC-01, AC-02).
func (s *Service) PreviewImportacionCSV(ctx context.Context, r io.Reader) (*PreviewImportacionAcademicaDTO, error) {
	return s.ValidarImportacionCSV(r)
}

// ConfirmarImportacionCSV procesa y persiste asignaciones desde un CSV (US-ACA-07 AC-03, AC-04).
func (s *Service) ConfirmarImportacionCSV(ctx context.Context, r io.Reader, actor ContextoActor) (*ResultadoImportacionAcademicaDTO, error) {
	prev, err := s.ValidarImportacionCSV(r)
	if err != nil {
		return nil, err
	}
	return s.ConfirmarImportacionAcademica(ctx, ConfirmarImportacionAcademicaCmd{
		Filas: prev.Filas,
		Actor: actor,
	})
}
