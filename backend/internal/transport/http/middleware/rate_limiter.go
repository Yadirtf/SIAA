// Package middleware — limitador de tasa de peticiones (rate limiting).
// T-AUT-02.2, RNF-SEG-005.
// NOTA: Esta implementación en memoria es para desarrollo y CI.
// En producción se reemplaza por Redis/Cloudflare (T-AUT-02.4).
package middleware

import (
	"time"

	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/domain/shared"
)

// RateLimiter crea un limitador de tasa en memoria por dirección IP.
// maxPerMinute: número máximo de peticiones por IP por minuto.
func RateLimiter(maxPerMinute int) echo.MiddlewareFunc {
	type entry struct {
		count   int
		resetAt time.Time
	}
	store := make(map[string]*entry)

	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			ip := c.RealIP()
			now := time.Now()

			e, ok := store[ip]
			if !ok || now.After(e.resetAt) {
				store[ip] = &entry{count: 1, resetAt: now.Add(time.Minute)}
				return next(c)
			}

			e.count++
			if e.count > maxPerMinute {
				c.Response().Header().Set("Retry-After", "60")
				return shared.NewAuthError(shared.ErrLimiteTasa, "Demasiadas peticiones. Espera un momento.")
			}

			return next(c)
		}
	}
}
