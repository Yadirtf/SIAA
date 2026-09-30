// Package http — rutas de privacidad (EP-11) y notificaciones (EP-10) del usuario autenticado.
package http

import (
	"net/http"

	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/platform/config"
	"github.com/siaa/backend/internal/transport/http/handler"
	mw "github.com/siaa/backend/internal/transport/http/middleware"
)

// HandlersPersonales agrupa las rutas propias del titular: aviso de privacidad,
// consentimiento y avisos.
type HandlersPersonales struct {
	Privacidad     *handler.PrivacidadHandler
	Notificaciones *handler.NotificacionesHandler
	Perfil         *handler.PerfilHandler
}

// exigirConsentimiento devuelve el middleware que bloquea el marcaje sin consentimiento.
func (h *HandlersPersonales) exigirConsentimiento() echo.MiddlewareFunc {
	if h == nil || h.Privacidad == nil {
		return mw.ExigirConsentimiento(nil)
	}
	return mw.ExigirConsentimiento(h.Privacidad.Servicio().PuedeMarcar)
}

// registerPersonalesRoutes: todas son del propio usuario (sin permiso RBAC, con token), salvo
// la política, que es pública (RNF-LEG-003).
func registerPersonalesRoutes(api *echo.Group, cfg *config.Config, registry *RouteRegistry, h *HandlersPersonales) {
	if h == nil {
		return
	}
	propia := func(g *echo.Group, metodo, prefijo, ruta string, fn echo.HandlerFunc) {
		g.Add(metodo, ruta, fn)
		registry.MarkPublic(metodo, "/api/v1"+prefijo+ruta)
	}
	if p := h.Privacidad; p != nil {
		api.GET("/privacidad/politica", p.Politica, mw.RateLimiterByIP(60))
		registry.MarkPublic(http.MethodGet, "/api/v1/privacidad/politica")
		me := api.Group("/me/consentimiento", mw.JWTAuth(cfg), mw.RateLimiterByUser(60))
		propia(me, http.MethodGet, "/me/consentimiento", "", p.Estado)
		propia(me, http.MethodPost, "/me/consentimiento", "", p.Decidir)
	}
	if p := h.Perfil; p != nil {
		g := api.Group("/me/perfil", mw.JWTAuth(cfg), mw.RateLimiterByUser(60))
		propia(g, http.MethodGet, "/me/perfil", "", p.Obtener)
	}
	if n := h.Notificaciones; n != nil {
		g := api.Group("/me/notificaciones", mw.JWTAuth(cfg), mw.RateLimiterByUser(120))
		propia(g, http.MethodGet, "/me/notificaciones", "", n.Bandeja)
		propia(g, http.MethodPost, "/me/notificaciones", "/:id/leida", n.MarcarLeida)
		propia(g, http.MethodPost, "/me/notificaciones", "/tokens", n.RegistrarToken)
		propia(g, http.MethodDelete, "/me/notificaciones", "/tokens", n.EliminarToken)
		propia(g, http.MethodGet, "/me/notificaciones", "/preferencias", n.Preferencias)
		propia(g, http.MethodPut, "/me/notificaciones", "/preferencias", n.GuardarPreferencias)
	}
}
