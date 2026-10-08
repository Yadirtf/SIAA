package academico

import (
	"context"
	"fmt"

	domainAca "github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/domain/shared"
)

// aplicarPlanes crea los grupos faltantes y las asignaciones del lote. Si una escritura
// falla, revierte (borrado lógico) todo lo creado para que la carga no quede a medias (AC-03).
func (s *Service) aplicarPlanes(ctx context.Context, planes []*planFila) (int, int, error) {
	var asignaciones, grupos []string
	revertir := func(causa error, fila int) (int, int, error) {
		for _, id := range asignaciones {
			_ = s.asignacionRepo.DeleteLogico(ctx, id)
		}
		for _, id := range grupos {
			_ = s.estructuraRepo.DeleteGrupoLogico(ctx, id)
		}
		return 0, 0, fmt.Errorf("carga revertida por error en la fila %d: %w", fila, causa)
	}
	nuevos := map[string]string{}
	ahora := s.clk.Now()
	for _, p := range planes {
		grupoID := ""
		if p.grupo != nil {
			grupoID = p.grupo.ID()
		} else if id, ok := nuevos[p.claveGrupo()]; ok {
			grupoID = id
		} else {
			g, err := domainAca.NuevoGrupo(shared.NewID(), p.fila.GrupoCodigo, p.asignatura.ID(), p.periodo.ID(), 0, nil, ahora)
			if err != nil {
				return revertir(err, p.fila.NumeroFila)
			}
			if err := s.estructuraRepo.CreateGrupo(ctx, g); err != nil {
				return revertir(err, p.fila.NumeroFila)
			}
			grupoID = g.ID()
			nuevos[p.claveGrupo()] = grupoID
			grupos = append(grupos, grupoID)
		}
		a := p.asignacion
		asig, err := domainAca.NuevaAsignacion(a.ID(), a.PeriodoID(), a.DocenteIDs(), a.DocenteNombre(), grupoID,
			a.AsignaturaID(), a.FacultadID(), a.EspacioID(), a.EspacioNombre(), a.Franja(), a.Modalidad(),
			nil, a.FechaInicio(), a.FechaFin(), nil, ahora)
		if err != nil {
			return revertir(err, p.fila.NumeroFila)
		}
		if err := s.asignacionRepo.Create(ctx, asig); err != nil {
			return revertir(err, p.fila.NumeroFila)
		}
		asignaciones = append(asignaciones, asig.ID())
	}
	return len(asignaciones), len(grupos), nil
}
