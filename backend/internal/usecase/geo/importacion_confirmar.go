package geo

import (
	"context"
	"fmt"

	"github.com/siaa/backend/internal/domain/geo"
	"github.com/siaa/backend/internal/domain/shared"
)

// ConfirmarImportarGeoJSONCmd contiene los datos para persistir la importación confirmada
// (sirve para GeoJSON y KML: ambos llegan como elementos previsualizados).
type ConfirmarImportarGeoJSONCmd struct {
	SedeID    string                   `json:"sedeId"`
	BloqueID  *string                  `json:"bloqueId,omitempty"`
	Piso      *int                     `json:"piso,omitempty"`
	Elementos []ItemPreviewImportacion `json:"elementos"`
	Actor     ContextoActor            `json:"-"`
}

// OmitidoImportacion explica por qué un elemento no se creó al confirmar.
type OmitidoImportacion struct {
	Codigo string `json:"codigo"`
	Motivo string `json:"motivo"`
}

// ResultadoImportacion resume la confirmación (US-GEO-11 AC-02).
type ResultadoImportacion struct {
	TotalImportados int                  `json:"totalImportados"`
	Omitidos        []OmitidoImportacion `json:"omitidos"`
}

// ConfirmarImportarGeoJSON persiste los espacios importados. El backend no confía en el
// veredicto del cliente: cada geometría se revalida con US-GEO-04 y se contrasta con los
// espacios del mismo bloque y piso según US-GEO-05 (solapamiento > 50 % bloquea).
func (s *Service) ConfirmarImportarGeoJSON(ctx context.Context, cmd ConfirmarImportarGeoJSONCmd) (*ResultadoImportacion, error) {
	if cmd.SedeID == "" {
		return nil, shared.NewValidationError("La sede es obligatoria para la importación", shared.FieldError{
			Campo: "sedeId", Error: "SEDE_REQUERIDA",
		})
	}

	now := s.clk.Now()
	res := &ResultadoImportacion{Omitidos: []OmitidoImportacion{}}
	omitir := func(codigo, motivo string) {
		res.Omitidos = append(res.Omitidos, OmitidoImportacion{Codigo: codigo, Motivo: motivo})
	}

	for _, entrada := range cmd.Elementos {
		item := analizarCandidato(entrada.Indice, candidatoImportacion{
			Codigo: entrada.Codigo, Nombre: entrada.Nombre, Tipo: entrada.Tipo, Capacidad: entrada.Capacidad,
			TipoGeometria: "Polygon", Anillo: entrada.Vertices,
		})
		if !item.Valido {
			omitir(item.Codigo, fmt.Sprintf("geometría inválida: %v", item.Errores))
			continue
		}
		if existente, _ := s.espacioRepo.FindByCodigo(ctx, item.Codigo); existente != nil {
			omitir(item.Codigo, "ya existe un espacio con ese código")
			continue
		}

		verts := make([]geo.GeoPoint, 0, len(item.Vertices))
		for _, c := range item.Vertices {
			if pt, err := geo.NewGeoPoint(c[0], c[1]); err == nil {
				verts = append(verts, pt)
			}
		}
		poly, err := geo.NewGeoPolygon(verts)
		if err != nil {
			omitir(item.Codigo, err.Error())
			continue
		}
		if motivo := s.solapamientoBloqueante(ctx, cmd.BloqueID, cmd.Piso, poly); motivo != "" {
			omitir(item.Codigo, motivo)
			continue
		}

		esp := &geo.Espacio{
			SedeID: cmd.SedeID, BloqueID: cmd.BloqueID, Piso: cmd.Piso,
			Codigo: item.Codigo, Nombre: item.Nombre, Capacidad: item.Capacidad,
			Tipo: geo.TipoEspacio(item.Tipo), Estado: geo.EstadoActivo, NivelValidacion: geo.NivelAula,
			BufferMetros: 10.0, Activo: true, CreadoEn: now, ActualizadoEn: now,
		}
		if err := esp.AsignarGeometria(poly, geo.MetodoImportacion, nil); err != nil {
			omitir(item.Codigo, err.Error())
			continue
		}
		if err := s.espacioRepo.Create(ctx, esp); err != nil {
			omitir(item.Codigo, "no se pudo guardar el espacio")
			continue
		}
		res.TotalImportados++
	}

	s.auditar(ctx, "sede", cmd.SedeID, "ESPACIOS_IMPORTADOS_GEOJSON", cmd.Actor, nil, map[string]interface{}{
		"totalImportados": res.TotalImportados,
		"omitidos":        res.Omitidos,
	})
	return res, nil
}

// solapamientoBloqueante devuelve el motivo si el polígono cubre más del 50 % de otro espacio
// del mismo bloque y piso (misma regla que GuardarGeometriaEspacio, US-GEO-05).
func (s *Service) solapamientoBloqueante(ctx context.Context, bloqueID *string, piso *int, poly geo.GeoPolygon) string {
	otros, err := s.espacioRepo.BuscarIntersecciones(ctx, "", bloqueID, piso, poly)
	if err != nil {
		return "no se pudo verificar el solapamiento"
	}
	for _, otro := range otros {
		if otro.Geometria == nil {
			continue
		}
		if _, pct := geo.CalcularAreaSolapadaGeodesica(poly, *otro.Geometria); pct > 50.0 {
			return fmt.Sprintf("solapamiento crítico del %.2f%% con %s", pct, otro.Codigo)
		}
	}
	return ""
}
