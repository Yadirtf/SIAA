package handler

import (
	"errors"
	"net/http"
	"time"

	"github.com/labstack/echo/v4"

	domainAca "github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/transport/http/dto"
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

// ─────────────────────────────────────────────────────────────
// PERIODOS (US-ACA-01)
// ─────────────────────────────────────────────────────────────

func (h *AcademicoHandler) CrearPeriodo(c echo.Context) error {
	var req dto.CrearPeriodoRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "cuerpo de solicitud inválido")
	}

	fIni, err := dto.ParseFechaFlexible(req.FechaInicio)
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "fecha de inicio inválida: use YYYY-MM-DD")
	}
	fFin, err := dto.ParseFechaFlexible(req.FechaFin)
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "fecha de fin inválida: use YYYY-MM-DD")
	}

	var ext *string
	if req.CodigoExterno != "" {
		ext = &req.CodigoExterno
	}

	actor := extraerActorAcademico(c)
	res, err := h.svc.CrearPeriodo(c.Request().Context(), actor, usecaseAca.CrearPeriodoCmd{
		Codigo:        req.Codigo,
		Nombre:        req.Nombre,
		FechaInicio:   fIni,
		FechaFin:      fFin,
		Estado:        domainAca.EstadoPeriodo(req.Estado),
		SedeID:        req.SedeID,
		CodigoExterno: ext,
	})
	if err != nil {
		return mapearErrorAcademico(err)
	}

	return c.JSON(http.StatusCreated, dto.FromPeriodoDomain(res.Periodo, res.Advertencias))
}

func (h *AcademicoHandler) ActualizarPeriodo(c echo.Context) error {
	id := c.Param("id")
	var req dto.CrearPeriodoRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "cuerpo de solicitud inválido")
	}

	fIni, err := dto.ParseFechaFlexible(req.FechaInicio)
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "fecha de inicio inválida: use YYYY-MM-DD")
	}
	fFin, err := dto.ParseFechaFlexible(req.FechaFin)
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "fecha de fin inválida: use YYYY-MM-DD")
	}

	var ext *string
	if req.CodigoExterno != "" {
		ext = &req.CodigoExterno
	}

	actor := extraerActorAcademico(c)
	res, err := h.svc.ActualizarPeriodo(c.Request().Context(), actor, id, usecaseAca.CrearPeriodoCmd{
		Codigo:        req.Codigo,
		Nombre:        req.Nombre,
		FechaInicio:   fIni,
		FechaFin:      fFin,
		Estado:        domainAca.EstadoPeriodo(req.Estado),
		SedeID:        req.SedeID,
		CodigoExterno: ext,
	})
	if err != nil {
		return mapearErrorAcademico(err)
	}

	return c.JSON(http.StatusOK, dto.FromPeriodoDomain(res.Periodo, res.Advertencias))
}

func (h *AcademicoHandler) ObtenerPeriodo(c echo.Context) error {
	id := c.Param("id")
	p, err := h.svc.ObtenerPeriodo(c.Request().Context(), id)
	if err != nil {
		return mapearErrorAcademico(err)
	}
	return c.JSON(http.StatusOK, dto.FromPeriodoDomain(p, nil))
}

func (h *AcademicoHandler) ListarPeriodos(c echo.Context) error {
	sedeID := c.QueryParam("sedeId")
	lista, err := h.svc.ListarPeriodos(c.Request().Context(), sedeID)
	if err != nil {
		return mapearErrorAcademico(err)
	}

	res := make([]dto.PeriodoResponse, 0, len(lista))
	for _, p := range lista {
		res = append(res, dto.FromPeriodoDomain(p, nil))
	}
	return c.JSON(http.StatusOK, res)
}

// ─────────────────────────────────────────────────────────────
// ESTRUCTURA: FACULTADES, PROGRAMAS, ASIGNATURAS, GRUPOS
// ─────────────────────────────────────────────────────────────

func (h *AcademicoHandler) CrearFacultad(c echo.Context) error {
	var req dto.CrearFacultadRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "cuerpo de solicitud inválido")
	}
	actor := extraerActorAcademico(c)
	var ext *string
	if req.CodigoExterno != "" {
		ext = &req.CodigoExterno
	}
	f, err := h.svc.CrearFacultad(c.Request().Context(), actor, req.Codigo, req.Nombre, req.SedeID, ext)
	if err != nil {
		return mapearErrorAcademico(err)
	}
	return c.JSON(http.StatusCreated, dto.FromFacultadDomain(f))
}

func (h *AcademicoHandler) ListarFacultades(c echo.Context) error {
	sedeID := c.QueryParam("sedeId")
	lista, err := h.svc.ListarFacultades(c.Request().Context(), sedeID)
	if err != nil {
		return mapearErrorAcademico(err)
	}
	res := make([]dto.FacultadResponse, 0, len(lista))
	for _, f := range lista {
		res = append(res, dto.FromFacultadDomain(f))
	}
	return c.JSON(http.StatusOK, res)
}

