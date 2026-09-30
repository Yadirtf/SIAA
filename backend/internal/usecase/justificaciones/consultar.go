package justificaciones

import (
	"context"

	"github.com/siaa/backend/internal/domain/justificacion"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/repository"
)

// FiltroListado son los criterios de la bandeja de justificaciones.
type FiltroListado struct {
	DocenteID  string
	Estado     justificacion.Estado
	Tipo       justificacion.Tipo
	FechaDesde string
	FechaHasta string
	Pagina     int64
	Limite     int64
}

// Listar devuelve las justificaciones visibles para el actor: las propias para el docente,
// las de su ámbito para el coordinador y todas para los roles globales (RF-ROL-003).
func (s *Service) Listar(ctx context.Context, actor Actor, f FiltroListado) ([]*justificacion.Justificacion, int64, error) {
	if f.Pagina < 1 {
		f.Pagina = 1
	}
	if f.Limite <= 0 || f.Limite > 200 {
		f.Limite = 50
	}
	filtro := repository.FiltroJustificaciones{
		DocenteID:  f.DocenteID,
		Estado:     f.Estado,
		Tipo:       f.Tipo,
		FechaDesde: f.FechaDesde,
		FechaHasta: f.FechaHasta,
		Alcance:    repository.FiltroDeAlcance(actor.Alcance),
	}
	if actor.Alcance.SoloPropios {
		filtro.DocenteID = actor.UsuarioID
	}
	return s.justificaciones.Listar(ctx, filtro, (f.Pagina-1)*f.Limite, f.Limite)
}

// Obtener devuelve el detalle si está dentro del alcance del actor.
func (s *Service) Obtener(ctx context.Context, actor Actor, id string) (*justificacion.Justificacion, error) {
	j, err := s.justificaciones.ObtenerPorID(ctx, id)
	if err != nil {
		return nil, err
	}
	if j == nil {
		return nil, shared.NewNotFoundError("justificación", id)
	}
	if !actor.Alcance.PermiteRegistroDe(j.DocenteID, j.FacultadID, j.SedeID) {
		return nil, shared.NewScopeError()
	}
	return j, nil
}
