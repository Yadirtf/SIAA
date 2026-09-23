package handler

import (
	"errors"
	"net/http"

	"github.com/labstack/echo/v4"

	domainAca "github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/transport/http/middleware"
	usecaseAca "github.com/siaa/backend/internal/usecase/academico"
)

type AcademicoHandler struct {
	svc *usecaseAca.Service
}

func NewAcademicoHandler(svc *usecaseAca.Service) *AcademicoHandler {
	return &AcademicoHandler{svc: svc}
}

func extraerActorAcademico(c echo.Context) usecaseAca.ContextoActor {
	actorID, _ := c.Get(middleware.CtxUsuarioID).(string)
	rol := ""
	if claims, ok := middleware.GetClaims(c); ok {
		rol = claims.RolActivo
	}
	return usecaseAca.ContextoActor{
		UsuarioID: actorID,
		Rol:       rol,
	}
}

func mapearErrorAcademico(err error) error {
	if err == nil {
		return nil
	}
	if errors.Is(err, usecaseAca.ErrColisionDetectada) {
		return echo.NewHTTPError(http.StatusConflict, err.Error())
	}
	if errors.Is(err, usecaseAca.ErrFueraDeAmbitoFacultad) {
		return echo.NewHTTPError(http.StatusForbidden, err.Error())
	}
	if errors.Is(err, usecaseAca.ErrPeriodoNoEncontrado) ||
		errors.Is(err, usecaseAca.ErrFacultadNoEncontrada) ||
		errors.Is(err, usecaseAca.ErrProgramaNoEncontrado) ||
		errors.Is(err, usecaseAca.ErrAsignaturaNoEncontrada) ||
		errors.Is(err, usecaseAca.ErrGrupoNoEncontrado) ||
		errors.Is(err, usecaseAca.ErrAsignacionNoEncontrada) ||
		errors.Is(err, usecaseAca.ErrExcepcionNoEncontrada) {
		return echo.NewHTTPError(http.StatusNotFound, err.Error())
	}
	if errors.Is(err, domainAca.ErrPeriodoCerradoModif) {
		return echo.NewHTTPError(http.StatusConflict, err.Error())
	}
	return echo.NewHTTPError(http.StatusBadRequest, err.Error())
}
