// Package academico — nombres de bloque y sede para ubicar cada sesión.
package academico

import (
	"context"

	"github.com/siaa/backend/internal/repository"
)

// WithUbicaciones habilita que los listados de sesiones informen el bloque y la sede del aula.
func (s *Service) WithUbicaciones(sedes repository.SedeRepository, bloques repository.BloqueRepository) *Service {
	s.sedeRepo, s.bloqueRepo = sedes, bloques
	return s
}

// cacheUbicaciones consulta cada bloque y sede una sola vez por listado.
type cacheUbicaciones struct {
	svc     *Service
	sedes   map[string]string
	bloques map[string]string
}

func (s *Service) nuevoCacheUbicaciones() *cacheUbicaciones {
	return &cacheUbicaciones{svc: s, sedes: map[string]string{}, bloques: map[string]string{}}
}

func (c *cacheUbicaciones) sede(ctx context.Context, id string) string {
	if id == "" || c.svc.sedeRepo == nil {
		return ""
	}
	if v, ok := c.sedes[id]; ok {
		return v
	}
	nombre := ""
	if sede, err := c.svc.sedeRepo.FindByID(ctx, id); err == nil && sede != nil {
		nombre = sede.Nombre
	}
	c.sedes[id] = nombre
	return nombre
}

func (c *cacheUbicaciones) bloque(ctx context.Context, id string) string {
	if id == "" || c.svc.bloqueRepo == nil {
		return ""
	}
	if v, ok := c.bloques[id]; ok {
		return v
	}
	nombre := ""
	if b, err := c.svc.bloqueRepo.FindByID(ctx, id); err == nil && b != nil {
		nombre = b.Nombre
	}
	c.bloques[id] = nombre
	return nombre
}
