// Package http — registro y verificación de seguridad de rutas al arranque.
// T-ROL-01.4, AC-03: toda ruta registrada declara permiso o se marca pública;
// en caso contrario el servicio NO arranca.
package http

import (
	"fmt"
	"strings"
	"sync"

	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/domain/rbac"
)

// RouteSecurityType indica el tipo de seguridad asignado a la ruta.
type RouteSecurityType string

const (
	SecurityPublic     RouteSecurityType = "PUBLIC"
	SecurityPermission RouteSecurityType = "PERMISSION"
)

// RouteSecurityMetadata almacena los metadatos de seguridad de una ruta.
type RouteSecurityMetadata struct {
	Type       RouteSecurityType
	Permission rbac.Permission
}

// RouteRegistry mantiene el inventario estricto de seguridad de rutas.
type RouteRegistry struct {
	mu     sync.RWMutex
	routes map[string]RouteSecurityMetadata
}

// NewRouteRegistry inicializa un nuevo registro de rutas.
func NewRouteRegistry() *RouteRegistry {
	return &RouteRegistry{
		routes: make(map[string]RouteSecurityMetadata),
	}
}

func routeKey(method, path string) string {
	return fmt.Sprintf("%s %s", strings.ToUpper(method), strings.TrimSuffix(path, "/"))
}

// MarkPublic declara una ruta como pública (sin requerimiento de permiso RBAC).
func (r *RouteRegistry) MarkPublic(method, path string) {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.routes[routeKey(method, path)] = RouteSecurityMetadata{
		Type: SecurityPublic,
	}
}

// RegisterPermission declara el permiso granular obligatorio para una ruta.
func (r *RouteRegistry) RegisterPermission(method, path string, perm rbac.Permission) {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.routes[routeKey(method, path)] = RouteSecurityMetadata{
		Type:       SecurityPermission,
		Permission: perm,
	}
}

// VerifyAllRoutes inspecciona todas las rutas registradas en el enrutador Echo.
// Falla con error descriptivo si alguna ruta bajo /api/v1 no declara permiso ni es pública.
func (r *RouteRegistry) VerifyAllRoutes(e *echo.Echo) error {
	r.mu.RLock()
	defer r.mu.RUnlock()

	var undeclared []string
	for _, route := range e.Routes() {
		// Ignorar rutas internas/preflight de Echo o que no sean del prefijo de API
		if route.Method == echo.RouteNotFound || route.Path == "/*" || !strings.HasPrefix(route.Path, "/api/v1") {
			continue
		}

		key := routeKey(route.Method, route.Path)
		meta, exists := r.routes[key]
		if !exists || (meta.Type != SecurityPublic && meta.Permission == "") {
			undeclared = append(undeclared, key)
		}
	}

	if len(undeclared) > 0 {
		return fmt.Errorf("T-ROL-01.4: fallo de seguridad en arranque — rutas sin permiso declarado ni marca pública: [%s]",
			strings.Join(undeclared, ", "))
	}

	return nil
}
