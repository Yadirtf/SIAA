// Package metrics — métricas de la base de datos: pool de conexiones y comandos a MongoDB.
// US-PLT-05 AC-01: saturación de conexiones; el driver alimenta estos contadores mediante
// sus monitores de pool y de comandos (repository/mongo/monitor.go).
package metrics

import (
	"sync"
	"sync/atomic"
	"time"
)

// DatabaseMetrics expone el estado del pool de conexiones y la latencia de los comandos.
type DatabaseMetrics struct {
	ConexionesActivas    uint64             `json:"conexionesActivas"`
	ConexionesInactivas  uint64             `json:"conexionesInactivas"`
	ConexionesMaximas    uint64             `json:"conexionesMaximas"`
	SaturacionPorcentaje float64            `json:"saturacionPorcentaje"`
	ComandosTotal        uint64             `json:"comandosTotal"`
	ComandosFallidos     uint64             `json:"comandosFallidos"`
	LatenciaComandos     LatencyPercentiles `json:"latenciaComandos"`
	Comandos             map[string]uint64  `json:"comandos"`
}

// maxMuestrasDB limita el búfer de latencias de comandos.
const maxMuestrasDB = 5000

// dbCollector acumula el estado del pool (conexiones abiertas y prestadas) y los comandos.
type dbCollector struct {
	abiertas  int64 // conexiones físicas abiertas en el pool
	prestadas int64 // conexiones entregadas a una operación en curso
	maximas   uint64

	comandos uint64
	fallidos uint64

	mu        sync.Mutex
	porNombre map[string]uint64
	muestras  []float64
}

// SetDBStats fija directamente activas e inactivas (pruebas o fuentes externas).
func (c *Collector) SetDBStats(activas, inactivas uint64) {
	atomic.StoreInt64(&c.baseDatos.prestadas, int64(activas))
	atomic.StoreInt64(&c.baseDatos.abiertas, int64(activas+inactivas))
}

// SetDBPoolMaximo registra el tamaño máximo del pool: con él la saturación es prestadas/máximo.
func (c *Collector) SetDBPoolMaximo(maximo uint64) {
	atomic.StoreUint64(&c.baseDatos.maximas, maximo)
}

// ConexionDBAbierta / ConexionDBCerrada siguen el número de conexiones físicas del pool.
func (c *Collector) ConexionDBAbierta() { atomic.AddInt64(&c.baseDatos.abiertas, 1) }

// ConexionDBCerrada descuenta una conexión física del pool.
func (c *Collector) ConexionDBCerrada() { atomic.AddInt64(&c.baseDatos.abiertas, -1) }

// ConexionDBPrestada marca una conexión en uso por una operación.
func (c *Collector) ConexionDBPrestada() { atomic.AddInt64(&c.baseDatos.prestadas, 1) }

// ConexionDBDevuelta marca una conexión que volvió al pool.
func (c *Collector) ConexionDBDevuelta() { atomic.AddInt64(&c.baseDatos.prestadas, -1) }

// RecordComandoDB registra un comando terminado con su duración y si falló.
func (c *Collector) RecordComandoDB(nombre string, duracion time.Duration, fallido bool) {
	d := &c.baseDatos
	atomic.AddUint64(&d.comandos, 1)
	if fallido {
		atomic.AddUint64(&d.fallidos, 1)
	}
	d.mu.Lock()
	defer d.mu.Unlock()
	if d.porNombre == nil {
		d.porNombre = make(map[string]uint64)
	}
	d.porNombre[nombre]++
	if len(d.muestras) >= maxMuestrasDB {
		d.muestras = d.muestras[1:]
	}
	d.muestras = append(d.muestras, float64(duracion.Microseconds())/1000.0)
}

// reporte consolida el estado actual del pool y de los comandos.
func (d *dbCollector) reporte() DatabaseMetrics {
	prestadas := noNegativo(atomic.LoadInt64(&d.prestadas))
	abiertas := noNegativo(atomic.LoadInt64(&d.abiertas))
	if abiertas < prestadas {
		abiertas = prestadas
	}
	maximas := atomic.LoadUint64(&d.maximas)

	// Con tamaño máximo conocido la saturación es sobre el pool completo; si no, sobre las abiertas.
	var saturacion float64
	switch {
	case maximas > 0:
		saturacion = float64(prestadas) / float64(maximas) * 100.0
	case abiertas > 0:
		saturacion = float64(prestadas) / float64(abiertas) * 100.0
	}

	d.mu.Lock()
	defer d.mu.Unlock()
	nombres := make(map[string]uint64, len(d.porNombre))
	for k, v := range d.porNombre {
		nombres[k] = v
	}
	return DatabaseMetrics{
		ConexionesActivas:    prestadas,
		ConexionesInactivas:  abiertas - prestadas,
		ConexionesMaximas:    maximas,
		SaturacionPorcentaje: saturacion,
		ComandosTotal:        atomic.LoadUint64(&d.comandos),
		ComandosFallidos:     atomic.LoadUint64(&d.fallidos),
		LatenciaComandos:     calculatePercentiles(d.muestras),
		Comandos:             nombres,
	}
}

func noNegativo(v int64) uint64 {
	if v < 0 {
		return 0
	}
	return uint64(v)
}
