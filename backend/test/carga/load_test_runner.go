// Package main — Runner reproducible en Go para prueba de carga pico horario.
// Satisface US-PLT-05, AC-02, AC-03 y RNF-PER-001/003.
package main

import (
	"flag"
	"fmt"
	"net/http"
	"sort"
	"sync"
	"sync/atomic"
	"time"
)

func main() {
	targetURL := flag.String("url", "http://localhost:8080/api/v1/health", "URL objetivo")
	targetRPS := flag.Int("rps", 300, "Peticiones por segundo")
	durationSec := flag.Int("duration", 600, "Duración en segundos (default 600s = 10 min)")
	flag.Parse()

	fmt.Printf("=== INICIANDO PRUEBA DE CARGA PICO HORARIO (SIAA US-PLT-05) ===\n")
	fmt.Printf("Objetivo: %s | Tasa: %d req/s | Duración: %ds\n", *targetURL, *targetRPS, *durationSec)

	client := &http.Client{
		Timeout: 5 * time.Second,
		Transport: &http.Transport{
			MaxIdleConns:        500,
			MaxIdleConnsPerHost: 500,
			IdleConnTimeout:     90 * time.Second,
		},
	}

	var totalRequests uint64
	var totalErrors uint64
	var mu sync.Mutex
	latencies := make([]float64, 0, *targetRPS**durationSec)

	ticker := time.NewTicker(time.Second)
	defer ticker.Stop()

	stopTime := time.Now().Add(time.Duration(*durationSec) * time.Second)

	for time.Now().Before(stopTime) {
		<-ticker.C
		var wg sync.WaitGroup
		for i := 0; i < *targetRPS; i++ {
			wg.Add(1)
			go func() {
				defer wg.Done()
				start := time.Now()
				resp, err := client.Get(*targetURL)
				durMs := float64(time.Since(start).Microseconds()) / 1000.0

				atomic.AddUint64(&totalRequests, 1)

				isErr := err != nil || resp == nil || resp.StatusCode >= 400
				if resp != nil {
					resp.Body.Close()
				}

				if isErr {
					atomic.AddUint64(&totalErrors, 1)
				}

				mu.Lock()
				latencies = append(latencies, durMs)
				mu.Unlock()
			}()
		}
		wg.Wait()
	}

	sort.Float64s(latencies)
	total := len(latencies)
	if total == 0 {
		fmt.Println("No se registraron muestras.")
		return
	}

	p50 := latencies[int(float64(total)*0.50)]
	p95 := latencies[int(float64(total)*0.95)]
	p99 := latencies[int(float64(total)*0.99)]
	errorRate := (float64(totalErrors) / float64(totalRequests)) * 100.0

	fmt.Printf("\n=== RESULTADOS DE LA PRUEBA DE CARGA ===\n")
	fmt.Printf("Total peticiones: %d\n", totalRequests)
	fmt.Printf("Total errores:    %d\n", totalErrors)
	fmt.Printf("Tasa de error:    %.4f%% (Requerido: <= 0.10%%)\n", errorRate)
	fmt.Printf("Latencia p50:     %.2f ms\n", p50)
	fmt.Printf("Latencia p95:     %.2f ms (Requerido: <= 2000.00 ms)\n", p95)
	fmt.Printf("Latencia p99:     %.2f ms\n", p99)

	if p95 <= 2000 && errorRate <= 0.10 {
		fmt.Println("✅ PRUEBA APROBADA (Cumple RNF-PER-001 y RNF-PER-003)")
	} else {
		fmt.Println("❌ PRUEBA NO CUMPLE CRITERIOS DE ACEPTACIÓN")
	}
}
