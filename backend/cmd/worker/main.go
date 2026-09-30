// cmd/worker/main.go — proceso de tareas periódicas de SIAA (ADR-09).
// Genera las ausencias automáticas (US-MAR-07), programa y despacha los avisos (EP-10) y
// anonimiza las coordenadas vencidas (Ley 1581), separado del API para que su carga no
// compita con el pico de marcajes.
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

// cadaRetencion espacia la anonimización: basta con aplicarla unas veces al día.
const cadaRetencion = time.Hour

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

	notificaciones, err := app.NuevoWorkersNotificaciones(cfg, log, mongoClient)
	if err != nil {
		log.Error("configuración de notificaciones inválida", applog.Err(err))
		os.Exit(1)
	}
	tareas := []tarea{
		{nombre: "ausencias", ejecutar: app.NuevoAusenciasWorker(mongoClient).EjecutarCiclo},
		{nombre: "programación de avisos", ejecutar: notificaciones.Programador.EjecutarCiclo},
		{nombre: "envío de avisos", ejecutar: notificaciones.Despachador.EjecutarCiclo},
		{nombre: "anonimización de coordenadas", cada: cadaRetencion, ejecutar: retencion(app.NuevoRetencionWorker(mongoClient).EjecutarCiclo)},
	}

	intervalo := time.Duration(minutosIntervalo()) * time.Minute
	log.Info("worker iniciado", applog.Extra(map[string]string{"intervalo": intervalo.String()}))
	ticker := time.NewTicker(intervalo)
	defer ticker.Stop()
	for {
		ahora := time.Now().UTC()
		for i := range tareas {
			tareas[i].correr(ctx, log, intervalo, ahora)
		}
		select {
		case <-ctx.Done():
			log.Info("worker detenido")
			return
		case <-ticker.C:
		}
	}
}

// tarea es un proceso periódico; `cada` (opcional) lo espacia más que el intervalo del worker.
type tarea struct {
	nombre   string
	cada     time.Duration
	ultima   time.Time
	ejecutar func(ctx context.Context, ahora time.Time) (int, error)
}

func (t *tarea) correr(ctx context.Context, log *applog.Logger, limite time.Duration, ahora time.Time) {
	if t.cada > 0 && !t.ultima.IsZero() && ahora.Sub(t.ultima) < t.cada {
		return
	}
	cicloCtx, cicloCancel := context.WithTimeout(ctx, limite)
	defer cicloCancel()
	n, err := t.ejecutar(cicloCtx, ahora)
	if err != nil {
		log.Error("ciclo fallido: "+t.nombre, applog.Err(err))
		return
	}
	t.ultima = ahora
	if n > 0 {
		log.Info(t.nombre, applog.Extra(map[string]string{"cantidad": strconv.Itoa(n)}))
	}
}

// retencion adapta el contador int64 del worker de retención.
func retencion(f func(context.Context, time.Time) (int64, error)) func(context.Context, time.Time) (int, error) {
	return func(ctx context.Context, ahora time.Time) (int, error) {
		n, err := f(ctx, ahora)
		return int(n), err
	}
}

// minutosIntervalo lee WORKER_INTERVALO_MIN (1 por defecto: el aviso de cierre de ventana
// sale pocos minutos antes y no admite más retraso).
func minutosIntervalo() int {
	if v, err := strconv.Atoi(os.Getenv("WORKER_INTERVALO_MIN")); err == nil && v > 0 {
		return v
	}
	return 1
}
