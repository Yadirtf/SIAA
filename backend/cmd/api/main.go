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

	"github.com/siaa/backend/internal/platform/clock"
	"github.com/siaa/backend/internal/platform/config"
	applog "github.com/siaa/backend/internal/platform/log"
	"github.com/siaa/backend/internal/platform/mailer"
	mongoRepo "github.com/siaa/backend/internal/repository/mongo"
	"github.com/siaa/backend/internal/repository/mongo/impl"
	"github.com/siaa/backend/internal/repository/mongo/migrations"
	apphttp "github.com/siaa/backend/internal/transport/http"
	"github.com/siaa/backend/internal/transport/http/handler"
	usecaseAca "github.com/siaa/backend/internal/usecase/academico"
	"github.com/siaa/backend/internal/usecase/auth"
	usecaseGeo "github.com/siaa/backend/internal/usecase/geo"
	usecaseMarcaje "github.com/siaa/backend/internal/usecase/marcaje"
	usecasePar "github.com/siaa/backend/internal/usecase/parametro"
	usecaseRbac "github.com/siaa/backend/internal/usecase/rbac"
)

func main() {
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
	if err := migrations.Run(ctx, mongoClient.DB()); err != nil {
		log.Error("migraciones fallidas", applog.Err(err))
		os.Exit(1)
	}
	log.Info("migraciones ejecutadas")

	// ─── Repositorios ─────────────────────────────────────────
	clk := clock.RealClock{}
	usuarioRepo := impl.NewUsuarioRepository(mongoClient)
	refreshRepo := impl.NewRefreshTokenRepository(mongoClient)
	recoveryRepo := impl.NewRecoveryTokenRepository(mongoClient)
	auditoriaRepo := impl.NewAuditoriaRepository(mongoClient)
	sedeRepo := impl.NewSedeRepository(mongoClient)
	bloqueRepo := impl.NewBloqueRepository(mongoClient)
	espacioRepo := impl.NewEspacioRepository(mongoClient)
	histRepo := impl.NewEspacioGeometriaHistRepository(mongoClient)
	sesionChecker := impl.NewSesionFutureChecker(mongoClient)

	// Académico (EP-04)
	periodoRepo := impl.NewPeriodoRepository(mongoClient)
	estructuraRepo := impl.NewEstructuraRepository(mongoClient)
	asignacionRepo := impl.NewAsignacionRepository(mongoClient)
	excepcionRepo := impl.NewCalendarioExcepcionRepository(mongoClient)
	sesionRepo := impl.NewSesionRepository(mongoClient)

	rolRepo := impl.NewRolRepository(mongoClient)

	// Parametrización jerárquica (EP-05)
	parametroRepo := impl.NewParametroRepo(mongoClient.DB())

	// ─── Infraestructura ──────────────────────────────────────
	// En producción se inyecta la implementación SMTP en lugar del noop.
	appMailer := mailer.NewNoopMailer(log)

	dispositivoRepo := impl.NewDispositivoRepository(mongoClient)

	// ─── Casos de uso ─────────────────────────────────────────
	rbacSvc := usecaseRbac.NewService(rolRepo, auditoriaRepo, clk)

	authSvc := auth.NewService(
		usuarioRepo,
		refreshRepo,
		recoveryRepo,
		auditoriaRepo,
		clk,
		cfg,
		appMailer,
	).WithDispositivos(dispositivoRepo)

	geoSvc := usecaseGeo.NewService(
		sedeRepo,
		bloqueRepo,
		espacioRepo,
		histRepo,
		sesionChecker,
		auditoriaRepo,
		clk,
		log,
	)

	acaSvc := usecaseAca.NewService(
		periodoRepo,
		estructuraRepo,
		asignacionRepo,
		excepcionRepo,
		usuarioRepo,
		espacioRepo,
		auditoriaRepo,
		clk,
		log,
	).WithSesiones(sesionRepo)

	parametroSvc := usecasePar.New(parametroRepo)

	// ─── Motor de Marcaje (EP-06) ─────────────────────────────
	marcajeRepo := impl.NewMarcajeMongoRepository(mongoClient.DB())
	crearMarcajeUC := usecaseMarcaje.NewCrearMarcajeUseCase(marcajeRepo, sesionRepo, espacioRepo, dispositivoRepo, auditoriaRepo, nil)
	activaUC := usecaseMarcaje.NewSesionActivaUseCase(sesionRepo, espacioRepo, marcajeRepo)
	historialUC := usecaseMarcaje.NewHistorialUseCase(marcajeRepo)
	ajustarUC := usecaseMarcaje.NewAjustarMarcajeUseCase(marcajeRepo, sesionRepo, auditoriaRepo)
	syncUC := usecaseMarcaje.NewSyncOfflineUseCase(crearMarcajeUC, marcajeRepo)
	ventanaEstudiantilUC := usecaseMarcaje.NewVentanaEstudiantilUseCase(sesionRepo, marcajeRepo)
	listaManualUC := usecaseMarcaje.NewListaManualUseCase(sesionRepo, marcajeRepo, auditoriaRepo)
	ausenciasWorker := usecaseMarcaje.NewAusenciasWorker(marcajeRepo, sesionRepo)

	// Worker periódico de ausencias automáticas (US-MAR-07, cada 15 min)
	go func() {
		ticker := time.NewTicker(15 * time.Minute)
		defer ticker.Stop()
		for range ticker.C {
			_, _ = ausenciasWorker.EjecutarCiclo(context.Background(), time.Now().UTC())
		}
	}()

	// ─── Handlers ─────────────────────────────────────────────
	healthH := handler.NewHealthHandler(mongoClient, cfg.Version, cfg.Commit)
	authH := handler.NewAuthHandler(authSvc)
	openapiH := handler.NewOpenAPIHandler("../contracts/openapi.json")
	rolesH := handler.NewRolesHandler(rbacSvc)
	geoH := handler.NewGeoHandler(geoSvc)
	acaH := handler.NewAcademicoHandler(acaSvc)
	parametroH := handler.NewParametroHandler(parametroSvc)
	marcajeH := handler.NewMarcajeHandler(crearMarcajeUC, activaUC, historialUC)
	marcajeAdminH := handler.NewMarcajeAdminHandler(ajustarUC, ventanaEstudiantilUC, listaManualUC)
	marcajeSyncH := handler.NewMarcajeSyncHandler(syncUC)

	// ─── Router con verificación de seguridad al arranque (T-ROL-01.4) ───
	router, err := apphttp.NewRouter(cfg, log, healthH, authH, openapiH, rolesH, geoH, acaH, parametroH, marcajeH, marcajeAdminH, marcajeSyncH, auditoriaRepo, nil)
	if err != nil {
		log.Error("fallo de seguridad al inicializar rutas del servidor", applog.Err(err))
		os.Exit(1)
	}

	// ─── Servidor HTTP ────────────────────────────────────────
	srv := &http.Server{
		Addr:         ":" + cfg.Port,
		Handler:      router,
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
