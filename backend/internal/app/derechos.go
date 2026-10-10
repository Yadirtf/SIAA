package app

import (
	"github.com/siaa/backend/internal/domain/privacidad"
	"github.com/siaa/backend/internal/repository"
	mongoRepo "github.com/siaa/backend/internal/repository/mongo"
	"github.com/siaa/backend/internal/repository/mongo/impl"
	"github.com/siaa/backend/internal/transport/http/handler"
	usecasePriv "github.com/siaa/backend/internal/usecase/privacidad"
)

// construirDerechos arma el canal de derechos del titular (US-LEG-02): copia de datos,
// rectificación y supresión con su bandeja de atención.
func construirDerechos(politica privacidad.Politica, mongoClient *mongoRepo.Client, auditoria repository.AuditoriaRepository,
	avisos usecasePriv.AvisoDerechos,
) *handler.DerechosHandler {
	svc := usecasePriv.NewDerechosService(
		privacidad.NuevoCanalDerechos(politica.Institucion, politica.Contacto),
		impl.NewSolicitudDerechoRepository(mongoClient),
		impl.NewUsuarioRepository(mongoClient),
		impl.NewSupresionTitularRepository(mongoClient),
		auditoria,
	).WithInvestigaciones(impl.NewInvestigacionRepository(mongoClient)).
		WithAvisos(avisos).
		WithFuentes(usecasePriv.FuentesCopia{
			Dispositivos:    impl.NewDispositivoRepository(mongoClient),
			Marcajes:        impl.NewMarcajeMongoRepository(mongoClient.DB()),
			Justificaciones: impl.NewJustificacionRepository(mongoClient),
			Consentimientos: impl.NewConsentimientoHistorialRepository(mongoClient),
		})
	return handler.NewDerechosHandler(svc)
}
