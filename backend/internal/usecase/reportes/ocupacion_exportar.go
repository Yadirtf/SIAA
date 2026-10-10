package reportes

import (
	"context"
	"fmt"
	"strconv"

	"github.com/siaa/backend/internal/platform/exportar"
)

// Exportar genera el reporte de ocupación en XLSX o PDF con las mismas reglas de
// US-REP-02: sello, huella, tipos de dato y auditoría (US-REP-04 AC-03).
func (o *OcupacionService) Exportar(ctx context.Context, actor Actor, f FiltroOcupacion, formato string) (*Archivo, error) {
	if err := validarFormato(formato); err != nil {
		return nil, err
	}
	rep, err := o.Calcular(ctx, actor, f)
	if err != nil {
		return nil, err
	}
	tabla := tablaOcupacion(rep, o.base.nombreActor(ctx, actor))
	tabla.Metadatos = o.base.describirFiltro(ctx, Filtro{
		PeriodoID: rep.Filtro.PeriodoID, FacultadID: rep.Filtro.FacultadID, Desde: rep.Filtro.Desde, Hasta: rep.Filtro.Hasta,
	})
	u := newUbicaciones(o.espacios, o.bloques, o.sedes)
	if rep.Filtro.SedeID != "" {
		tabla.Metadatos = append(tabla.Metadatos, [2]string{"Sede", u.nombreSede(ctx, rep.Filtro.SedeID)})
	}
	if rep.Filtro.BloqueID != "" {
		tabla.Metadatos = append(tabla.Metadatos, [2]string{"Bloque", u.nombreBloque(ctx, rep.Filtro.BloqueID)})
	}
	tabla.Metadatos = append(tabla.Metadatos, [2]string{"Agrupación", rep.Filtro.Agrupacion})
	return o.base.exportarTabla(ctx, actor, exportacion{
		tabla: tabla, formato: formato, base: "ocupacion", filtro: f, registros: len(rep.Filas),
		etiquetaRegistros: "filas",
	})
}

func tablaOcupacion(rep *ReporteOcupacion, generadoPor string) exportar.Tabla {
	primera := map[string]string{AgruparAula: "Aula", AgruparBloque: "Bloque", AgruparSede: "Sede"}[rep.Filtro.Agrupacion]
	t := exportar.Tabla{
		Titulo:      "Reporte de ocupación de espacios",
		Columnas:    []string{primera, "Bloque", "Sede", "Espacios", "Sesiones", "Sesiones con asistencia", "Horas programadas", "Horas confirmadas", "% utilización"},
		Anchos:      []float64{2.6, 2, 2, 1, 1, 1.4, 1.3, 1.3, 1.2},
		GeneradoEn:  rep.GeneradoEn,
		GeneradoPor: generadoPor,
		Tipos: []exportar.TipoColumna{exportar.Texto, exportar.Texto, exportar.Texto, exportar.Entero, exportar.Entero,
			exportar.Entero, exportar.Decimal, exportar.Decimal, exportar.Porcentaje},
	}
	for _, f := range append(rep.Filas, rep.Totales) {
		t.Filas = append(t.Filas, []string{
			f.Nombre, f.Bloque, f.Sede, strconv.Itoa(f.Espacios), strconv.Itoa(f.Sesiones),
			strconv.Itoa(f.SesionesConfirmadas), horas(f.HorasProgramadas), horas(f.HorasConfirmadas),
			fmt.Sprintf("%.1f%%", f.PorcentajeUtilizacion),
		})
	}
	return t
}
