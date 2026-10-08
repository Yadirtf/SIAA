package http

import "github.com/siaa/backend/internal/platform/config"

// limiteAutenticacion devuelve las peticiones por minuto permitidas por IP en las rutas
// públicas de /auth (US-AUT-02 AC-03): 20 por defecto, configurable con
// AUTH_RATE_LIMIT_PER_MINUTE y nunca mayor que el límite global.
func limiteAutenticacion(cfg *config.Config) int {
	limite := 20
	if cfg.AuthRateLimitPerMinute > 0 {
		limite = cfg.AuthRateLimitPerMinute
	}
	if cfg.RateLimitPerMinute > 0 && cfg.RateLimitPerMinute < limite {
		limite = cfg.RateLimitPerMinute
	}
	return limite
}
