// cmd/worker/main.go — proceso de tareas periódicas de SIAA (ADR-09).
// Genera las ausencias automáticas (US-MAR-07) por ventanas incrementales, separado del API
// para que su carga no compita con el pico de marcajes.
package main

import (
	"context"
	"fmt"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"

	"github.com/joho/godotenv"

	"github.com/siaa/backend/internal/app"
	"github.com/siaa/backend/internal/platform/config"
	applog "github.com/siaa/backend/internal/platform/log"
	mongoRepo "github.com/siaa/backend/internal/repository/mongo"
)

func main() {
	_ = godotenv.Load(".env", "../.env")
	cfg, err := config.Load()
	if err != nil {
		fmt.Fprintf(os.Stderr, "FATAL: %v\n", err)
		os.Exit(1)
	}
	log := applog.New(applog.LevelInfo, os.Stdout)

	ctx, cancel := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer cancel()

	conCtx, conCancel := context.WithTimeout(ctx, 15*time.Second)
	mongoClient, err := mongoRepo.Connect(conCtx, cfg.MongoURI, cfg.MongoDB)
	conCancel()
	if err != nil {
		log.Error("no se pudo conectar a MongoDB", applog.Err(err))
		os.Exit(1)
	}
	defer func() { _ = mongoClient.Disconnect(context.Background()) }()

	worker := app.NuevoAusenciasWorker(mongoClient)
	intervalo := time.Duration(minutosIntervalo()) * time.Minute
	log.Info("worker de ausencias iniciado", applog.Extra(map[string]string{"intervalo": intervalo.String()}))

	ticker := time.NewTicker(intervalo)
	defer ticker.Stop()
	for {
		cicloCtx, cicloCancel := context.WithTimeout(ctx, intervalo)
		n, err := worker.EjecutarCiclo(cicloCtx, time.Now().UTC())
		cicloCancel()
		if err != nil {
			log.Error("ciclo de ausencias fallido", applog.Err(err))
		} else if n > 0 {
			log.Info("ausencias generadas", applog.Extra(map[string]string{"cantidad": strconv.Itoa(n)}))
		}
		select {
		case <-ctx.Done():
			log.Info("worker detenido")
			return
		case <-ticker.C:
		}
	}
}

// minutosIntervalo lee WORKER_INTERVALO_MIN (5 por defecto).
func minutosIntervalo() int {
	if v, err := strconv.Atoi(os.Getenv("WORKER_INTERVALO_MIN")); err == nil && v > 0 {
		return v
	}
	return 5
}
