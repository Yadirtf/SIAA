// Package http — rutas de gestión de usuarios y dispositivos (US-AUT-02/03/07, US-ROL-01..05).
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

func registerUsuarioRoutes(
	api *echo.Group,
	cfg *config.Config,
	auditoria repository.AuditoriaRepository,
	registry *RouteRegistry,
	authH *handler.AuthHandler,
	usuariosH *handler.UsuariosHandler,
) {
	// Cada ruta exige token, tasa de 120 req/min por usuario y su permiso (T-ROL-01.4).
	proteger := func(g *echo.Group, prefijo, metodo, ruta string, h echo.HandlerFunc, perm rbac.Permission) {
		g.Add(metodo, ruta, h, mw.RequirePermission(perm, auditoria))
		registry.RegisterPermission(metodo, "/api/v1"+prefijo+ruta, perm)
	}

	u := api.Group("/usuarios", mw.JWTAuth(cfg), mw.RateLimiterByUser(120))
	if usuariosH != nil {
		// Gestión de usuarios, roles y ámbitos, auditada (RF-ROL-003, RF-ROL-005).
		proteger(u, "/usuarios", http.MethodGet, "", usuariosH.Listar, rbac.PermUsuarioLeer)
		proteger(u, "/usuarios", http.MethodPost, "", usuariosH.Crear, rbac.PermUsuarioCrear)
		proteger(u, "/usuarios", http.MethodPost, "/importar", usuariosH.Importar, rbac.PermUsuarioCrear)
		proteger(u, "/usuarios", http.MethodGet, "/:id", usuariosH.Obtener, rbac.PermUsuarioLeer)
		proteger(u, "/usuarios", http.MethodPut, "/:id", usuariosH.Actualizar, rbac.PermUsuarioEditar)
		proteger(u, "/usuarios", http.MethodPost, "/:id/activar", usuariosH.Activar, rbac.PermUsuarioEditar)
		proteger(u, "/usuarios", http.MethodPost, "/:id/desactivar", usuariosH.Desactivar, rbac.PermUsuarioEditar)
		proteger(u, "/usuarios", http.MethodPut, "/:id/roles", usuariosH.AsignarRoles, rbac.PermUsuarioEditar)
		proteger(u, "/usuarios", http.MethodPut, "/:id/ambitos", usuariosH.AsignarAmbitos, rbac.PermUsuarioEditar)
	}
	// Desbloqueo administrativo auditado (US-AUT-02 AC-02) y cierre remoto de sesiones (US-AUT-07).
	proteger(u, "/usuarios", http.MethodPost, "/:id/desbloquear", authH.DesbloquearUsuario, rbac.PermUsuarioEditar)
	proteger(u, "/usuarios", http.MethodPost, "/:id/revocar-sesiones", authH.RevocarSesiones, rbac.PermUsuarioEditar)
	proteger(u, "/usuarios", http.MethodGet, "/:id/dispositivos", authH.ListarDispositivosUsuario, rbac.PermUsuarioLeer)

	// Gestión de dispositivos confiables (US-AUT-03).
	d := api.Group("/dispositivos", mw.JWTAuth(cfg), mw.RateLimiterByUser(120))
	proteger(d, "/dispositivos", http.MethodPost, "/:id/aprobar", authH.AprobarDispositivo, rbac.PermUsuarioEditar)
	proteger(d, "/dispositivos", http.MethodPost, "/:id/revocar", authH.RevocarDispositivo, rbac.PermUsuarioEditar)
}
