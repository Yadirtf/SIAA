// Package exportar genera los archivos XLSX y PDF de reportes y bitácora (RF-REP-004, RF-AUD-003).
package exportar

import (
	"github.com/siaa/backend/internal/domain/shared"

	"crypto/sha256"
	"encoding/hex"
	"strings"
	"time"
)

// Tabla es el contenido tabular a exportar con su encabezado institucional.
type Tabla struct {
	Titulo    string
	Metadatos [][2]string // pares etiqueta/valor: filtros, usuario, fecha de generación
	Columnas  []string
	Anchos    []float64 // ancho relativo por columna en el PDF; vacío = uniforme
	// Tipos indica cómo escribir cada columna en el XLSX (US-REP-02 AC-01); vacío = texto.
	// Las filas se conservan como texto para que el PDF y la huella no dependan del tipo.
	Tipos       []TipoColumna
	Filas       [][]string
	GeneradoEn  time.Time
	GeneradoPor string
}

// TipoColumna es el tipo de dato de una columna en la hoja de cálculo.
type TipoColumna int

const (
	Texto      TipoColumna = iota
	Entero                 // "12"
	Decimal                // "12.50", dos decimales
	Porcentaje             // "85.5%" o "85.5" → 0.855 con formato 0.0 %
	Fecha                  // "2026-10-01" → fecha de Excel
	FechaHora              // "2026-10-01 14:05" → fecha y hora de Excel
)

// tipo devuelve el tipo de la columna c (texto si no se declaró).
func (t Tabla) tipo(c int) TipoColumna {
	if c < len(t.Tipos) {
		return t.Tipos[c]
	}
	return Texto
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
		[2]string{"Generado", shared.FechaHoraLocal(t.GeneradoEn)},
		[2]string{"Generado por", t.GeneradoPor},
		[2]string{"Huella SHA-256", t.Huella()},
	)
	return meta
}
