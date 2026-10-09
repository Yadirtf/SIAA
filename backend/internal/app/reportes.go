// Package app — cableado de los reportes operativos de EP-08 (tablero, ocupación, asistencia).
package app

import (
	"github.com/siaa/backend/internal/platform/clock"
	"github.com/siaa/backend/internal/repository"
	mongoRepo "github.com/siaa/backend/internal/repository/mongo"
	"github.com/siaa/backend/internal/repository/mongo/impl"
	"github.com/siaa/backend/internal/transport/http/handler"
	usecaseMarcaje "github.com/siaa/backend/internal/usecase/marcaje"
	usecaseRep "github.com/siaa/backend/internal/usecase/reportes"
)

// reportesHandler arma el handler de reportes con el tablero en vivo (US-REP-03), la
// ocupación de espacios (US-REP-04) y la asistencia estudiantil (US-REP-05), que reutiliza
// el mismo cálculo de GET /me/asistencia.
func reportesHandler(
	mongoClient *mongoRepo.Client,
	base *usecaseRep.Service,
	sesiones repository.SesionRepository,
	marcajes repository.MarcajeRepository,
	usuarios repository.UsuarioRepository,
	espacios repository.EspacioRepository,
	bloques repository.BloqueRepository,
	sedes repository.SedeRepository,
	estructura repository.EstructuraRepository,
	asistencia *usecaseMarcaje.AsistenciaEstudianteUseCase,
) *handler.ReportesHandler {
	clk := clock.RealClock{}
	tablero := usecaseRep.NewTableroService(sesiones, marcajes, impl.NewAlertasRepository(mongoClient),
		usuarios, espacios, estructura, clk)
	return handler.NewReportesHandler(base).
		WithTablero(tablero).
		WithOcupacion(usecaseRep.NewOcupacionService(base, espacios, bloques, sedes)).
		WithAsistenciaGrupos(usecaseRep.NewAsistenciaGrupoService(asistencia, sesiones, estructura, usuarios, clk))
}
