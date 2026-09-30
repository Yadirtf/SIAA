// Package app — composición de la aplicación: repositorios, casos de uso, handlers y router.
// Se usa desde cmd/api y desde las pruebas de integración, para que ambos ejecuten
// exactamente el mismo cableado contra MongoDB real.
package app

import (
	"context"
	"fmt"

	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/platform/clock"
	"github.com/siaa/backend/internal/platform/config"
	applog "github.com/siaa/backend/internal/platform/log"
	"github.com/siaa/backend/internal/platform/mailer"
	"github.com/siaa/backend/internal/platform/security"
	mongoRepo "github.com/siaa/backend/internal/repository/mongo"
	"github.com/siaa/backend/internal/repository/mongo/impl"
	apphttp "github.com/siaa/backend/internal/transport/http"
	"github.com/siaa/backend/internal/transport/http/handler"
	usecaseAca "github.com/siaa/backend/internal/usecase/academico"
	usecaseAud "github.com/siaa/backend/internal/usecase/auditoria"
	"github.com/siaa/backend/internal/usecase/auth"
	usecaseGeo "github.com/siaa/backend/internal/usecase/geo"
	usecaseJus "github.com/siaa/backend/internal/usecase/justificaciones"
	usecaseMarcaje "github.com/siaa/backend/internal/usecase/marcaje"
	usecasePar "github.com/siaa/backend/internal/usecase/parametro"
	usecaseRbac "github.com/siaa/backend/internal/usecase/rbac"
	usecaseRep "github.com/siaa/backend/internal/usecase/reportes"
	usecaseUsuarios "github.com/siaa/backend/internal/usecase/usuarios"
)

// App agrupa lo que el proceso necesita para servir: el router HTTP y el worker de ausencias.
type App struct {
	Router          *echo.Echo
	AusenciasWorker *usecaseMarcaje.AusenciasWorker
}

