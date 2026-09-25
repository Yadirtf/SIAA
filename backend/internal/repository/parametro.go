// Package repository — contrato de persistencia para la parametrización jerárquica.
// US-PAR-01, US-PAR-02: ADR-02 (usecase depende de interfaces, no de implementaciones).
package repository

import (
	"context"

	"github.com/siaa/backend/internal/domain/parametro"
)

// ParametroFilter permite filtrar parámetros por ámbito e ID de ámbito.
type ParametroFilter struct {
	Ambito   *parametro.Ambito
	AmbitoID *string
	Clave    *parametro.Clave
}

// ParametroRepository define las operaciones de persistencia para parámetros jerárquicos.
// Toda lógica de resolución y herencia reside en el dominio (cascada.go), nunca aquí.
type ParametroRepository interface {
	// Upsert inserta o actualiza un parámetro para el ámbito+clave dado.
	// Guarda el valor anterior antes de sobreescribir (US-PAR-01 AC-03).
	Upsert(ctx context.Context, p *parametro.Parametro) error

	// ListByAmbito lista todos los parámetros de un nivel+id específico.
	ListByAmbito(ctx context.Context, ambito parametro.Ambito, ambitoID string) ([]*parametro.Parametro, error)

	// FindByAmbitoAndClave busca un parámetro específico por ámbito+clave.
	FindByAmbitoAndClave(ctx context.Context, ambito parametro.Ambito, ambitoID string, clave parametro.Clave) (*parametro.Parametro, error)

	// ListParaCascada devuelve todos los parámetros relevantes para resolver la cascada
	// de una asignación concreta. Filtra por los ámbitos y sus IDs correspondientes.
	ListParaCascada(ctx context.Context, filtros []ParametroFilter) ([]*parametro.Parametro, error)
}
