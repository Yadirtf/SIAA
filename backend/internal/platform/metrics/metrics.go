// Package metrics — Colector en memoria de métricas y observabilidad para SIAA.
// Satisface US-PLT-05, AC-01 y RNF-PER-003.
package metrics

import (
	"sort"
	"sync"
	"sync/atomic"
	"time"
)

// LatencyPercentiles representa los percentiles de latencia en milisegundos.
type LatencyPercentiles struct {
	P50Ms float64 `json:"p50Ms"`
	P95Ms float64 `json:"p95Ms"`
	P99Ms float64 `json:"p99Ms"`
}

// RouteMetrics almacena contadores y muestras de latencia para una ruta HTTP.
type RouteMetrics struct {
	TotalRequests uint64             `json:"totalRequests"`
	TotalErrors   uint64             `json:"totalErrors"`
	Latencia      LatencyPercentiles `json:"latencia"`
}

// DatabaseMetrics expone el estado del pool de conexiones a MongoDB.
type DatabaseMetrics struct {
	ConexionesActivas    uint64  `json:"conexionesActivas"`
	ConexionesInactivas  uint64  `json:"conexionesInactivas"`
	SaturacionPorcentaje float64 `json:"saturacionPorcentaje"`
}

// MetricsReport representa el informe global de métricas del sistema.
type MetricsReport struct {
	Timestamp         time.Time               `json:"timestamp"`
	UptimeSegundos    int64                   `json:"uptimeSegundos"`
	SolicitudesTotal  uint64                  `json:"solicitudesTotal"`
	ErroresTotal      uint64                  `json:"erroresTotal"`
	TasaError         float64                 `json:"tasaError"`
	Rutas             map[string]RouteMetrics `json:"rutas"`
	BaseDatos         DatabaseMetrics         `json:"baseDatos"`
	ResultadosMarcaje map[string]uint64       `json:"resultadosMarcaje"`
}

// Collector gestiona la recolección concurrente y cálculo de percentiles.
type Collector struct {
	startTime time.Time

	solicitudesTotal uint64
	erroresTotal     uint64

	mu      sync.RWMutex
	routes  map[string]*routeData
	marcaje map[string]uint64

	dbActivas   uint64
	dbInactivas uint64
}

type routeData struct {
	requests uint64
	errors   uint64
	samples  []float64
}

// NewCollector inicializa un nuevo recolector de métricas.
func NewCollector() *Collector {
	return &Collector{
		startTime: time.Now(),
		routes:    make(map[string]*routeData),
		marcaje:   make(map[string]uint64),
	}
}

// RecordRequest registra una petición HTTP procesada con su duración y estado.
func (c *Collector) RecordRequest(route string, duration time.Duration, isError bool) {
	atomic.AddUint64(&c.solicitudesTotal, 1)
	if isError {
		atomic.AddUint64(&c.erroresTotal, 1)
	}

	durationMs := float64(duration.Microseconds()) / 1000.0

	c.mu.Lock()
	defer c.mu.Unlock()

	rd, ok := c.routes[route]
	if !ok {
		rd = &routeData{samples: make([]float64, 0, 1000)}
		c.routes[route] = rd
	}

	rd.requests++
	if isError {
		rd.errors++
	}

	// Mantener buffer circular de hasta 5000 muestras para calcular percentiles sin agotar memoria
	if len(rd.samples) >= 5000 {
		rd.samples = rd.samples[1:]
	}
	rd.samples = append(rd.samples, durationMs)
}

// RecordMarcajeResultado incrementa el contador de resultado de marcaje.
func (c *Collector) RecordMarcajeResultado(resultado string) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.marcaje[resultado]++
}

// SetDBStats actualiza las métricas del pool de base de datos.
func (c *Collector) SetDBStats(activas, inactivas uint64) {
	atomic.StoreUint64(&c.dbActivas, activas)
	atomic.StoreUint64(&c.dbInactivas, inactivas)
}

// GetReport calcula y retorna el reporte consolidado de observabilidad.
func (c *Collector) GetReport() MetricsReport {
	c.mu.RLock()
	defer c.mu.RUnlock()

	totalReq := atomic.LoadUint64(&c.solicitudesTotal)
	totalErr := atomic.LoadUint64(&c.erroresTotal)

	var tasaError float64
	if totalReq > 0 {
		tasaError = float64(totalErr) / float64(totalReq)
	}

	rutasMap := make(map[string]RouteMetrics, len(c.routes))
	for route, rd := range c.routes {
		rutasMap[route] = RouteMetrics{
			TotalRequests: rd.requests,
			TotalErrors:   rd.errors,
			Latencia:      calculatePercentiles(rd.samples),
		}
	}

	marcajeMap := make(map[string]uint64, len(c.marcaje))
	for k, v := range c.marcaje {
		marcajeMap[k] = v
	}

	activas := atomic.LoadUint64(&c.dbActivas)
	inactivas := atomic.LoadUint64(&c.dbInactivas)
	totalConns := activas + inactivas

	var satDB float64
	if totalConns > 0 {
		satDB = (float64(activas) / float64(totalConns)) * 100.0
	}

	return MetricsReport{
		Timestamp:        time.Now(),
		UptimeSegundos:   int64(time.Since(c.startTime).Seconds()),
		SolicitudesTotal: totalReq,
		ErroresTotal:     totalErr,
		TasaError:        tasaError,
		Rutas:            rutasMap,
		BaseDatos: DatabaseMetrics{
			ConexionesActivas:    activas,
			ConexionesInactivas:  inactivas,
			SaturacionPorcentaje: satDB,
		},
		ResultadosMarcaje: marcajeMap,
	}
}

func calculatePercentiles(samples []float64) LatencyPercentiles {
	n := len(samples)
	if n == 0 {
		return LatencyPercentiles{}
	}

	sorted := make([]float64, n)
	copy(sorted, samples)
	sort.Float64s(sorted)

	return LatencyPercentiles{
		P50Ms: getPercentile(sorted, 0.50),
		P95Ms: getPercentile(sorted, 0.95),
		P99Ms: getPercentile(sorted, 0.99),
	}
}

func getPercentile(sorted []float64, p float64) float64 {
	n := len(sorted)
	if n == 0 {
		return 0
	}
	index := int(float64(n-1) * p)
	if index < 0 {
		index = 0
	}
	if index >= n {
		index = n - 1
	}
	return sorted[index]
}
