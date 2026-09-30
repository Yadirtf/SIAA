// cmd/api/main.go — Punto de entrada del servidor API de SIAA.
// T-PLT-01.1: arranque y apagado ordenado con drenaje de 15 s.
// T-PLT-01.2: el servicio NO arranca si falta una variable obligatoria.
package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/joho/godotenv"

	"github.com/siaa/backend/internal/app"
	"github.com/siaa/backend/internal/platform/config"
	applog "github.com/siaa/backend/internal/platform/log"
	mongoRepo "github.com/siaa/backend/internal/repository/mongo"
	"github.com/siaa/backend/internal/repository/mongo/migrations"
	"github.com/siaa/backend/internal/repository/mongo/seed"
)

func main() {
	// Sonda de salud para el HEALTHCHECK del contenedor (imagen scratch sin curl):
	// consulta /health del proceso que ya está corriendo y sale con 0 o 1.
	if len(os.Args) > 1 && os.Args[1] == "--health-check" {
		os.Exit(sondaSalud())
	}

	// Cargar .env en entornos de desarrollo (ignorar error si no existe)
	_ = godotenv.Load(".env", "../.env")

	// ─── Configuración ───────────────────────────────────────
	cfg, err := config.Load()
	if err != nil {
		fmt.Fprintf(os.Stderr, "FATAL: %v\n", err)
		os.Exit(1)
	}

	// ─── Logger ──────────────────────────────────────────────
	logLevel := applog.LevelInfo
	if cfg.Env == "development" {
		logLevel = applog.LevelDebug
	}
	log := applog.New(logLevel, os.Stdout)
	log.Info("iniciando SIAA API",
		applog.Extra(map[string]string{
			"version": cfg.Version,
			"commit":  cfg.Commit,
			"env":     cfg.Env,
		}),
	)

	// ─── MongoDB ─────────────────────────────────────────────
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	mongoClient, err := mongoRepo.Connect(ctx, cfg.MongoURI, cfg.MongoDB)
	if err != nil {
		log.Error("no se pudo conectar a MongoDB", applog.Err(err))
		os.Exit(1)
	}
	log.Info("MongoDB conectado")

	// Ejecutar migraciones (índices + semillas) — idempotente
	if err := migrations.Run(ctx, mongoClient.DB(), cfg.Env != "production", seed.AdminInicial{
		Correo:   cfg.AdminInicialCorreo,
		Password: cfg.AdminInicialPassword,
	}); err != nil {
		log.Error("migraciones fallidas", applog.Err(err))
		os.Exit(1)
	}
	log.Info("migraciones ejecutadas")

	openapiPath := os.Getenv("OPENAPI_SPEC_PATH")
	if openapiPath == "" {
		openapiPath = "../contracts/openapi.json"
	}
	aplicacion, err := app.Construir(cfg, log, mongoClient, openapiPath)
	if err != nil {
		log.Error("fallo de seguridad al inicializar rutas del servidor", applog.Err(err))
		os.Exit(1)
	}

	// Las ausencias automáticas las genera el proceso cmd/worker (ADR-09), no el API.

	// ─── Servidor HTTP ────────────────────────────────────────
	srv := &http.Server{
		Addr:         ":" + cfg.Port,
		Handler:      aplicacion.Router,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 30 * time.Second,
		IdleTimeout:  120 * time.Second,
	}

	// Arrancar en goroutine para poder capturar señales
	serverErr := make(chan error, 1)
	go func() {
		log.Info(fmt.Sprintf("servidor escuchando en :%s", cfg.Port))
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			serverErr <- err
		}
	}()

	// ─── Apagado ordenado ─────────────────────────────────────
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)

	select {
	case sig := <-quit:
		log.Info(fmt.Sprintf("señal recibida: %s — apagando servidor", sig))
	case err := <-serverErr:
		log.Error("error del servidor", applog.Err(err))
		os.Exit(1)
	}

	// Drenaje de 15 segundos (T-PLT-01.1)
	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer shutdownCancel()

	if err := srv.Shutdown(shutdownCtx); err != nil {
		log.Error("apagado forzado", applog.Err(err))
	}

	if err := mongoClient.Disconnect(context.Background()); err != nil {
		log.Error("error desconectando MongoDB", applog.Err(err))
	}

	log.Info("servidor detenido correctamente")
}

// sondaSalud consulta GET /api/v1/health en el puerto local del servicio.
func sondaSalud() int {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	client := &http.Client{Timeout: 3 * time.Second}
	resp, err := client.Get("http://127.0.0.1:" + port + "/api/v1/health")
	if err != nil {
		return 1
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return 1
	}
	return 0
}