func (h *AcademicoHandler) EliminarFacultad(c echo.Context) error {
	id := c.Param("id")
	actor := extraerActorAcademico(c)
	if err := h.svc.EliminarFacultad(c.Request().Context(), actor, id); err != nil {
		return mapearErrorAcademico(err)
	}
	return c.NoContent(http.StatusNoContent)
}

func (h *AcademicoHandler) CrearPrograma(c echo.Context) error {
	var req dto.CrearProgramaRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "cuerpo de solicitud inválido")
	}
	actor := extraerActorAcademico(c)
	var ext *string
	if req.CodigoExterno != "" {
		ext = &req.CodigoExterno
	}
	p, err := h.svc.CrearPrograma(c.Request().Context(), actor, req.Codigo, req.Nombre, req.FacultadID, ext)
	if err != nil {
		return mapearErrorAcademico(err)
	}
	return c.JSON(http.StatusCreated, dto.FromProgramaDomain(p))
}

func (h *AcademicoHandler) ListarProgramas(c echo.Context) error {
	facultadID := c.QueryParam("facultadId")
	lista, err := h.svc.ListarProgramas(c.Request().Context(), facultadID)
	if err != nil {
		return mapearErrorAcademico(err)
	}
	res := make([]dto.ProgramaResponse, 0, len(lista))
	for _, p := range lista {
		res = append(res, dto.FromProgramaDomain(p))
	}
	return c.JSON(http.StatusOK, res)
}

func (h *AcademicoHandler) EliminarPrograma(c echo.Context) error {
	id := c.Param("id")
	actor := extraerActorAcademico(c)
	if err := h.svc.EliminarPrograma(c.Request().Context(), actor, id); err != nil {
		return mapearErrorAcademico(err)
	}
	return c.NoContent(http.StatusNoContent)
}

func (h *AcademicoHandler) CrearAsignatura(c echo.Context) error {
	var req dto.CrearAsignaturaRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "cuerpo de solicitud inválido")
	}
	actor := extraerActorAcademico(c)
	var ext *string
	if req.CodigoExterno != "" {
		ext = &req.CodigoExterno
	}
	a, err := h.svc.CrearAsignatura(c.Request().Context(), actor, req.Codigo, req.Nombre, req.ProgramaID, req.Creditos, ext)
	if err != nil {
		return mapearErrorAcademico(err)
	}
	return c.JSON(http.StatusCreated, dto.FromAsignaturaDomain(a))
}

func (h *AcademicoHandler) ListarAsignaturas(c echo.Context) error {
	programaID := c.QueryParam("programaId")
	lista, err := h.svc.ListarAsignaturas(c.Request().Context(), programaID)
	if err != nil {
		return mapearErrorAcademico(err)
	}
	res := make([]dto.AsignaturaResponse, 0, len(lista))
	for _, a := range lista {
		res = append(res, dto.FromAsignaturaDomain(a))
	}
	return c.JSON(http.StatusOK, res)
}

func (h *AcademicoHandler) EliminarAsignatura(c echo.Context) error {
	id := c.Param("id")
	actor := extraerActorAcademico(c)
	if err := h.svc.EliminarAsignatura(c.Request().Context(), actor, id); err != nil {
		return mapearErrorAcademico(err)
	}
	return c.NoContent(http.StatusNoContent)
}

func (h *AcademicoHandler) CrearGrupo(c echo.Context) error {
	var req dto.CrearGrupoRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "cuerpo de solicitud inválido")
	}
	actor := extraerActorAcademico(c)
	var ext *string
	if req.CodigoExterno != "" {
		ext = &req.CodigoExterno
	}
	g, err := h.svc.CrearGrupo(c.Request().Context(), actor, req.Numero, req.AsignaturaID, req.PeriodoID, req.Cupo, ext)
	if err != nil {
		return mapearErrorAcademico(err)
	}
	return c.JSON(http.StatusCreated, dto.FromGrupoDomain(g))
}

func (h *AcademicoHandler) ListarGrupos(c echo.Context) error {
	asignaturaID := c.QueryParam("asignaturaId")
	periodoID := c.QueryParam("periodoId")
	lista, err := h.svc.ListarGrupos(c.Request().Context(), asignaturaID, periodoID)
	if err != nil {
		return mapearErrorAcademico(err)
	}
	res := make([]dto.GrupoResponse, 0, len(lista))
	for _, g := range lista {
		res = append(res, dto.FromGrupoDomain(g))
	}
	return c.JSON(http.StatusOK, res)
}

func (h *AcademicoHandler) EliminarGrupo(c echo.Context) error {
	id := c.Param("id")
	actor := extraerActorAcademico(c)
	if err := h.svc.EliminarGrupo(c.Request().Context(), actor, id); err != nil {
		return mapearErrorAcademico(err)
	}
	return c.NoContent(http.StatusNoContent)
}

