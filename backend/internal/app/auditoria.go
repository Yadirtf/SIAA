// Package app — cableado de la bitácora transversal y de las investigaciones que suspenden
// la retención (US-AUD-01, US-AUD-04 AC-03).
package app

import (
	applog "github.com/siaa/backend/internal/platform/log"
	"github.com/siaa/backend/internal/repository"
	mongoRepo "github.com/siaa/backend/internal/repository/mongo"
	"github.com/siaa/backend/internal/repository/mongo/impl"
	"github.com/siaa/backend/internal/transport/http/handler"
	usecaseAud "github.com/siaa/backend/internal/usecase/auditoria"
	usecasePriv "github.com/siaa/backend/internal/usecase/privacidad"
)

// bitacora devuelve el repositorio de auditoría que usan todos los casos de uso: completa IP,
// agente de usuario y rol activo desde la petición y registra en el log los fallos de escritura.
func bitacora(mongoClient *mongoRepo.Client, log *applog.Logger) repository.AuditoriaRepository {
	return usecaseAud.NewRegistrador(impl.NewAuditoriaRepository(mongoClient), log)
}

// construirInvestigaciones arma el handler de investigaciones en curso.
func construirInvestigaciones(mongoClient *mongoRepo.Client, auditoria repository.AuditoriaRepository) *handler.InvestigacionesHandler {
	return handler.NewInvestigacionesHandler(
		usecasePriv.NewInvestigaciones(impl.NewInvestigacionRepository(mongoClient), auditoria))
}
