package app

import (
	"github.com/siaa/backend/internal/platform/config"
	"github.com/siaa/backend/internal/platform/politica"
	"github.com/siaa/backend/internal/repository"
	mongoRepo "github.com/siaa/backend/internal/repository/mongo"
	"github.com/siaa/backend/internal/repository/mongo/impl"
	apphttp "github.com/siaa/backend/internal/transport/http"
	"github.com/siaa/backend/internal/transport/http/handler"
	usecaseNot "github.com/siaa/backend/internal/usecase/notificaciones"
	usecasePriv "github.com/siaa/backend/internal/usecase/privacidad"
	usecaseUsuarios "github.com/siaa/backend/internal/usecase/usuarios"
)

// construirPersonales arma el aviso de privacidad con su consentimiento (Ley 1581) y la
// bandeja de notificaciones (EP-10) y los derechos del titular (US-LEG-02). Devuelve además el productor que encola los avisos
// que generan el horario y las justificaciones.
func construirPersonales(cfg *config.Config, mongoClient *mongoRepo.Client, auditoria repository.AuditoriaRepository,
	estructura repository.EstructuraRepository, espacios repository.EspacioRepository,
) (*apphttp.HandlersPersonales, *usecaseNot.Productor) {
	pol := politica.Construir(cfg.InstitucionNombre, cfg.PrivacidadContacto)
	privSvc := usecasePriv.NewService(
		pol,
		impl.NewConsentimientoRepository(mongoClient),
		auditoria,
	)
	cola := impl.NewNotificacionRepository(mongoClient)
	notSvc := usecaseNot.NewService(
		impl.NewTokenPushRepository(mongoClient),
		impl.NewPreferenciasRepository(mongoClient),
		cola,
	)
	productor := usecaseNot.NewProductor(cola, estructura, espacios)
	handlers := &apphttp.HandlersPersonales{
		Derechos:       construirDerechos(pol, mongoClient, auditoria, productor),
		Auditoria:      auditoria,
		Privacidad:     handler.NewPrivacidadHandler(privSvc),
		Notificaciones: handler.NewNotificacionesHandler(notSvc),
		Perfil: handler.NewPerfilHandler(usecaseUsuarios.NewServicioPerfil(
			impl.NewUsuarioRepository(mongoClient), impl.NewDispositivoRepository(mongoClient))),
	}
	return handlers, productor
}
