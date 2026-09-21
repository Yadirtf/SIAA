// Package middleware — limitador de tasa de peticiones (rate limiting).
// T-AUT-02.2, RNF-SEG-005, US-AUT-02 (AC-03, AC-04).
// NOTA: Esta implementación en memoria es thread-safe con sync.RWMutex.
// En producción se complementa/reemplaza por Redis/Cloudflare (T-AUT-02.4).
package middleware

import (
	"fmt"
	"math"
	"sync"
	"time"

	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/domain/shared"
)

type rateLimitEntry struct {
	count   int
	resetAt time.Time
}

type memoryRateLimitStore struct {
	mu      sync.RWMutex
	entries map[string]*rateLimitEntry
}

func newMemoryRateLimitStore() *memoryRateLimitStore {
	return &memoryRateLimitStore{
		entries: make(map[string]*rateLimitEntry),
	}
}

func (s *memoryRateLimitStore) allow(key string, maxPerMinute int, now time.Time) (bool, time.Duration) {
	s.mu.Lock()
	defer s.mu.Unlock()

	e, exists := s.entries[key]
	if !exists || now.After(e.resetAt) {
		s.entries[key] = &rateLimitEntry{
			count:   1,
			resetAt: now.Add(time.Minute),
		}
		return true, 0
	}

	e.count++
	if e.count > maxPerMinute {
		retryAfter := e.resetAt.Sub(now)
		if retryAfter < 0 {
			retryAfter = time.Second
		}
		return false, retryAfter
	}

	return true, 0
}

// RateLimiterByIP limita la tasa por dirección IP.
// US-AUT-02 AC-03 / RNF-SEG-005: 20 req/min para autenticación.
func RateLimiterByIP(maxPerMinute int) echo.MiddlewareFunc {
	store := newMemoryRateLimitStore()
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			ip := c.RealIP()
			allowed, retryAfter := store.allow(ip, maxPerMinute, time.Now())
			if !allowed {
				secs := int(math.Ceil(retryAfter.Seconds()))
				if secs < 1 {
					secs = 1
				}
				c.Response().Header().Set("Retry-After", fmt.Sprintf("%d", secs))
				return shared.NewAuthError(shared.ErrLimiteTasa, "Demasiadas peticiones. Espera un momento.")
			}
			return next(c)
		}
	}
}

// RateLimiterByUser limita la tasa por identificador de usuario autenticado (claims.UsuarioID)
// o por IP si la petición no incluye contexto de usuario autenticado.
// US-AUT-02 AC-04 / RNF-SEG-005: 120 req/min por usuario sin afectar a otros.
func RateLimiterByUser(maxPerMinute int) echo.MiddlewareFunc {
	store := newMemoryRateLimitStore()
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			key := c.RealIP()
			if claims, ok := GetClaims(c); ok && claims.UsuarioID != "" {
				key = "user:" + claims.UsuarioID
			}

			allowed, retryAfter := store.allow(key, maxPerMinute, time.Now())
			if !allowed {
				secs := int(math.Ceil(retryAfter.Seconds()))
				if secs < 1 {
					secs = 1
				}
				c.Response().Header().Set("Retry-After", fmt.Sprintf("%d", secs))
				return shared.NewAuthError(shared.ErrLimiteTasa, "Demasiadas peticiones. Espera un momento.")
			}
			return next(c)
		}
	}
}

// RateLimiter mantiene compatibilidad hacia atrás delegando a RateLimiterByIP.
func RateLimiter(maxPerMinute int) echo.MiddlewareFunc {
	return RateLimiterByIP(maxPerMinute)
}
