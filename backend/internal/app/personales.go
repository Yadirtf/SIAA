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
)

// construirPersonales arma el aviso de privacidad con su consentimiento (Ley 1581) y la
// bandeja de notificaciones (EP-10). Devuelve además el productor que encola los avisos
// que generan el horario y las justificaciones.
func construirPersonales(cfg *config.Config, mongoClient *mongoRepo.Client, auditoria repository.AuditoriaRepository,
	estructura repository.EstructuraRepository, espacios repository.EspacioRepository,
) (*apphttp.HandlersPersonales, *usecaseNot.Productor) {
	privSvc := usecasePriv.NewService(
		politica.Construir(cfg.InstitucionNombre, cfg.PrivacidadContacto),
		impl.NewConsentimientoRepository(mongoClient),
		auditoria,
	)
	cola := impl.NewNotificacionRepository(mongoClient)
	notSvc := usecaseNot.NewService(
		impl.NewTokenPushRepository(mongoClient),
		impl.NewPreferenciasRepository(mongoClient),
		cola,
	)
	handlers := &apphttp.HandlersPersonales{
		Privacidad:     handler.NewPrivacidadHandler(privSvc),
		Notificaciones: handler.NewNotificacionesHandler(notSvc),
	}
	return handlers, usecaseNot.NewProductor(cola, estructura, espacios)
}
