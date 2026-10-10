package geo

import (
	"context"
	"fmt"
	"strings"

	"github.com/siaa/backend/internal/domain/geo"
)

// analizarCandidatos valida cada candidato con las reglas de US-GEO-04 y detecta códigos
// repetidos dentro del mismo archivo (US-GEO-11 AC-01).
func analizarCandidatos(cands []candidatoImportacion) *PreviewImportacionDTO {
	res := &PreviewImportacionDTO{
		TotalElementos: len(cands),
		Elementos:      make([]ItemPreviewImportacion, 0, len(cands)),
	}
	vistos := map[string]int{}
	for i, c := range cands {
		item := analizarCandidato(i+1, c)
		if previo, dup := vistos[item.Codigo]; dup && item.Valido {
			item.Valido = false
			item.Errores = append(item.Errores, fmt.Sprintf("Código %s repetido en el archivo (elemento %d)", item.Codigo, previo))
		}
		vistos[item.Codigo] = item.Indice
		if item.Valido {
			res.Validos++
		} else {
			res.Invalidos++
		}
		res.Elementos = append(res.Elementos, item)
	}
	return res
}

// analizarCandidato aplica metadatos por defecto, normaliza el orden de coordenadas (AC-04) y
// valida la topología con el mismo validador de dominio que la captura manual (US-GEO-04).
func analizarCandidato(indice int, c candidatoImportacion) ItemPreviewImportacion {
	item := ItemPreviewImportacion{
		Indice:    indice,
		Codigo:    strings.TrimSpace(c.Codigo),
		Nombre:    strings.TrimSpace(c.Nombre),
		Tipo:      strings.ToUpper(strings.TrimSpace(c.Tipo)),
		Capacidad: c.Capacidad,
		Valido:    true,
		Errores:   []string{},
	}
	if item.Codigo == "" {
		item.Codigo = fmt.Sprintf("IMP-%d", indice)
		item.Advertencias = append(item.Advertencias, "Código no provisto, asignado código provisional")
	}
	if item.Nombre == "" {
		item.Nombre = fmt.Sprintf("Espacio Importado %d", indice)
	}
	if item.Tipo == "" {
		item.Tipo = string(geo.TipoAula)
	} else if !geo.EsTipoEspacioValido(geo.TipoEspacio(item.Tipo)) {
		item.Advertencias = append(item.Advertencias, fmt.Sprintf("Tipo %s desconocido; se importará como AULA", item.Tipo))
		item.Tipo = string(geo.TipoAula)
	}

	invalidar := func(msg string) ItemPreviewImportacion {
		item.Valido = false
		item.Errores = append(item.Errores, msg)
		return item
	}
	if c.ErrorLectura != "" {
		return invalidar(c.ErrorLectura)
	}
	if c.TipoGeometria != "Polygon" {
		return invalidar("La geometría debe ser de tipo Polygon con anillo cerrado")
	}
	if len(c.Anillo) < 3 {
		return invalidar("El polígono debe tener al menos 3 vértices")
	}

	invertidas := coordenadasInvertidas(c.Anillo)
	if invertidas {
		item.CoordenadasInvert = true
		item.Advertencias = append(item.Advertencias, "Se detectó orden [latitud, longitud] invertido; normalizado a [longitud, latitud]")
	}
	coords := make([][2]float64, 0, len(c.Anillo))
	for _, p := range c.Anillo {
		lon, lat := p[0], p[1]
		if invertidas {
			lon, lat = p[1], p[0]
		}
		if _, err := geo.NewGeoPoint(lon, lat); err != nil {
			item.Valido = false
			item.Errores = append(item.Errores, fmt.Sprintf("Vértice inválido [%.6f, %.6f]: %v", lon, lat, err))
			continue
		}
		coords = append(coords, [2]float64{lon, lat})
	}
	item.Vertices = coords
	if !item.Valido {
		return item
	}
	r := geo.ValidarGeometriaPoligono(coords, 0, 0)
	if !r.Valido {
		return invalidar(fmt.Sprintf("Polígono geodésico no conformante (%s): %s", r.Codigo, r.Mensaje))
	}
	item.Advertencias = append(item.Advertencias, r.Advertencias...)
	return item
}

// coordenadasInvertidas detecta por rango de valores un anillo escrito [lat, lon] (AC-04):
// una "latitud" fuera de ±90 con "longitud" válida como latitud, o el patrón típico de
// Colombia/Sudamérica (latitud ~[-10, 20], longitud ~[-90, -50]) en la posición cambiada.
func coordenadasInvertidas(anillo [][2]float64) bool {
	for _, p := range anillo {
		c0, c1 := p[0], p[1]
		if (c1 > 90 || c1 < -90) && c0 >= -90 && c0 <= 90 {
			return true
		}
		if c0 >= -10 && c0 <= 20 && c1 >= -90 && c1 <= -50 {
			return true
		}
	}
	return false
}

// marcarCodigosExistentes advierte en la previsualización qué códigos ya existen: la
// confirmación los omitirá para no sobrescribir espacios vigentes.
func (s *Service) marcarCodigosExistentes(ctx context.Context, res *PreviewImportacionDTO) {
	for i := range res.Elementos {
		it := &res.Elementos[i]
		if existente, err := s.espacioRepo.FindByCodigo(ctx, it.Codigo); err == nil && existente != nil && !existente.Eliminado {
			it.Advertencias = append(it.Advertencias, fmt.Sprintf("Ya existe un espacio con código %s; se omitirá al confirmar", it.Codigo))
		}
	}
}
