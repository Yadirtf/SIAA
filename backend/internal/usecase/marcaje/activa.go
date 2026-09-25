// Package marcaje — caso de uso para consulta de sesión activa y sesiones del día.
// Satisface US-MAR-01 (AC-01..AC-07), T-MAR-01.1, T-MAR-01.2, T-MAR-01.3.
package marcaje

import (
	"context"
	"math"
	"time"

	"github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/domain/geo"
	domainMarcaje "github.com/siaa/backend/internal/domain/marcaje"
	"github.com/siaa/backend/internal/repository"
)

// DetalleSesionActiva representa el DTO de respuesta para GET /me/sesiones/activa (§9.5).
type DetalleSesionActiva struct {
	Sesion                            *SesionItemDTO         `json:"sesion"`
	Ventana                           VentanaDTO             `json:"ventana"`
	Parametros                        map[string]interface{} `json:"parametros"`
	GeometriaBuffer                   *geo.GeoJSONPolygon    `json:"geometriaBuffer,omitempty"`
	VerificacionComplementariaExigida bool                   `json:"verificacionComplementariaExigida"`
	MarcajeExistente                  *domainMarcaje.Marcaje `json:"marcajeExistente"`
	HoraServidor                      time.Time              `json:"horaServidor"`
}

type SesionItemDTO struct {
	ID               string         `json:"id"`
	Asignatura       string         `json:"asignatura"`
	Grupo            string         `json:"grupo"`
	Espacio          EspacioItemDTO `json:"espacio"`
	InicioProgramado time.Time      `json:"inicioProgramado"`
	FinProgramado    time.Time      `json:"finProgramado"`
	Modalidad        string         `json:"modalidad"`
}

type EspacioItemDTO struct {
	ID     string `json:"id"`
	Codigo string `json:"codigo"`
	Nombre string `json:"nombre"`
}

type VentanaDTO struct {
	AbreEn           time.Time `json:"abreEn"`
	CierraEn         time.Time `json:"cierraEn"`
	Estado           string    `json:"estado"` // ABIERTA, NO_ABIERTA, CERRADA
	MinutosParaAbrir int       `json:"minutosParaAbrir,omitempty"`
}

type ResumenSesionHoy struct {
	SesionID         string                 `json:"sesionId"`
	Asignatura       string                 `json:"asignatura"`
	Grupo            string                 `json:"grupo"`
	EspacioCodigo    string                 `json:"espacioCodigo"`
	InicioProgramado time.Time              `json:"inicioProgramado"`
	FinProgramado    time.Time              `json:"finProgramado"`
	Estado           string                 `json:"estado"`
	MarcajeEntrada   *domainMarcaje.Marcaje `json:"marcajeEntrada,omitempty"`
	MarcajeSalida    *domainMarcaje.Marcaje `json:"marcajeSalida,omitempty"`
}

// SesionActivaUseCase gestiona la consulta de la sesión marcable y la regla de desempate.
type SesionActivaUseCase struct {
	sesionRepo  repository.SesionRepository
	espacioRepo repository.EspacioRepository
	marcajeRepo repository.MarcajeRepository
}

func NewSesionActivaUseCase(
	sesionRepo repository.SesionRepository,
	espacioRepo repository.EspacioRepository,
	marcajeRepo repository.MarcajeRepository,
) *SesionActivaUseCase {
	return &SesionActivaUseCase{
		sesionRepo:  sesionRepo,
		espacioRepo: espacioRepo,
		marcajeRepo: marcajeRepo,
	}
}

// ObtenerSesionActiva resuelve la sesión marcable ahora con regla de desempate (T-MAR-01.1, T-MAR-01.3).
func (uc *SesionActivaUseCase) ObtenerSesionActiva(ctx context.Context, docenteID string, ahora time.Time) (*DetalleSesionActiva, error) {
	if ahora.IsZero() {
		ahora = time.Now().UTC()
	}
	fechaHoy := ahora.Format("2006-01-02")

	sesiones, err := uc.sesionRepo.ListByDocenteYFecha(ctx, docenteID, fechaHoy)
	if err != nil {
		return nil, err
	}

	var sesionActiva *academico.Sesion
	var ventanaActiva VentanaDTO
	minDiff := math.MaxFloat64

	// 1. Buscar sesión cuya ventana esté actualmente ABIERTA
	for _, s := range sesiones {
		if s.Estado() == academico.EstadoSesionCancelada || s.Estado() == academico.EstadoSesionExcluida {
			continue
		}
		abre := s.VentanaEntradaAbre()
		cierra := s.VentanaEntradaCierra()

		if (ahora.Equal(abre) || ahora.After(abre)) && (ahora.Equal(cierra) || ahora.Before(cierra)) {
			// Regla de desempate cuando se solapan dos ventanas: gana el inicio más próximo a ahora (T-MAR-01.3)
			diff := math.Abs(ahora.Sub(s.InicioProgramado()).Seconds())
			if diff < minDiff {
				minDiff = diff
				sesionActiva = s
				ventanaActiva = VentanaDTO{
					AbreEn:   abre,
					CierraEn: cierra,
					Estado:   "ABIERTA",
				}
			}
		}
	}

	// 2. Si no hay ventana abierta en este momento, buscar la próxima sesión del día (AC-02, T-MAR-01.7)
	if sesionActiva == nil {
		var proximaSesion *academico.Sesion
		minFuturo := math.MaxFloat64

		for _, s := range sesiones {
			if s.Estado() == academico.EstadoSesionCancelada || s.Estado() == academico.EstadoSesionExcluida {
				continue
			}
			abre := s.VentanaEntradaAbre()
			if abre.After(ahora) {
				delta := abre.Sub(ahora).Seconds()
				if delta < minFuturo {
					minFuturo = delta
					proximaSesion = s
				}
			}
		}

		if proximaSesion != nil {
			sesionActiva = proximaSesion
			ventanaActiva = VentanaDTO{
				AbreEn:           proximaSesion.VentanaEntradaAbre(),
				CierraEn:         proximaSesion.VentanaEntradaCierra(),
				Estado:           "NO_ABIERTA",
				MinutosParaAbrir: int(math.Ceil(proximaSesion.VentanaEntradaAbre().Sub(ahora).Minutes())),
			}
		}
	}

	if sesionActiva == nil {
		return &DetalleSesionActiva{
			Sesion:       nil,
			HoraServidor: ahora,
		}, nil
	}

	return uc.construirDetalle(ctx, sesionActiva, ventanaActiva, docenteID, ahora)
}

