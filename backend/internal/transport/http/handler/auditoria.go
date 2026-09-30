// Package handler — consulta y exportación de la bitácora (RF-AUD-003).
package handler

import (
	"net/http"
	"strconv"
	"time"

	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/repository"
	"github.com/siaa/backend/internal/transport/http/middleware"
	"github.com/siaa/backend/internal/usecase/auditoria"
)

// AuditoriaHandler expone la bitácora en modo solo lectura.
type AuditoriaHandler struct {
	svc *auditoria.Service
}

// NewAuditoriaHandler crea el handler de auditoría.
func NewAuditoriaHandler(svc *auditoria.Service) *AuditoriaHandler {
	return &AuditoriaHandler{svc: svc}
}

// EntradaAuditoriaDTO es un registro de la bitácora en la API.
type EntradaAuditoriaDTO struct {
	ID            string      `json:"id"`
	Entidad       string      `json:"entidad"`
	EntidadID     string      `json:"entidadId"`
	Accion        string      `json:"accion"`
	ActorID       string      `json:"actorId"`
	ActorNombre   string      `json:"actorNombre"`
	RolActivo     string      `json:"rolActivo,omitempty"`
	CorrelationID string      `json:"correlationId,omitempty"`
	IPOrigen      string      `json:"ipOrigen,omitempty"`
	AgenteUsuario string      `json:"agenteUsuario,omitempty"`
	ValorAnterior interface{} `json:"valorAnterior,omitempty"`
	ValorNuevo    interface{} `json:"valorNuevo,omitempty"`
	CreadoEn      time.Time   `json:"creadoEn"`
}

// filtroAuditoria lee los filtros; las fechas aceptan RFC 3339 o AAAA-MM-DD (hasta incluye el día).
func filtroAuditoria(c echo.Context) (repository.FiltroAuditoria, error) {
	f := repository.FiltroAuditoria{
		Entidad:   c.QueryParam("entidad"),
		EntidadID: c.QueryParam("entidadId"),
		ActorID:   c.QueryParam("actorId"),
		Accion:    c.QueryParam("accion"),
	}
	for _, p := range []struct {
		nombre  string
		destino **time.Time
		finDia  bool
	}{{"desde", &f.Desde, false}, {"hasta", &f.Hasta, true}} {
		v := c.QueryParam(p.nombre)
		if v == "" {
			continue
		}
		t, err := time.Parse(time.RFC3339, v)
		if err != nil {
			d, errDia := time.ParseInLocation("2006-01-02", v, shared.ZonaInstitucional())
			if errDia != nil {
				return f, shared.NewValidationError("fecha inválida en " + p.nombre + "; use AAAA-MM-DD o RFC 3339")
			}
			if p.finDia {
				d = d.Add(24*time.Hour - time.Nanosecond)
			}
			t = d
		}
		t = t.UTC()
		*p.destino = &t
	}
	return f, nil
}

// Consultar maneja GET /auditoria?entidad=&entidadId=&actorId=&accion=&desde=&hasta=&pagina=&limite=.
// Devuelve la lista y el total en X-Total-Count.
func (h *AuditoriaHandler) Consultar(c echo.Context) error {
	f, err := filtroAuditoria(c)
	if err != nil {
		return err
	}
	pagina, _ := strconv.ParseInt(c.QueryParam("pagina"), 10, 64)
	limite, _ := strconv.ParseInt(c.QueryParam("limite"), 10, 64)
	res, err := h.svc.Consultar(c.Request().Context(), f, pagina, limite)
	if err != nil {
		return err
	}
	lista := make([]EntradaAuditoriaDTO, len(res.Entradas))
	for i, e := range res.Entradas {
		lista[i] = EntradaAuditoriaDTO{
			ID: e.ID, Entidad: e.Entidad, EntidadID: e.EntidadID, Accion: e.Accion,
			ActorID: e.ActorID, ActorNombre: e.ActorNombre, RolActivo: e.RolActivo,
			CorrelationID: e.CorrelationID, IPOrigen: e.IPOrigen, AgenteUsuario: e.AgenteUsuario,
			ValorAnterior: e.ValorAnterior, ValorNuevo: e.ValorNuevo, CreadoEn: e.CreadoEn,
		}
	}
	c.Response().Header().Set("X-Total-Count", strconv.FormatInt(res.Total, 10))
	return c.JSON(http.StatusOK, lista)
}

// Exportar maneja GET /auditoria/exportar?formato=xlsx|pdf&... .
func (h *AuditoriaHandler) Exportar(c echo.Context) error {
	f, err := filtroAuditoria(c)
	if err != nil {
		return err
	}
	var actorID, rol string
	if claims, ok := middleware.GetClaims(c); ok {
		actorID, rol = claims.UsuarioID, claims.RolActivo
	}
	arch, err := h.svc.Exportar(c.Request().Context(), actorID, rol, f, c.QueryParam("formato"))
	if err != nil {
		return err
	}
	return enviarArchivo(c, arch.Nombre, arch.Mime, arch.Contenido)
}
