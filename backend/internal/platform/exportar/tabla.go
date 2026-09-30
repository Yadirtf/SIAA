// Package exportar genera los archivos XLSX y PDF de reportes y bitácora (RF-REP-004, RF-AUD-003).
package exportar

import (
	"crypto/sha256"
	"encoding/hex"
	"strings"
	"time"
)

// Tabla es el contenido tabular a exportar con su encabezado institucional.
type Tabla struct {
	Titulo      string
	Metadatos   [][2]string // pares etiqueta/valor: filtros, usuario, fecha de generación
	Columnas    []string
	Anchos      []float64 // ancho relativo por columna en el PDF; vacío = uniforme
	Filas       [][]string
	GeneradoEn  time.Time
	GeneradoPor string
}

// Huella es el SHA-256 de columnas y filas; permite verificar que el archivo no se alteró.
func (t Tabla) Huella() string {
	h := sha256.New()
	h.Write([]byte(strings.Join(t.Columnas, "\x1f")))
	for _, f := range t.Filas {
		h.Write([]byte{'\x1e'})
		h.Write([]byte(strings.Join(f, "\x1f")))
	}
	return hex.EncodeToString(h.Sum(nil))
}

// encabezado devuelve los metadatos comunes a ambos formatos.
func (t Tabla) encabezado() [][2]string {
	meta := append([][2]string(nil), t.Metadatos...)
	meta = append(meta,
		[2]string{"Generado", t.GeneradoEn.In(zona()).Format("2006-01-02 15:04 MST")},
		[2]string{"Generado por", t.GeneradoPor},
		[2]string{"Huella SHA-256", t.Huella()},
	)
	return meta
}

func zona() *time.Location {
	if loc, err := time.LoadLocation("America/Bogota"); err == nil {
		return loc
	}
	return time.FixedZone("COT", -5*60*60)
}
