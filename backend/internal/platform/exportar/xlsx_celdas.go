package exportar

import (
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/xuri/excelize/v2"
)

// fechaISO reconoce los valores AAAA-MM-DD de los metadatos (rango consultado).
var fechaISO = regexp.MustCompile(`^\d{4}-\d{2}-\d{2}$`)

// estilos son los formatos numéricos de las celdas tipadas (US-REP-02 AC-01).
type estilos struct {
	entero, decimal, porcentaje, fecha, fechaHora int
}

func nuevosEstilos(f *excelize.File) (estilos, error) {
	var e estilos
	formatos := []struct {
		destino *int
		codigo  string
	}{
		{&e.entero, "0"},
		{&e.decimal, "0.00"},
		{&e.porcentaje, "0.0%"},
		{&e.fecha, "yyyy-mm-dd"},
		{&e.fechaHora, "yyyy-mm-dd hh:mm"},
	}
	for _, x := range formatos {
		codigo := x.codigo
		id, err := f.NewStyle(&excelize.Style{CustomNumFmt: &codigo})
		if err != nil {
			return e, err
		}
		*x.destino = id
	}
	return e, nil
}

// valorTipado convierte el texto de la celda al tipo de la columna y devuelve el estilo a
// aplicar. Si el texto no corresponde al tipo (p. ej. una celda vacía), queda como texto.
func (e estilos) valorTipado(tipo TipoColumna, v string) (interface{}, int) {
	v = strings.TrimSpace(v)
	if v == "" {
		return nil, 0
	}
	switch tipo {
	case Entero:
		if n, err := strconv.ParseInt(v, 10, 64); err == nil {
			return n, e.entero
		}
	case Decimal:
		if n, err := strconv.ParseFloat(v, 64); err == nil {
			return n, e.decimal
		}
	case Porcentaje:
		if n, err := strconv.ParseFloat(strings.TrimSuffix(v, "%"), 64); err == nil {
			return n / 100, e.porcentaje
		}
	case Fecha:
		if t, ok := comoFecha("2006-01-02", v); ok {
			return t, e.fecha
		}
	case FechaHora:
		for _, layout := range []string{"2006-01-02 15:04:05", "2006-01-02 15:04"} {
			if t, ok := comoFecha(layout, v); ok {
				return t, e.fechaHora
			}
		}
	}
	return v, 0
}

// comoFecha interpreta la hora de pared sin zona: Excel no guarda zona horaria y el valor
// mostrado debe ser el mismo que en pantalla (hora institucional).
func comoFecha(layout, v string) (time.Time, bool) {
	t, err := time.ParseInLocation(layout, v, time.UTC)
	return t, err == nil
}

// escribirCelda pone el valor tipado en la celda y su formato numérico.
func (e estilos) escribirCelda(f *excelize.File, celda string, tipo TipoColumna, v string) {
	valor, estilo := e.valorTipado(tipo, v)
	if valor == nil {
		return
	}
	_ = f.SetCellValue(hoja, celda, valor)
	if estilo != 0 {
		_ = f.SetCellStyle(hoja, celda, celda, estilo)
	}
}

// tipoMetadato escribe como fecha los valores AAAA-MM-DD del encabezado (desde/hasta).
func tipoMetadato(v string) TipoColumna {
	if fechaISO.MatchString(strings.TrimSpace(v)) {
		return Fecha
	}
	return Texto
}
