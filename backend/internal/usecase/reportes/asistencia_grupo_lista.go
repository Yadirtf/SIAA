package reportes

import (
	"context"
	"sort"
	"strings"

	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/repository"
)

// GrupoVisible es un grupo que el actor puede consultar en el reporte de asistencia.
type GrupoVisible struct {
	GrupoID      string `json:"grupoId"`
	Grupo        string `json:"grupo"`
	AsignaturaID string `json:"asignaturaId"`
	Asignatura   string `json:"asignatura"`
	PeriodoID    string `json:"periodoId"`
}

// GruposVisibles lista los grupos del periodo con sesiones dentro del alcance del actor: los
// propios para el docente y los de su sede o facultad para el coordinador.
func (s *AsistenciaGrupoService) GruposVisibles(ctx context.Context, actor Actor, periodoID string) ([]GrupoVisible, error) {
	if strings.TrimSpace(periodoID) == "" {
		return nil, shared.NewValidationError("indique el periodo (periodoId)")
	}
	sesiones, err := s.sesiones.List(ctx, repository.SesionFilter{
		PeriodoID: periodoID, Alcance: repository.FiltroDeAlcance(actor.Alcance),
	})
	if err != nil {
		return nil, err
	}
	n := nuevosNombres(nil, nil, s.estructura)
	vistos := map[string]bool{}
	res := []GrupoVisible{}
	for _, se := range sesiones {
		if se.GrupoID() == "" || vistos[se.GrupoID()] {
			continue
		}
		vistos[se.GrupoID()] = true
		g := GrupoVisible{GrupoID: se.GrupoID(), Grupo: se.GrupoID(), AsignaturaID: se.AsignaturaID(),
			Asignatura: n.asignatura(ctx, se.AsignaturaID()), PeriodoID: periodoID}
		if gr, err := s.estructura.GetGrupoByID(ctx, se.GrupoID()); err == nil && gr != nil {
			g.Grupo = gr.Numero()
		}
		res = append(res, g)
	}
	sort.SliceStable(res, func(i, j int) bool {
		if res[i].Asignatura != res[j].Asignatura {
			return strings.ToLower(res[i].Asignatura) < strings.ToLower(res[j].Asignatura)
		}
		return res[i].Grupo < res[j].Grupo
	})
	return res, nil
}
