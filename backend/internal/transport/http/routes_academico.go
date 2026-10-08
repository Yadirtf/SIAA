// Package http — rutas de estructura académica, horarios y asignaciones (EP-04).
package http

import (
	"net/http"

	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/platform/config"
	"github.com/siaa/backend/internal/repository"
	"github.com/siaa/backend/internal/transport/http/handler"
	mw "github.com/siaa/backend/internal/transport/http/middleware"
)

func registerAcademicoRoutes(
	api *echo.Group,
	cfg *config.Config,
	auditoria repository.AuditoriaRepository,
	registry *RouteRegistry,
	acaH *handler.AcademicoHandler,
) {
	if acaH == nil {
		return
	}
	// Periodos (US-ACA-01, US-ACA-05)
	periodos := api.Group("/periodos", mw.JWTAuth(cfg), mw.RateLimiterByUser(120))
	periodos.GET("", acaH.ListarPeriodos, mw.RequirePermission(rbac.PermHorarioLeer, auditoria))
	registry.RegisterPermission(http.MethodGet, "/api/v1/periodos", rbac.PermHorarioLeer)
	periodos.POST("", acaH.CrearPeriodo, mw.RequirePermission(rbac.PermHorarioCrear, auditoria))
	registry.RegisterPermission(http.MethodPost, "/api/v1/periodos", rbac.PermHorarioCrear)
	periodos.GET("/:id", acaH.ObtenerPeriodo, mw.RequirePermission(rbac.PermHorarioLeer, auditoria))
	registry.RegisterPermission(http.MethodGet, "/api/v1/periodos/:id", rbac.PermHorarioLeer)
	periodos.PUT("/:id", acaH.ActualizarPeriodo, mw.RequirePermission(rbac.PermHorarioCrear, auditoria))
	registry.RegisterPermission(http.MethodPut, "/api/v1/periodos/:id", rbac.PermHorarioCrear)
	periodos.POST("/:id/generar-sesiones", acaH.GenerarSesiones, mw.RequirePermission(rbac.PermHorarioCrear, auditoria))
	registry.RegisterPermission(http.MethodPost, "/api/v1/periodos/:id/generar-sesiones", rbac.PermHorarioCrear)

	// Sesiones de clase (US-ACA-05, US-ACA-06, US-ACA-08, US-MAR-01)
	sesiones := api.Group("/sesiones", mw.JWTAuth(cfg), mw.RateLimiterByUser(120))
	sesiones.GET("", acaH.ListarSesiones, mw.RequirePermission(rbac.PermHorarioLeer, auditoria))
	registry.RegisterPermission(http.MethodGet, "/api/v1/sesiones", rbac.PermHorarioLeer)
	sesiones.GET("/:id", acaH.ObtenerSesion, mw.RequirePermission(rbac.PermHorarioLeer, auditoria))
	registry.RegisterPermission(http.MethodGet, "/api/v1/sesiones/:id", rbac.PermHorarioLeer)
	sesiones.POST("/:id/cancelar", acaH.CancelarSesion, mw.RequirePermission(rbac.PermHorarioCrear, auditoria))
	registry.RegisterPermission(http.MethodPost, "/api/v1/sesiones/:id/cancelar", rbac.PermHorarioCrear)
	sesiones.PUT("/:id/aula", acaH.ReasignarAulaSesion, mw.RequirePermission(rbac.PermHorarioCrear, auditoria))
	registry.RegisterPermission(http.MethodPut, "/api/v1/sesiones/:id/aula", rbac.PermHorarioCrear)
	sesiones.PATCH("/:id/docente-reemplazo", acaH.AsignarDocenteReemplazo, mw.RequirePermission(rbac.PermHorarioCrear, auditoria))
	registry.RegisterPermission(http.MethodPatch, "/api/v1/sesiones/:id/docente-reemplazo", rbac.PermHorarioCrear)

	// Importación masiva académica (US-ACA-07)
	acaImport := api.Group("/academico", mw.JWTAuth(cfg), mw.RateLimiterByUser(120))
	acaImport.POST("/importar/preview", acaH.PreviewImportarAcademicoCSV, mw.RequirePermission(rbac.PermHorarioCrear, auditoria))
	registry.RegisterPermission(http.MethodPost, "/api/v1/academico/importar/preview", rbac.PermHorarioCrear)
	acaImport.POST("/importar", acaH.ConfirmarImportarAcademico, mw.RequirePermission(rbac.PermHorarioCrear, auditoria))
	registry.RegisterPermission(http.MethodPost, "/api/v1/academico/importar", rbac.PermHorarioCrear)
	acaImport.POST("/importar/diagnostico", acaH.DiagnosticoImportarAcademico, mw.RequirePermission(rbac.PermHorarioCrear, auditoria))
	registry.RegisterPermission(http.MethodPost, "/api/v1/academico/importar/diagnostico", rbac.PermHorarioCrear)
	acaImport.GET("/importar/plantilla", acaH.PlantillaImportarAcademico, mw.RequirePermission(rbac.PermHorarioCrear, auditoria))
	registry.RegisterPermission(http.MethodGet, "/api/v1/academico/importar/plantilla", rbac.PermHorarioCrear)

	// Facultades
	facultades := api.Group("/facultades", mw.JWTAuth(cfg), mw.RateLimiterByUser(120))
	facultades.GET("", acaH.ListarFacultades, mw.RequirePermission(rbac.PermHorarioLeer, auditoria))
	registry.RegisterPermission(http.MethodGet, "/api/v1/facultades", rbac.PermHorarioLeer)
	facultades.POST("", acaH.CrearFacultad, mw.RequirePermission(rbac.PermHorarioCrear, auditoria))
	registry.RegisterPermission(http.MethodPost, "/api/v1/facultades", rbac.PermHorarioCrear)
	facultades.PUT("/:id", acaH.ActualizarFacultad, mw.RequirePermission(rbac.PermHorarioCrear, auditoria))
	registry.RegisterPermission(http.MethodPut, "/api/v1/facultades/:id", rbac.PermHorarioCrear)
	facultades.DELETE("/:id", acaH.EliminarFacultad, mw.RequirePermission(rbac.PermHorarioCrear, auditoria))
	registry.RegisterPermission(http.MethodDelete, "/api/v1/facultades/:id", rbac.PermHorarioCrear)

	// Programas
	programas := api.Group("/programas", mw.JWTAuth(cfg), mw.RateLimiterByUser(120))
	programas.GET("", acaH.ListarProgramas, mw.RequirePermission(rbac.PermHorarioLeer, auditoria))
	registry.RegisterPermission(http.MethodGet, "/api/v1/programas", rbac.PermHorarioLeer)
	programas.POST("", acaH.CrearPrograma, mw.RequirePermission(rbac.PermHorarioCrear, auditoria))
	registry.RegisterPermission(http.MethodPost, "/api/v1/programas", rbac.PermHorarioCrear)
	programas.PUT("/:id", acaH.ActualizarPrograma, mw.RequirePermission(rbac.PermHorarioCrear, auditoria))
	registry.RegisterPermission(http.MethodPut, "/api/v1/programas/:id", rbac.PermHorarioCrear)
	programas.DELETE("/:id", acaH.EliminarPrograma, mw.RequirePermission(rbac.PermHorarioCrear, auditoria))
	registry.RegisterPermission(http.MethodDelete, "/api/v1/programas/:id", rbac.PermHorarioCrear)

	// Asignaturas
	asignaturas := api.Group("/asignaturas", mw.JWTAuth(cfg), mw.RateLimiterByUser(120))
	asignaturas.GET("", acaH.ListarAsignaturas, mw.RequirePermission(rbac.PermHorarioLeer, auditoria))
	registry.RegisterPermission(http.MethodGet, "/api/v1/asignaturas", rbac.PermHorarioLeer)
	asignaturas.POST("", acaH.CrearAsignatura, mw.RequirePermission(rbac.PermHorarioCrear, auditoria))
	registry.RegisterPermission(http.MethodPost, "/api/v1/asignaturas", rbac.PermHorarioCrear)
	asignaturas.PUT("/:id", acaH.ActualizarAsignatura, mw.RequirePermission(rbac.PermHorarioCrear, auditoria))
	registry.RegisterPermission(http.MethodPut, "/api/v1/asignaturas/:id", rbac.PermHorarioCrear)
	asignaturas.DELETE("/:id", acaH.EliminarAsignatura, mw.RequirePermission(rbac.PermHorarioCrear, auditoria))
	registry.RegisterPermission(http.MethodDelete, "/api/v1/asignaturas/:id", rbac.PermHorarioCrear)

	// Grupos
	grupos := api.Group("/grupos", mw.JWTAuth(cfg), mw.RateLimiterByUser(120))
	grupos.GET("", acaH.ListarGrupos, mw.RequirePermission(rbac.PermHorarioLeer, auditoria))
	registry.RegisterPermission(http.MethodGet, "/api/v1/grupos", rbac.PermHorarioLeer)
	grupos.POST("", acaH.CrearGrupo, mw.RequirePermission(rbac.PermHorarioCrear, auditoria))
	registry.RegisterPermission(http.MethodPost, "/api/v1/grupos", rbac.PermHorarioCrear)
	grupos.PUT("/:id", acaH.ActualizarGrupo, mw.RequirePermission(rbac.PermHorarioCrear, auditoria))
	registry.RegisterPermission(http.MethodPut, "/api/v1/grupos/:id", rbac.PermHorarioCrear)
	grupos.DELETE("/:id", acaH.EliminarGrupo, mw.RequirePermission(rbac.PermHorarioCrear, auditoria))
	registry.RegisterPermission(http.MethodDelete, "/api/v1/grupos/:id", rbac.PermHorarioCrear)
	// Estudiantes del grupo (US-MAR-13, US-MAR-14)
	grupos.GET("/:id/estudiantes", acaH.ListarEstudiantesGrupo, mw.RequirePermission(rbac.PermHorarioCrear, auditoria))
	registry.RegisterPermission(http.MethodGet, "/api/v1/grupos/:id/estudiantes", rbac.PermHorarioCrear)
	grupos.PUT("/:id/estudiantes", acaH.ReemplazarEstudiantesGrupo, mw.RequirePermission(rbac.PermHorarioCrear, auditoria))
	registry.RegisterPermission(http.MethodPut, "/api/v1/grupos/:id/estudiantes", rbac.PermHorarioCrear)

	// Asignaciones (US-ACA-03)
	asignaciones := api.Group("/asignaciones", mw.JWTAuth(cfg), mw.RateLimiterByUser(120))
	asignaciones.GET("", acaH.ListarAsignaciones, mw.RequirePermission(rbac.PermHorarioLeer, auditoria))
	registry.RegisterPermission(http.MethodGet, "/api/v1/asignaciones", rbac.PermHorarioLeer)
	asignaciones.POST("", acaH.CrearAsignacion, mw.RequirePermission(rbac.PermAsignacionCrear, auditoria))
	registry.RegisterPermission(http.MethodPost, "/api/v1/asignaciones", rbac.PermAsignacionCrear)
	asignaciones.PUT("/:id", acaH.ActualizarAsignacion, mw.RequirePermission(rbac.PermAsignacionCrear, auditoria))
	registry.RegisterPermission(http.MethodPut, "/api/v1/asignaciones/:id", rbac.PermAsignacionCrear)
	asignaciones.DELETE("/:id", acaH.EliminarAsignacion, mw.RequirePermission(rbac.PermAsignacionCrear, auditoria))
	registry.RegisterPermission(http.MethodDelete, "/api/v1/asignaciones/:id", rbac.PermAsignacionCrear)

	// Calendario de Excepciones (US-ACA-04)
	excepciones := api.Group("/calendario-excepciones", mw.JWTAuth(cfg), mw.RateLimiterByUser(120))
	excepciones.GET("", acaH.ListarExcepciones, mw.RequirePermission(rbac.PermHorarioLeer, auditoria))
	registry.RegisterPermission(http.MethodGet, "/api/v1/calendario-excepciones", rbac.PermHorarioLeer)
	excepciones.POST("", acaH.CrearExcepcion, mw.RequirePermission(rbac.PermHorarioCrear, auditoria))
	registry.RegisterPermission(http.MethodPost, "/api/v1/calendario-excepciones", rbac.PermHorarioCrear)
	excepciones.DELETE("/:id", acaH.EliminarExcepcion, mw.RequirePermission(rbac.PermHorarioCrear, auditoria))
	registry.RegisterPermission(http.MethodDelete, "/api/v1/calendario-excepciones/:id", rbac.PermHorarioCrear)
}