// ─────────────────────────────────────────────────────────────
// ASIGNACIONES (US-ACA-03)
// ─────────────────────────────────────────────────────────────

func (h *AcademicoHandler) CrearAsignacion(c echo.Context) error {
	var req dto.CrearAsignacionRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "cuerpo de solicitud inválido")
	}

	var fIni, fFin time.Time
	if req.FechaInicio != "" {
		fIni, _ = dto.ParseFechaFlexible(req.FechaInicio)
	}
	if req.FechaFin != "" {
		fFin, _ = dto.ParseFechaFlexible(req.FechaFin)
	}

	var ext *string
	if req.CodigoExterno != "" {
		ext = &req.CodigoExterno
	}

	actor := extraerActorAcademico(c)
	cmd := usecaseAca.CrearAsignacionCmd{
		PeriodoID:          req.PeriodoID,
		DocenteIDs:         req.DocenteIDs,
		DocenteNombre:      req.DocenteNombre,
		GrupoID:            req.GrupoID,
		AsignaturaID:       req.AsignaturaID,
		FacultadID:         req.FacultadID,
		EspacioID:          req.EspacioID,
		EspacioNombre:      req.EspacioNombre,
		DiaSemana:          req.Franja.DiaSemana,
		HoraInicio:         req.Franja.HoraInicio,
		HoraFin:            req.Franja.HoraFin,
		ZonaHoraria:        req.Franja.ZonaHoraria,
		Modalidad:          domainAca.ModalidadAsignacion(req.Modalidad),
		ParametrosOverride: req.ParametrosOverride,
		FechaInicio:        fIni,
		FechaFin:           fFin,
		CodigoExterno:      ext,
	}

	res, err := h.svc.CrearAsignacion(c.Request().Context(), actor, cmd)
	if err != nil {
		return mapearErrorAcademico(err)
	}

	return c.JSON(http.StatusCreated, dto.FromAsignacionDomain(res.Asignacion, res.Advertencias))
}

func (h *AcademicoHandler) ListarAsignaciones(c echo.Context) error {
	periodoID := c.QueryParam("periodoId")
	lista, err := h.svc.ListarAsignaciones(c.Request().Context(), periodoID)
	if err != nil {
		return mapearErrorAcademico(err)
	}

	res := make([]dto.AsignacionResponse, 0, len(lista))
	for _, a := range lista {
		res = append(res, dto.FromAsignacionDomain(&a, nil))
	}
	return c.JSON(http.StatusOK, res)
}

func (h *AcademicoHandler) EliminarAsignacion(c echo.Context) error {
	id := c.Param("id")
	actor := extraerActorAcademico(c)
	if err := h.svc.EliminarAsignacion(c.Request().Context(), actor, id); err != nil {
		return mapearErrorAcademico(err)
	}
	return c.NoContent(http.StatusNoContent)
}

// ─────────────────────────────────────────────────────────────
// CALENDARIO DE EXCEPCIONES (US-ACA-04)
// ─────────────────────────────────────────────────────────────

func (h *AcademicoHandler) CrearExcepcion(c echo.Context) error {
	var req dto.CrearExcepcionRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "cuerpo de solicitud inválido")
	}

	fIni, err := dto.ParseFechaFlexible(req.FechaInicio)
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "fecha de inicio inválida: use YYYY-MM-DD")
	}
	fFin, err := dto.ParseFechaFlexible(req.FechaFin)
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "fecha de fin inválida: use YYYY-MM-DD")
	}

	actor := extraerActorAcademico(c)
	exc, err := h.svc.CrearExcepcion(c.Request().Context(), actor, usecaseAca.CrearExcepcionCmd{
		Nombre:      req.Nombre,
		Tipo:        domainAca.TipoExcepcion(req.Tipo),
		Ambito:      domainAca.AmbitoExcepcion(req.Ambito),
		AmbitoID:    req.AmbitoID,
		FechaInicio: fIni,
		FechaFin:    fFin,
	})
	if err != nil {
		return mapearErrorAcademico(err)
	}

	return c.JSON(http.StatusCreated, dto.FromExcepcionDomain(exc))
}

func (h *AcademicoHandler) ListarExcepciones(c echo.Context) error {
	lista, err := h.svc.ListarExcepciones(c.Request().Context())
	if err != nil {
		return mapearErrorAcademico(err)
	}

	res := make([]dto.ExcepcionResponse, 0, len(lista))
	for _, e := range lista {
		res = append(res, dto.FromExcepcionDomain(e))
	}
	return c.JSON(http.StatusOK, res)
}

func (h *AcademicoHandler) EliminarExcepcion(c echo.Context) error {
	id := c.Param("id")
	actor := extraerActorAcademico(c)
	if err := h.svc.EliminarExcepcion(c.Request().Context(), actor, id); err != nil {
		return mapearErrorAcademico(err)
	}
	return c.NoContent(http.StatusNoContent)
}
