// Package auditoria expone la consulta y exportación de la bitácora (RF-AUD-003).
// La bitácora no admite edición ni borrado desde la aplicación.
package auditoria

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"

	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/platform/exportar"
	"github.com/siaa/backend/internal/repository"
)

// MaxFilasExportacion limita el tamaño del archivo exportado; se exportan las más recientes.
const MaxFilasExportacion = 10000

// Entrada es un registro de la bitácora con el nombre legible del actor.
type Entrada struct {
	*repository.AuditEntry
	ActorNombre string
}

// Pagina es un resultado paginado de la bitácora.
type Pagina struct {
	Entradas []Entrada
	Total    int64
}

// Archivo es la bitácora exportada.
type Archivo struct {
	Nombre    string
	Mime      string
	Contenido []byte
}

// Service consulta la bitácora y registra cada exportación.
type Service struct {
	lectura   repository.AuditoriaConsultaRepository
	escritura repository.AuditoriaRepository
	usuarios  repository.UsuarioRepository
	clock     shared.Clock
}

// NewService crea el servicio de consulta de auditoría.
func NewService(lectura repository.AuditoriaConsultaRepository, escritura repository.AuditoriaRepository, usuarios repository.UsuarioRepository, clock shared.Clock) *Service {
	return &Service{lectura: lectura, escritura: escritura, usuarios: usuarios, clock: clock}
}

// Consultar devuelve una página de la bitácora, de la más reciente a la más antigua.
func (s *Service) Consultar(ctx context.Context, f repository.FiltroAuditoria, pagina, limite int64) (*Pagina, error) {
	if pagina < 1 {
		pagina = 1
	}
	if limite <= 0 || limite > 200 {
		limite = 50
	}
	lista, total, err := s.lectura.Buscar(ctx, f, (pagina-1)*limite, limite)
	if err != nil {
		return nil, err
	}
	return &Pagina{Entradas: s.conNombres(ctx, lista), Total: total}, nil
}

// Exportar genera la bitácora filtrada en XLSX o PDF y audita la propia exportación.
func (s *Service) Exportar(ctx context.Context, actorID, rolActivo string, f repository.FiltroAuditoria, formato string) (*Archivo, error) {
	if formato != "xlsx" && formato != "pdf" {
		return nil, shared.NewValidationError("formato inválido; use xlsx o pdf")
	}
	lista, total, err := s.lectura.Buscar(ctx, f, 0, MaxFilasExportacion)
	if err != nil {
		return nil, err
	}
	ahora := s.clock.Now()
	tabla := exportar.Tabla{
		Titulo:      "Bitácora de auditoría",
		Metadatos:   metadatos(f, len(lista), total),
		Columnas:    []string{"Fecha", "Actor", "Rol", "Acción", "Entidad", "Identificador", "IP", "Valor anterior", "Valor nuevo"},
		Anchos:      []float64{1.5, 2, 1.3, 2.2, 1.2, 1.8, 1.1, 3, 3},
		GeneradoEn:  ahora,
		GeneradoPor: s.nombre(ctx, actorID),
	}
	for _, e := range s.conNombres(ctx, lista) {
		tabla.Filas = append(tabla.Filas, []string{
			shared.FechaHoraSegundosLocal(e.CreadoEn),
			e.ActorNombre, e.RolActivo, e.Accion, e.Entidad, e.EntidadID, e.IPOrigen,
			comoTexto(e.ValorAnterior), comoTexto(e.ValorNuevo),
		})
	}
	arch := &Archivo{Nombre: "auditoria-" + ahora.Format("20060102-1504") + "." + formato}
	if formato == "xlsx" {
		arch.Mime = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
		arch.Contenido, err = exportar.XLSX(tabla)
	} else {
		arch.Mime = "application/pdf"
		arch.Contenido, err = exportar.PDF(tabla)
	}
	if err != nil {
		return nil, err
	}
	_ = s.escritura.Create(ctx, &repository.AuditEntry{
		Entidad: "auditoria", EntidadID: "bitacora", Accion: "AUDITORIA_EXPORTADA",
		ActorID: actorID, RolActivo: rolActivo, CreadoEn: ahora,
		ValorNuevo: map[string]interface{}{"formato": formato, "filtro": f, "registros": len(lista), "huella": tabla.Huella()},
	})
	return arch, nil
}

func (s *Service) conNombres(ctx context.Context, lista []*repository.AuditEntry) []Entrada {
	nombres := map[string]string{}
	res := make([]Entrada, len(lista))
	for i, e := range lista {
		n, ok := nombres[e.ActorID]
		if !ok {
			n = s.nombre(ctx, e.ActorID)
			nombres[e.ActorID] = n
		}
		res[i] = Entrada{AuditEntry: e, ActorNombre: n}
	}
	return res
}

func (s *Service) nombre(ctx context.Context, id string) string {
	if id == "" {
		return "sistema"
	}
	if u, err := s.usuarios.FindByID(ctx, id); err == nil && u != nil {
		return strings.TrimSpace(u.Nombre + " " + u.Apellido)
	}
	return id
}

func comoTexto(v interface{}) string {
	switch x := v.(type) {
	case nil:
		return ""
	case string:
		return recortar(x)
	}
	b, err := json.Marshal(v)
	if err != nil {
		return recortar(fmt.Sprint(v))
	}
	return recortar(string(b))
}

// recortar mantiene cada celda por debajo del límite de Excel (32 767 caracteres).
func recortar(s string) string {
	const max = 4000
	if r := []rune(s); len(r) > max {
		return string(r[:max]) + "..."
	}
	return s
}

func metadatos(f repository.FiltroAuditoria, exportados int, total int64) [][2]string {
	m := [][2]string{}
	for _, p := range [][2]string{{"Entidad", f.Entidad}, {"Identificador", f.EntidadID}, {"Actor", f.ActorID}, {"Acción", f.Accion}} {
		if p[1] != "" {
			m = append(m, p)
		}
	}
	if f.Desde != nil {
		m = append(m, [2]string{"Desde", shared.FechaHoraLocal(*f.Desde)})
	}
	if f.Hasta != nil {
		m = append(m, [2]string{"Hasta", shared.FechaHoraLocal(*f.Hasta)})
	}
	return append(m, [2]string{"Registros", fmt.Sprintf("%d de %d", exportados, total)})
}
