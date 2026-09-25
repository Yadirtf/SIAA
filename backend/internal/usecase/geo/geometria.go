// Package geo — casos de uso para gestión de geometrías, versiones y solapamientos.
// Satisface US-GEO-04, US-GEO-05, US-GEO-06 (AC-01..AC-05), US-GEO-08 (AC-01..AC-03), US-GEO-09 (AC-01..AC-03).
package geo

import (
	"context"
	"fmt"

	"github.com/siaa/backend/internal/domain/geo"
	"github.com/siaa/backend/internal/domain/shared"
	applog "github.com/siaa/backend/internal/platform/log"
	"github.com/siaa/backend/internal/repository"
)

// GuardarGeometriaEspacio valida el polígono (o centroide+radio), detecta solapamientos en el mismo
// bloque y piso, precalcula el buffer perimetral, archiva la versión previa inmutable y actualiza el espacio.
func (s *Service) GuardarGeometriaEspacio(ctx context.Context, cmd GuardarGeometriaCmd) (*geo.Espacio, error) {
	espacio, err := s.espacioRepo.FindByID(ctx, cmd.EspacioID)
	if err != nil {
		return nil, fmt.Errorf("obtener espacio para geometría: %w", err)
	}
	if espacio == nil {
		return nil, shared.NewNotFoundError("Espacio", cmd.EspacioID)
	}

	var poly geo.GeoPolygon
	// US-GEO-09 AC-01: Generación a partir de centroide + radio
	if cmd.MetodoCaptura == geo.MetodoCentroideRadio {
		if cmd.Centroide == nil || cmd.RadioMetros == nil || *cmd.RadioMetros <= 0 {
			return nil, shared.NewValidationError(
				"Se requiere centroide y radio mayor a cero para el método CENTROIDE_RADIO",
				shared.FieldError{Campo: "radioMetros", Error: "CENTROIDE_RADIO_REQUERIDO"},
			)
		}
		p, errGen := geo.GenerarPoligonoCentroideRadio(*cmd.Centroide, *cmd.RadioMetros, 32)
		if errGen != nil {
			return nil, errGen
		}
		poly = p
		espacio.RadioMetros = cmd.RadioMetros
	} else {
		p, errPoly := geo.NewGeoPolygon(cmd.Vertices)
		if errPoly != nil {
			return nil, errPoly
		}
		poly = p
	}

	// T-GEO-05.1, AC-05: Buscar intersecciones espaciales en el mismo bloque y piso
	intersecciones, err := s.espacioRepo.BuscarIntersecciones(ctx, espacio.ID, espacio.BloqueID, espacio.Piso, poly)
	if err != nil {
		return nil, fmt.Errorf("verificar intersecciones de espacio: %w", err)
	}

	var advertencias []geo.SolapamientoEspacio
	for _, otro := range intersecciones {
		if otro.Geometria == nil {
			continue
		}
		areaInter, pct := geo.CalcularAreaSolapadaGeodesica(poly, *otro.Geometria)
		if pct > 0.01 {
			bloquea := pct > 50.0
			advertencias = append(advertencias, geo.SolapamientoEspacio{
				EspacioID:          otro.ID,
				EspacioCodigo:      otro.Codigo,
				EspacioNombre:      otro.Nombre,
				AreaSolapadaM2:     areaInter,
				PorcentajeSolapado: pct,
				BloqueaGuardado:    bloquea,
			})
		}
	}

	if len(advertencias) > 0 {
		for _, adv := range advertencias {
			if adv.BloqueaGuardado {
				return nil, &shared.DomainError{
					Code:    shared.ErrGeometriaSolapada,
					Message: fmt.Sprintf("Solapamiento crítico del %.2f%% detectado con el espacio '%s' (%s). Supera el 50%%.", adv.PorcentajeSolapado, adv.EspacioNombre, adv.EspacioCodigo),
					Fields: []shared.FieldError{
						{
							Campo: "geometria",
							Error: fmt.Sprintf("solapamiento_bloqueado_%.2f_pct_con_%s", adv.PorcentajeSolapado, adv.EspacioCodigo),
						},
					},
				}
			}
		}

		if !cmd.ConfirmarSolapamiento {
			fields := make([]shared.FieldError, 0, len(advertencias))
			for _, adv := range advertencias {
				fields = append(fields, shared.FieldError{
					Campo: "confirmarSolapamiento",
					Error: fmt.Sprintf("solapamiento_detectado: %.2f%% con '%s' (%s)", adv.PorcentajeSolapado, adv.EspacioNombre, adv.EspacioCodigo),
				})
			}
			return nil, &shared.DomainError{
				Code:    shared.ErrValidacion,
				Message: fmt.Sprintf("Se detectó solapamiento con %d espacio(s). Requiere confirmación explícita.", len(advertencias)),
				Fields:  fields,
			}
		}
	}

	valorAnterior := *espacio

	// US-GEO-06 AC-01: archivar versión previa en histórico inmutable
	if s.histRepo != nil && valorAnterior.Geometria != nil && valorAnterior.VersionGeometria > 0 {
		hist, err := geo.NewEspacioGeometriaHist(&valorAnterior, cmd.Actor.ActorID, cmd.MotivoSolapamiento, s.clk.Now())
		if err == nil {
			if errHist := s.histRepo.Create(ctx, hist); errHist != nil {
				s.log.Warn("no se pudo archivar versión histórica de geometría", applog.Err(errHist))
			}
		}
	}

	if err := espacio.AsignarGeometria(poly, cmd.MetodoCaptura, cmd.PrecisionPromedioMetros); err != nil {
		return nil, err
	}

	if err := s.espacioRepo.Update(ctx, espacio); err != nil {
		return nil, fmt.Errorf("guardar geometria espacio: %w", err)
	}

	if len(advertencias) > 0 && cmd.ConfirmarSolapamiento {
		s.auditar(ctx, "espacio", espacio.ID, "GEOMETRIA_SOLAPADA_CONFIRMADA", cmd.Actor, valorAnterior, map[string]interface{}{
			"espacio":       espacio,
			"motivo":        cmd.MotivoSolapamiento,
			"solapamientos": advertencias,
		})
	} else {
		s.auditar(ctx, "espacio", espacio.ID, "GEOMETRIA_ACTUALIZADA", cmd.Actor, valorAnterior, espacio)
	}

	return espacio, nil
}

