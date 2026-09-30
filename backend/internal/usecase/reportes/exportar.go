package reportes

import (
	"context"
	"fmt"
	"strconv"
	"strings"

	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/platform/exportar"
	"github.com/siaa/backend/internal/repository"
)

// Archivo es un reporte exportado listo para descargar.
type Archivo struct {
	Nombre    string
	Mime      string
	Contenido []byte
}

const (
	FormatoXLSX = "xlsx"
	FormatoPDF  = "pdf"
)

// ExportarCumplimiento genera el reporte en XLSX o PDF y deja constancia en la bitácora.
func (s *Service) ExportarCumplimiento(ctx context.Context, actor Actor, f Filtro, formato string) (*Archivo, error) {
	if formato != FormatoXLSX && formato != FormatoPDF {
		return nil, shared.NewValidationError("formato inválido; use xlsx o pdf")
	}
	rep, err := s.Cumplimiento(ctx, actor, f)
	if err != nil {
		return nil, err
	}
	tabla := tablaCumplimiento(rep, s.nombreActor(ctx, actor))
	tabla.Metadatos = s.metadatosFiltro(ctx, rep.Filtro, rep.FalsosRechazos)

	arch := &Archivo{Nombre: "cumplimiento-" + rep.GeneradoEn.Format("20060102-1504") + "." + formato}
	if formato == FormatoXLSX {
		arch.Mime = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
		arch.Contenido, err = exportar.XLSX(tabla)
	} else {
		arch.Mime = "application/pdf"
		arch.Contenido, err = exportar.PDF(tabla)
	}
	if err != nil {
		return nil, err
	}
	if s.auditoria != nil {
		_ = s.auditoria.Create(ctx, &repository.AuditEntry{
			Entidad:   "reportes",
			EntidadID: "cumplimiento",
			Accion:    "REPORTE_EXPORTADO",
			ActorID:   actor.UsuarioID,
			RolActivo: actor.RolActivo,
			ValorNuevo: map[string]interface{}{
				"formato": formato, "filtro": f, "docentes": len(rep.Docentes), "huella": tabla.Huella(),
			},
			CreadoEn: rep.GeneradoEn,
		})
	}
	return arch, nil
}

func (s *Service) nombreActor(ctx context.Context, actor Actor) string {
	if u, err := s.usuarios.FindByID(ctx, actor.UsuarioID); err == nil && u != nil {
		return strings.TrimSpace(u.Nombre+" "+u.Apellido) + " <" + u.Correo + ">"
	}
	return actor.UsuarioID
}

func tablaCumplimiento(rep *Reporte, generadoPor string) exportar.Tabla {
	t := exportar.Tabla{
		Titulo:      "Reporte de cumplimiento docente",
		Columnas:    []string{"Docente", "Documento", "Sesiones", "Horas programadas", "Horas dictadas", "Horas justificadas", "Presentes", "Tardanzas", "Aus. justificadas", "Aus. injustificadas", "Ajustadas", "% cumplimiento"},
		Anchos:      []float64{3, 1.6, 1, 1.3, 1.3, 1.3, 1, 1, 1.2, 1.3, 1, 1.2},
		GeneradoEn:  rep.GeneradoEn,
		GeneradoPor: generadoPor,
	}
	for _, d := range rep.Docentes {
		t.Filas = append(t.Filas, fila(d.Nombre, d.Documento, d))
	}
	t.Filas = append(t.Filas, fila("TOTAL", "", rep.Totales))
	return t
}

func fila(nombre, documento string, d FilaDocente) []string {
	if nombre == "" {
		nombre = d.DocenteID
	}
	return []string{
		nombre, documento, strconv.Itoa(d.Sesiones),
		horas(d.HorasProgramadas), horas(d.HorasDictadas), horas(d.HorasJustificadas),
		strconv.Itoa(d.Presentes), strconv.Itoa(d.Tardanzas),
		strconv.Itoa(d.AusenciasJustificadas), strconv.Itoa(d.AusenciasInjustificada),
		strconv.Itoa(d.Ajustadas), fmt.Sprintf("%.1f%%", d.PorcentajeCumplimiento),
	}
}

func horas(h float64) string { return strconv.FormatFloat(h, 'f', 2, 64) }

// metadatosFiltro describe los filtros con nombres legibles cuando se encuentran.
func (s *Service) metadatosFiltro(ctx context.Context, f Filtro, falsosRechazos int) [][2]string {
	var m [][2]string
	agregar := func(etiqueta, valor string) {
		if valor != "" {
			m = append(m, [2]string{etiqueta, valor})
		}
	}
	periodo, facultad, programa, docente := f.PeriodoID, f.FacultadID, f.ProgramaID, f.DocenteID
	if s.periodos != nil && periodo != "" {
		if p, err := s.periodos.GetByID(ctx, periodo); err == nil && p != nil {
			periodo = p.Nombre()
		}
	}
	if facultad != "" {
		if x, err := s.estructura.GetFacultadByID(ctx, facultad); err == nil && x != nil {
			facultad = x.Nombre()
		}
	}
	if programa != "" {
		if x, err := s.estructura.GetProgramaByID(ctx, programa); err == nil && x != nil {
			programa = x.Nombre()
		}
	}
	if docente != "" {
		if u, err := s.usuarios.FindByID(ctx, docente); err == nil && u != nil {
			docente = strings.TrimSpace(u.Nombre + " " + u.Apellido)
		}
	}
	agregar("Periodo", periodo)
	agregar("Facultad", facultad)
	agregar("Programa", programa)
	agregar("Docente", docente)
	agregar("Desde", f.Desde)
	agregar("Hasta", f.Hasta)
	m = append(m, [2]string{"Falsos rechazos (falla técnica aprobada)", strconv.Itoa(falsosRechazos)})
	return m
}
