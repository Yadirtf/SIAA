package app

import (
	"context"

	"github.com/siaa/backend/internal/domain/notificacion"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/platform/config"
	"github.com/siaa/backend/internal/platform/fcm"
	applog "github.com/siaa/backend/internal/platform/log"
	"github.com/siaa/backend/internal/platform/mailer"
	mongoRepo "github.com/siaa/backend/internal/repository/mongo"
	"github.com/siaa/backend/internal/repository/mongo/impl"
	usecaseNot "github.com/siaa/backend/internal/usecase/notificaciones"
	usecasePriv "github.com/siaa/backend/internal/usecase/privacidad"
)

// WorkersNotificaciones agrupa las dos etapas del envío de avisos (EP-10): el programador
// encola recordatorios y cierres de ventana; el despachador vacía la cola.
type WorkersNotificaciones struct {
	Programador *usecaseNot.Programador
	Despachador *usecaseNot.Despachador
	// Revision recuerda las justificaciones sin resolver (US-JUS-04 AC-02).
	Revision *usecaseNot.RecordatorioRevision
	// VencimientoRoles avisa los roles por vencer (US-ROL-05 AC-02).
	VencimientoRoles *usecaseNot.AvisoVencimientoRoles
}

// NuevoWorkersNotificaciones arma las etapas de notificación del proceso cmd/worker.
// Sin FCM configurado los avisos quedan en la bandeja de la app; sin SMTP no hay respaldo
// por correo.
func NuevoWorkersNotificaciones(cfg *config.Config, log *applog.Logger, mongoClient *mongoRepo.Client) (*WorkersNotificaciones, error) {
	cola := impl.NewNotificacionRepository(mongoClient)
	productor := usecaseNot.NewProductor(cola, impl.NewEstructuraRepository(mongoClient), impl.NewEspacioRepository(mongoClient))
	programador := usecaseNot.NewProgramador(
		impl.NewAgendaRepository(mongoClient),
		impl.NewMarcajeMongoRepository(mongoClient.DB()),
		impl.NewProcesoRepository(mongoClient),
		productor,
	).ConAnticipacion(cfg.NotifRecordatorioMin, cfg.NotifCierreMin)

	silencio, err := notificacion.NuevaFranjaSilencio(cfg.NotifSilencioInicio, cfg.NotifSilencioFin, shared.ZonaInstitucional())
	if err != nil {
		return nil, err
	}
	var push usecaseNot.EnviadorPush
	if enviador := enviadorFCM(cfg, log); enviador != nil {
		push = enviador
	}
	var correo usecaseNot.Correo
	if cfg.SMTPHost != "" {
		correo = mailer.NewSMTPMailer(mailer.SMTPConfig{
			Host: cfg.SMTPHost, Port: cfg.SMTPPort, User: cfg.SMTPUser, Pass: cfg.SMTPPass, From: cfg.SMTPFrom,
		})
	}
	despachador := usecaseNot.NewDespachador(cola,
		impl.NewTokenPushRepository(mongoClient),
		impl.NewPreferenciasRepository(mongoClient),
		impl.NewUsuarioRepository(mongoClient),
		impl.NewDispositivoRepository(mongoClient),
		push, correo, silencio)
	usuarios := impl.NewUsuarioRepository(mongoClient)
	return &WorkersNotificaciones{
		Programador: programador, Despachador: despachador,
		Revision: usecaseNot.NewRecordatorioRevision(impl.NewJustificacionesSinResolverRepository(mongoClient), usuarios, productor).
			ConPlazoHoras(cfg.NotifRevisionHoras),
		VencimientoRoles: usecaseNot.NewAvisoVencimientoRoles(impl.NewRolesPorVencerRepository(mongoClient), usuarios, productor),
	}, nil
}

// enviadorFCM devuelve el cliente de FCM o nil si no está configurado.
func enviadorFCM(cfg *config.Config, log *applog.Logger) *fcm.Enviador {
	if cfg.FCMProyecto == "" || cfg.FCMCredenciales == "" {
		log.Info("FCM no configurado: los avisos solo quedan en la bandeja de la app")
		return nil
	}
	e, err := fcm.Nuevo(context.Background(), cfg.FCMProyecto, cfg.FCMCredenciales)
	if err != nil {
		log.Error("no se pudo iniciar FCM", applog.Err(err))
		return nil
	}
	return e
}

// NuevoRetencionWorker arma la anonimización periódica de coordenadas (Ley 1581). Respeta las
// investigaciones en curso y avisa a quien las marcó cuando suspende un plazo (US-AUD-04 AC-03).
func NuevoRetencionWorker(mongoClient *mongoRepo.Client) *usecasePriv.RetencionWorker {
	return usecasePriv.NewRetencionWorker(
		impl.NewRetencionRepository(mongoClient),
		impl.NewParametroRepo(mongoClient.DB()),
		bitacora(mongoClient, nil),
	).WithInvestigaciones(impl.NewInvestigacionRepository(mongoClient), impl.NewNotificacionRepository(mongoClient))
}
