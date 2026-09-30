// Package repository — interfaz de persistencia para el motor de marcajes.
// Satisface US-MAR-04, US-MAR-05, US-MAR-07, US-MAR-08, US-MAR-09, US-MAR-10.
package repository

import (
	"context"
	"errors"
	"time"

	"github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/domain/marcaje"
)

// ErrMarcajeYaAjustado indica que el marcaje ya fue reemplazado por un ajuste previo.
var ErrMarcajeYaAjustado = errors.New("el marcaje ya fue ajustado")

// ErrRanuraOcupada indica que la sesión ya tiene otro marcaje consolidado del mismo tipo.
var ErrRanuraOcupada = errors.New("la sesión ya tiene un marcaje consolidado de ese tipo")

// FiltrosMarcaje define los criterios de búsqueda administrativa para marcajes.
type FiltrosMarcaje struct {
	SesionID  string
	UsuarioID string
	EspacioID string
	Resultado marcaje.ResultadoMarcaje
	Tipo      marcaje.TipoMarcaje
	Origen    marcaje.OrigenMarcaje
	Desde     *time.Time
	Hasta     *time.Time
	Anulado   *bool
	Alcance   *FiltroAlcance
}

// MarcajeRepository define el contrato de persistencia inmutable y consultas de marcaje.
type MarcajeRepository interface {
	Crear(ctx context.Context, m *marcaje.Marcaje) error
	ObtenerPorID(ctx context.Context, id string) (*marcaje.Marcaje, error)
	ObtenerPrevio(ctx context.Context, sesionID, usuarioID string, tipo marcaje.TipoMarcaje) (*marcaje.Marcaje, error)
	ListarPorUsuario(ctx context.Context, usuarioID string, mes string, skip, limit int64) ([]*marcaje.Marcaje, int64, error)
	ListarConFiltros(ctx context.Context, filtros FiltrosMarcaje, skip, limit int64) ([]*marcaje.Marcaje, int64, error)
	// RegistrarAjuste inserta el evento de ajuste y marca al original como reemplazado sin
	// alterar sus datos (RF-JUS-004). Devuelve ErrMarcajeYaAjustado o ErrRanuraOcupada.
	RegistrarAjuste(ctx context.Context, originalID string, ajuste *marcaje.Marcaje) error
	// ListarConsolidados devuelve los marcajes vigentes de un lote de sesiones (EP-08).
	ListarConsolidados(ctx context.Context, sesionIDs []string, tipo marcaje.TipoMarcaje) ([]*marcaje.Marcaje, error)
	ObtenerSesionesExpiradasSinMarcaje(ctx context.Context, ahora time.Time) ([]*academico.Sesion, error)
	ObtenerUltimoMarcajeUsuario(ctx context.Context, usuarioID string) (*marcaje.Marcaje, error)
	RevertirAusenciaPorOffline(ctx context.Context, sesionID, usuarioID string, nuevoMarcaje *marcaje.Marcaje) error
}
