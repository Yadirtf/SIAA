// Package marcaje — caso de uso para consulta de historial de marcajes.
// Satisface US-MAR-08 (AC-01..AC-05), T-MAR-08.1 y RNF-LEG-004.
package marcaje

import (
	"context"
	"errors"
	"math"

	domainMarcaje "github.com/siaa/backend/internal/domain/marcaje"
	"github.com/siaa/backend/internal/repository"
)

var (
	ErrAccesoHistorialAjeno = errors.New("acceso denegado: no puedes consultar el historial de otro usuario (US-MAR-08 AC-04)")
)

// RespuestaHistorial contiene el listado cronológico inverso y los metadatos de paginación.
type RespuestaHistorial struct {
	Items        []*domainMarcaje.Marcaje `json:"items"`
	Total        int64                    `json:"total"`
	Pagina       int64                    `json:"pagina"`
	Limite       int64                    `json:"limite"`
	TotalPaginas int64                    `json:"totalPaginas"`
}

// HistorialUseCase gestiona la consulta del historial propio con restricción de ámbito.
type HistorialUseCase struct {
	marcajeRepo repository.MarcajeRepository
}

func NewHistorialUseCase(marcajeRepo repository.MarcajeRepository) *HistorialUseCase {
	return &HistorialUseCase{
		marcajeRepo: marcajeRepo,
	}
}

// ConsultarHistorialPropio resuelve el historial paginado asegurando que solo el usuario autenticado acceda a sus datos (AC-04).
func (uc *HistorialUseCase) ConsultarHistorialPropio(ctx context.Context, usuarioAutenticadoID, targetUsuarioID string, mes string, pagina, limite int64) (*RespuestaHistorial, error) {
	// AC-04: Dado un usuario, cuando intenta consultar el historial de otro, recibe 403
	if targetUsuarioID != "" && targetUsuarioID != usuarioAutenticadoID {
		return nil, ErrAccesoHistorialAjeno
	}

	if pagina < 1 {
		pagina = 1
	}
	if limite <= 0 || limite > 100 {
		limite = 20
	}
	skip := (pagina - 1) * limite

	items, total, err := uc.marcajeRepo.ListarPorUsuario(ctx, usuarioAutenticadoID, mes, skip, limite)
	if err != nil {
		return nil, err
	}

	totalPaginas := int64(math.Ceil(float64(total) / float64(limite)))
	if totalPaginas == 0 {
		totalPaginas = 1
	}

	return &RespuestaHistorial{
		Items:        items,
		Total:        total,
		Pagina:       pagina,
		Limite:       limite,
		TotalPaginas: totalPaginas,
	}, nil
}