// ListarVersionesGeometria implementa AC-04 de US-GEO-06.
func (s *Service) ListarVersionesGeometria(ctx context.Context, espacioID string) ([]*geo.EspacioGeometriaHist, error) {
	espacio, err := s.espacioRepo.FindByID(ctx, espacioID)
	if err != nil {
		return nil, fmt.Errorf("obtener espacio para historial: %w", err)
	}
	if espacio == nil {
		return nil, shared.NewNotFoundError("Espacio", espacioID)
	}

	if s.histRepo == nil {
		return []*geo.EspacioGeometriaHist{}, nil
	}

	return s.histRepo.ListByEspacioID(ctx, espacioID)
}

// ObtenerVersionGeometria implementa AC-03 de US-GEO-06.
func (s *Service) ObtenerVersionGeometria(ctx context.Context, espacioID string, version int) (*geo.EspacioGeometriaHist, error) {
	espacio, err := s.espacioRepo.FindByID(ctx, espacioID)
	if err != nil {
		return nil, fmt.Errorf("obtener espacio para version histórica: %w", err)
	}
	if espacio == nil {
		return nil, shared.NewNotFoundError("Espacio", espacioID)
	}

	if s.histRepo == nil {
		return nil, shared.NewNotFoundError("VersionGeometria", fmt.Sprintf("%s_v%d", espacioID, version))
	}

	hist, err := s.histRepo.FindByEspacioIDAndVersion(ctx, espacioID, version)
	if err != nil {
		return nil, fmt.Errorf("buscar version geometria: %w", err)
	}
	if hist == nil {
		if espacio.VersionGeometria == version && espacio.Geometria != nil {
			return geo.NewEspacioGeometriaHist(espacio, "actual", "", espacio.ActualizadoEn)
		}
		return nil, shared.NewNotFoundError("VersionGeometria", fmt.Sprintf("%s_v%d", espacioID, version))
	}
	return hist, nil
}

// GenerarInformeSolapamientos implementa AC-04, T-GEO-05.3.
func (s *Service) GenerarInformeSolapamientos(ctx context.Context, sedeID, bloqueID string) ([]ItemInformeSolapamiento, error) {
	filter := repository.EspacioFilter{
		SedeID:   sedeID,
		BloqueID: bloqueID,
	}
	espacios, err := s.espacioRepo.List(ctx, filter)
	if err != nil {
		return nil, fmt.Errorf("listar espacios para informe: %w", err)
	}

	var informe []ItemInformeSolapamiento
	n := len(espacios)
	for i := 0; i < n; i++ {
		e1 := espacios[i]
		if !e1.Activo || e1.Eliminado || e1.Geometria == nil {
			continue
		}
		for j := i + 1; j < n; j++ {
			e2 := espacios[j]
			if !e2.Activo || e2.Eliminado || e2.Geometria == nil {
				continue
			}
			if !mismoBloqueYPiso(e1, e2) {
				continue
			}

			areaInter, pct := geo.CalcularAreaSolapadaGeodesica(*e1.Geometria, *e2.Geometria)
			if pct > 0.01 {
				informe = append(informe, ItemInformeSolapamiento{
					SedeID:             e1.SedeID,
					BloqueID:           e1.BloqueID,
					Piso:               e1.Piso,
					Espacio1ID:         e1.ID,
					Espacio1Codigo:     e1.Codigo,
					Espacio1Nombre:     e1.Nombre,
					Espacio2ID:         e2.ID,
					Espacio2Codigo:     e2.Codigo,
					Espacio2Nombre:     e2.Nombre,
					AreaSolapadaM2:     areaInter,
					PorcentajeSolapado: pct,
					EsCritico:          pct > 50.0,
				})
			}
		}
	}
	return informe, nil
}

func mismoBloqueYPiso(e1, e2 *geo.Espacio) bool {
	if (e1.BloqueID == nil && e2.BloqueID != nil) || (e1.BloqueID != nil && e2.BloqueID == nil) {
		return false
	}
	if e1.BloqueID != nil && e2.BloqueID != nil && *e1.BloqueID != *e2.BloqueID {
		return false
	}
	if (e1.Piso == nil && e2.Piso != nil) || (e1.Piso != nil && e2.Piso == nil) {
		return false
	}
	if e1.Piso != nil && e2.Piso != nil && *e1.Piso != *e2.Piso {
		return false
	}
	return true
}