func (uc *SesionActivaUseCase) construirDetalle(ctx context.Context, s *academico.Sesion, ventana VentanaDTO, docenteID string, ahora time.Time) (*DetalleSesionActiva, error) {
	codigoEspacio := "Aula"
	nombreEspacio := "Aula Asignada"
	var geoBuffer *geo.GeoJSONPolygon

	if s.GeometriaBufferSnapshot() != nil {
		polyJSON := s.GeometriaBufferSnapshot().ToGeoJSON()
		geoBuffer = &polyJSON
	}

	if s.EspacioID() != "" {
		esp, errEsp := uc.espacioRepo.FindByID(ctx, s.EspacioID())
		if errEsp == nil && esp != nil {
			codigoEspacio = esp.Codigo
			nombreEspacio = esp.Nombre
			if geoBuffer == nil && esp.GeometriaBuffer != nil {
				polyJSON := esp.GeometriaBuffer.ToGeoJSON()
				geoBuffer = &polyJSON
			}
		}
	}

	// Consultar si ya existe marcaje de entrada para esta sesión y docente
	previo, _ := uc.marcajeRepo.ObtenerPrevio(ctx, s.ID(), docenteID, domainMarcaje.TipoEntrada)

	params := map[string]interface{}{
		"precisionGpsMaxMetros": 35.0,
		"umbralTardanzaMin":     10,
	}

	return &DetalleSesionActiva{
		Sesion: &SesionItemDTO{
			ID:         s.ID(),
			Asignatura: s.AsignaturaID(),
			Grupo:      s.GrupoID(),
			Espacio: EspacioItemDTO{
				ID:     s.EspacioID(),
				Codigo: codigoEspacio,
				Nombre: nombreEspacio,
			},
			InicioProgramado: s.InicioProgramado(),
			FinProgramado:    s.FinProgramado(),
			Modalidad:        "PRESENCIAL",
		},
		Ventana:          ventana,
		Parametros:       params,
		GeometriaBuffer:  geoBuffer,
		MarcajeExistente: previo,
		HoraServidor:     ahora,
	}, nil
}

// ListarSesionesHoy retorna todas las sesiones del docente para la fecha actual (T-MAR-01.2).
func (uc *SesionActivaUseCase) ListarSesionesHoy(ctx context.Context, docenteID string, ahora time.Time) ([]ResumenSesionHoy, error) {
	if ahora.IsZero() {
		ahora = time.Now().UTC()
	}
	fechaHoy := ahora.Format("2006-01-02")

	sesiones, err := uc.sesionRepo.ListByDocenteYFecha(ctx, docenteID, fechaHoy)
	if err != nil {
		return nil, err
	}

	resultado := make([]ResumenSesionHoy, 0, len(sesiones))
	for _, s := range sesiones {
		codigoEspacio := "Aula"
		if s.EspacioID() != "" {
			if esp, errEsp := uc.espacioRepo.FindByID(ctx, s.EspacioID()); errEsp == nil && esp != nil {
				codigoEspacio = esp.Codigo
			}
		}

		mEntrada, _ := uc.marcajeRepo.ObtenerPrevio(ctx, s.ID(), docenteID, domainMarcaje.TipoEntrada)
		mSalida, _ := uc.marcajeRepo.ObtenerPrevio(ctx, s.ID(), docenteID, domainMarcaje.TipoSalida)

		resultado = append(resultado, ResumenSesionHoy{
			SesionID:         s.ID(),
			Asignatura:       s.AsignaturaID(),
			Grupo:            s.GrupoID(),
			EspacioCodigo:    codigoEspacio,
			InicioProgramado: s.InicioProgramado(),
			FinProgramado:    s.FinProgramado(),
			Estado:           string(s.Estado()),
			MarcajeEntrada:   mEntrada,
			MarcajeSalida:    mSalida,
		})
	}

	return resultado, nil
}
