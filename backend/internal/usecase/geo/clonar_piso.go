// Package geo — caso de uso para clonar geometría de espacios entre pisos (US-GEO-12).
// Satisface US-GEO-12 (AC-01..AC-03), RF-GEO-015 y mitigación R-01.
package geo

import (
	"context"
	"fmt"
	"strings"

	"github.com/siaa/backend/internal/domain/geo"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/repository"
)

// ClonarPisoCmd define los parámetros requeridos para clonar los espacios de un piso a otro.
type ClonarPisoCmd struct {
	BloqueID      string        `json:"bloqueId"`
	PisoOrigen    int           `json:"pisoOrigen"`
	PisoDestino   int           `json:"pisoDestino"`
	PrefijoCodigo string        `json:"prefijoCodigo,omitempty"` // Opcional: sustitución de prefijo
	Actor         ContextoActor `json:"-"`
}

// ResultadoClonarPisoDTO contiene el resumen de la operación de clonación.
type ResultadoClonarPisoDTO struct {
	EspaciosClonados int      `json:"espaciosClonados"`
	CodigosCreados   []string `json:"codigosCreados"`
	PisoOrigen       int      `json:"pisoOrigen"`
	PisoDestino      int      `json:"pisoDestino"`
	Mensaje          string   `json:"mensaje"`
}

// ClonarPiso clona todos los espacios activos del piso origen al piso destino dentro del mismo bloque (US-GEO-12).
func (s *Service) ClonarPiso(ctx context.Context, cmd ClonarPisoCmd) (*ResultadoClonarPisoDTO, error) {
	if cmd.PisoOrigen == cmd.PisoDestino {
		return nil, shared.NewValidationError(
			"El piso de destino debe ser diferente al piso de origen",
			shared.FieldError{Campo: "pisoDestino", Error: "PISO_DESTINO_IGUAL_ORIGEN"},
		)
	}

	bloque, err := s.bloqueRepo.FindByID(ctx, cmd.BloqueID)
	if err != nil || bloque == nil {
		return nil, shared.NewNotFoundError("Bloque", cmd.BloqueID)
	}

	// Obtener espacios activos del piso de origen
	pisoOrig := cmd.PisoOrigen
	espaciosOrigen, err := s.espacioRepo.List(ctx, repository.EspacioFilter{
		BloqueID: cmd.BloqueID,
		Piso:     &pisoOrig,
	})
	if err != nil {
		return nil, fmt.Errorf("consultar espacios origen: %w", err)
	}

	if len(espaciosOrigen) == 0 {
		return nil, shared.NewValidationError(
			fmt.Sprintf("No se encontraron espacios activos en el piso %d del bloque", cmd.PisoOrigen),
			shared.FieldError{Campo: "pisoOrigen", Error: "SIN_ESPACIOS_ORIGEN"},
		)
	}

	// Pre-calcular y validar los nuevos códigos para evitar colisiones parciales (AC-02)
	nuevosCodigos := make([]string, len(espaciosOrigen))
	origStr := fmt.Sprintf("%d", cmd.PisoOrigen)
	destStr := fmt.Sprintf("%d", cmd.PisoDestino)

	for i, esp := range espaciosOrigen {
		var nuevoCod string
		if cmd.PrefijoCodigo != "" {
			nuevoCod = fmt.Sprintf("%s-%s", cmd.PrefijoCodigo, esp.Codigo)
		} else if strings.Contains(esp.Codigo, origStr) {
			nuevoCod = strings.Replace(esp.Codigo, origStr, destStr, 1)
		} else {
			nuevoCod = fmt.Sprintf("%s-P%d", esp.Codigo, cmd.PisoDestino)
		}

		// Validar si el código ya existe
		existente, errFind := s.espacioRepo.FindByCodigo(ctx, nuevoCod)
		if errFind != nil {
			return nil, fmt.Errorf("verificar colision de codigo: %w", errFind)
		}
		if existente != nil {
			return nil, shared.NewValidationError(
				fmt.Sprintf("Colisión de código: el espacio '%s' ya existe en el sistema", nuevoCod),
				shared.FieldError{Campo: "codigo", Error: "CODIGO_DUPLICADO"},
			)
		}
		nuevosCodigos[i] = nuevoCod
	}

	// Clonar y persistir cada espacio con nueva ID y geometría idéntica
	now := s.clk.Now()
	clonados := make([]*geo.Espacio, 0, len(espaciosOrigen))
	codigosCreados := make([]string, 0, len(espaciosOrigen))

	for i, espOrig := range espaciosOrigen {
		pisoDest := cmd.PisoDestino
		nuevoEspacio := &geo.Espacio{
			SedeID:                  espOrig.SedeID,
			Torre:                   espOrig.Torre,
			BloqueID:                espOrig.BloqueID,
			Piso:                    &pisoDest,
			Codigo:                  nuevosCodigos[i],
			Nombre:                  strings.Replace(espOrig.Nombre, fmt.Sprintf("Piso %d", cmd.PisoOrigen), fmt.Sprintf("Piso %d", cmd.PisoDestino), 1),
			Capacidad:               espOrig.Capacidad,
			Tipo:                    espOrig.Tipo,
			FacultadResponsable:     espOrig.FacultadResponsable,
			Estado:                  geo.EstadoActivo,
			NivelValidacion:         espOrig.NivelValidacion,
			BufferMetros:            espOrig.BufferMetros,
			Geometria:               espOrig.Geometria,
			GeometriaBuffer:         espOrig.GeometriaBuffer,
			RadioMetros:             espOrig.RadioMetros,
			AreaMetrosCuadrados:     espOrig.AreaMetrosCuadrados,
			Centroide:               espOrig.Centroide,
			PrecisionPromedioMetros: espOrig.PrecisionPromedioMetros,
			MetodoCaptura:           espOrig.MetodoCaptura,
			VersionGeometria:        1,
			Activo:                  true,
			Eliminado:               false,
			CreadoEn:                now,
			ActualizadoEn:           now,
		}

		if err := s.espacioRepo.Create(ctx, nuevoEspacio); err != nil {
			return nil, fmt.Errorf("crear espacio clonado '%s': %w", nuevoEspacio.Codigo, err)
		}
		clonados = append(clonados, nuevoEspacio)
		codigosCreados = append(codigosCreados, nuevoEspacio.Codigo)
	}

	// Registrar auditoría de la clonación
	s.auditar(ctx, "bloque", cmd.BloqueID, "PISO_CLONADO", cmd.Actor,
		map[string]interface{}{"pisoOrigen": cmd.PisoOrigen, "total": len(espaciosOrigen)},
		map[string]interface{}{"pisoDestino": cmd.PisoDestino, "clonados": codigosCreados},
	)

	return &ResultadoClonarPisoDTO{
		EspaciosClonados: len(clonados),
		CodigosCreados:   codigosCreados,
		PisoOrigen:       cmd.PisoOrigen,
		PisoDestino:      cmd.PisoDestino,
		Mensaje:          "Clonación de piso completada con éxito. Nota: el GPS no discrimina piso (R-01).",
	}, nil
}
