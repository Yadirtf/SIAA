package marcaje

import (
	"context"
	"math"
	"time"

	"github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/repository"
)

// WithGrupoEstudiantes permite que un estudiante consulte las sesiones de sus grupos (US-MAR-13).
func (uc *SesionActivaUseCase) WithGrupoEstudiantes(r repository.GrupoEstudiantesRepository) *SesionActivaUseCase {
	uc.grupoEstRepo = r
	return uc
}

// sesionesComoEstudiante devuelve las sesiones de hoy de los grupos que integra el usuario.
func (uc *SesionActivaUseCase) sesionesComoEstudiante(ctx context.Context, usuarioID, fecha string) ([]*academico.Sesion, error) {
	if uc.grupoEstRepo == nil {
		return nil, nil
	}
	grupos, err := uc.grupoEstRepo.GruposDeEstudiante(ctx, usuarioID)
	if err != nil || len(grupos) == 0 {
		return nil, err
	}
	return uc.sesionRepo.List(ctx, repository.SesionFilter{GrupoIDs: grupos, Fecha: fecha})
}

// sesionActivaEstudiante elige la sesión que ve el estudiante: la que tiene la ventana
// estudiantil abierta; si no, la que está en curso (esperando a que el docente la abra); si
// no, la próxima del día.
func (uc *SesionActivaUseCase) sesionActivaEstudiante(ctx context.Context, usuarioID string, sesiones []*academico.Sesion, ahora time.Time) (*DetalleSesionActiva, error) {
	var elegida *academico.Sesion
	var ventana VentanaDTO
	prioridad := 0
	minFuturo := math.MaxFloat64
	for _, s := range sesiones {
		if s.Estado() == academico.EstadoSesionCancelada || s.Estado() == academico.EstadoSesionExcluida {
			continue
		}
		switch {
		case s.VentanaEstudiantilVigente(ahora):
			v := s.VentanaEstudiantil()
			elegida, prioridad = s, 3
			ventana = VentanaDTO{AbreEn: v.AbiertaEn, CierraEn: v.CierraEn, Estado: "ABIERTA"}
		case prioridad < 3 && !ahora.Before(s.VentanaEntradaAbre()) && !ahora.After(s.FinProgramado()):
			elegida, prioridad = s, 2
			ventana = ventanaEstudiantilNoVigente(s, ahora)
		case prioridad < 2 && s.InicioProgramado().After(ahora):
			if delta := s.InicioProgramado().Sub(ahora).Seconds(); delta < minFuturo {
				minFuturo = delta
				elegida, prioridad = s, 1
				ventana = VentanaDTO{AbreEn: s.InicioProgramado(), CierraEn: s.FinProgramado(), Estado: "NO_ABIERTA",
					MinutosParaAbrir: int(math.Ceil(s.InicioProgramado().Sub(ahora).Minutes()))}
			}
		}
	}
	if elegida == nil {
		return &DetalleSesionActiva{HoraServidor: ahora}, nil
	}
	return uc.construirDetalle(ctx, elegida, ventana, usuarioID, ahora)
}

// ventanaEstudiantilNoVigente describe una sesión en curso cuyo marcaje estudiantil está
// pendiente de abrir o ya se cerró.
func ventanaEstudiantilNoVigente(s *academico.Sesion, ahora time.Time) VentanaDTO {
	if v := s.VentanaEstudiantil(); v != nil && !ahora.Before(v.AbiertaEn) {
		return VentanaDTO{AbreEn: v.AbiertaEn, CierraEn: v.CierraEn, Estado: "CERRADA"}
	}
	return VentanaDTO{AbreEn: s.InicioProgramado(), CierraEn: s.FinProgramado(), Estado: "NO_ABIERTA"}
}

// VentanaEstudiantilDTO informa al docente y al estudiante el estado de la ventana del grupo.
type VentanaEstudiantilDTO struct {
	Abierta   bool      `json:"abierta"`
	AbiertaEn time.Time `json:"abiertaEn"`
	CierraEn  time.Time `json:"cierraEn"`
}

func ventanaEstudiantilDTO(s *academico.Sesion, ahora time.Time) *VentanaEstudiantilDTO {
	v := s.VentanaEstudiantil()
	if v == nil {
		return nil
	}
	return &VentanaEstudiantilDTO{Abierta: s.VentanaEstudiantilVigente(ahora), AbiertaEn: v.AbiertaEn, CierraEn: v.CierraEn}
}