// Construir conecta todas las capas sobre un cliente MongoDB ya conectado y migrado.
// openapiPath es la ruta del contrato servido en /openapi.json.
func Construir(cfg *config.Config, log *applog.Logger, mongoClient *mongoRepo.Client, openapiPath string) (*App, error) {
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
	// Con SMTP_HOST definido se envían correos reales (MailHog en desarrollo); si no, solo se registran.
	noop := mailer.NewNoopMailer(log)
	var appMailer auth.Mailer = noop
	var correo usecaseJus.Correo = noop
	if cfg.SMTPHost != "" {
		smtpMailer := mailer.NewSMTPMailer(mailer.SMTPConfig{
			Host:     cfg.SMTPHost,
			Port:     cfg.SMTPPort,
			User:     cfg.SMTPUser,
			Pass:     cfg.SMTPPass,
			From:     cfg.SMTPFrom,
			LinkBase: cfg.RecoveryURL,
			Minutos:  cfg.RecoveryTokenMinutes,
		})
		appMailer, correo = smtpMailer, smtpMailer
	}

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

	// Gestión de usuarios: sin contraseña inicial se invita por correo; al desactivar se cierran sesiones.
	usuariosSvc := usecaseUsuarios.NewService(usuarioRepo, rolRepo, auditoriaRepo, clk, cfg.PasswordMinLength).
		WithInvitador(authSvc).
		WithRevocador(authSvc)

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
	// RN-002: las sesiones se generan con los parámetros efectivos de la cascada jerárquica.
	acaSvc.WithResolutorParametros(func(ctx context.Context, a usecaseAca.AmbitoParametros) (map[string]interface{}, error) {
		snap, err := parametroSvc.ResolverEfectivos(ctx, usecasePar.EspecCascada{
			SedeID:       a.SedeID,
			FacultadID:   a.FacultadID,
			BloqueID:     a.BloqueID,
			EspacioID:    a.EspacioID,
			AsignacionID: a.AsignacionID,
		})
		if err != nil {
			return nil, err
		}
		valores := make(map[string]interface{}, len(snap))
		for clave, efectivo := range snap {
			valores[string(clave)] = efectivo.Origen.Valor
		}
		return valores, nil
	})

	// ─── Motor de Marcaje (EP-06) ─────────────────────────────
	marcajeRepo := impl.NewMarcajeMongoRepository(mongoClient.DB())
	crearMarcajeUC := usecaseMarcaje.NewCrearMarcajeUseCase(marcajeRepo, sesionRepo, espacioRepo, dispositivoRepo, auditoriaRepo, nil).
		WithAsignaciones(asignacionRepo)
	if v := verificadorAttestation(cfg, log); v != nil {
		crearMarcajeUC.WithAttestation(v)
	}
	activaUC := usecaseMarcaje.NewSesionActivaUseCase(sesionRepo, espacioRepo, marcajeRepo).
		WithAsignaciones(asignacionRepo).
		WithEstructura(estructuraRepo)
	historialUC := usecaseMarcaje.NewHistorialUseCase(marcajeRepo)
	ajustarUC := usecaseMarcaje.NewAjustarMarcajeUseCase(marcajeRepo, sesionRepo, auditoriaRepo)
	syncUC := usecaseMarcaje.NewSyncOfflineUseCase(crearMarcajeUC, marcajeRepo)
	ventanaEstudiantilUC := usecaseMarcaje.NewVentanaEstudiantilUseCase(sesionRepo, marcajeRepo)
	listaManualUC := usecaseMarcaje.NewListaManualUseCase(sesionRepo, marcajeRepo, auditoriaRepo)
	ausenciasWorker := NuevoAusenciasWorker(mongoClient)

	// ─── Justificaciones, reportes y bitácora (EP-07, EP-08, RF-AUD-003) ───
	claveAdjuntos := cfg.AdjuntosClave
	if claveAdjuntos == "" {
		claveAdjuntos = cfg.JWTSecret
	}
	cifrador, err := security.NuevoCifrador(claveAdjuntos)
	if err != nil {
		return nil, fmt.Errorf("cifrado de soportes: %w", err)
	}
	justificacionRepo := impl.NewJustificacionRepository(mongoClient)
	justificacionesSvc := usecaseJus.NewService(justificacionRepo, impl.NewAdjuntoRepository(mongoClient, cifrador),
		sesionRepo, marcajeRepo, usuarioRepo, auditoriaRepo, clk).
		WithCorreo(correo).
		WithPlazoDias(cfg.JustificacionPlazoDias)
	reportesSvc := usecaseRep.NewService(sesionRepo, marcajeRepo, justificacionRepo, estructuraRepo, usuarioRepo, auditoriaRepo, clk).
		WithPeriodos(periodoRepo)
	auditoriaSvc := usecaseAud.NewService(impl.NewAuditoriaConsultaRepository(mongoClient), auditoriaRepo, usuarioRepo, clk)

	// ─── Handlers ─────────────────────────────────────────────
	healthH := handler.NewHealthHandler(mongoClient, cfg.Version, cfg.Commit)
	authH := handler.NewAuthHandler(authSvc)
	openapiH := handler.NewOpenAPIHandler(openapiPath)
	rolesH := handler.NewRolesHandler(rbacSvc)
	geoH := handler.NewGeoHandler(geoSvc)
	acaH := handler.NewAcademicoHandler(acaSvc)
	parametroH := handler.NewParametroHandler(parametroSvc)
	marcajeH := handler.NewMarcajeHandler(crearMarcajeUC, activaUC, historialUC)
	marcajeAdminH := handler.NewMarcajeAdminHandler(ajustarUC, ventanaEstudiantilUC, listaManualUC)
	marcajeSyncH := handler.NewMarcajeSyncHandler(syncUC)
	usuariosH := handler.NewUsuariosHandler(usuariosSvc)
	seguimiento := &apphttp.HandlersSeguimiento{
		Justificaciones: handler.NewJustificacionesHandler(justificacionesSvc),
		Reportes:        handler.NewReportesHandler(reportesSvc),
		Auditoria:       handler.NewAuditoriaHandler(auditoriaSvc),
	}

	// ─── Router con verificación de seguridad al arranque (T-ROL-01.4) ───
	router, err := apphttp.NewRouter(cfg, log, healthH, authH, openapiH, rolesH, geoH, acaH, parametroH, marcajeH, marcajeAdminH, marcajeSyncH, usuariosH, seguimiento, auditoriaRepo, nil)
	if err != nil {
		return nil, fmt.Errorf("inicializar rutas: %w", err)
	}

	return &App{Router: router, AusenciasWorker: ausenciasWorker}, nil
}

// NuevoAusenciasWorker arma el worker de ausencias con su marca de agua (ADR-09). Lo usa el
// proceso cmd/worker, que corre aparte del API.
func NuevoAusenciasWorker(mongoClient *mongoRepo.Client) *usecaseMarcaje.AusenciasWorker {
	return usecaseMarcaje.NewAusenciasWorker(
		impl.NewMarcajeMongoRepository(mongoClient.DB()),
		impl.NewSesionRepository(mongoClient),
	).WithMarcaDeAgua(impl.NewProcesoRepository(mongoClient))
}
