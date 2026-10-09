// Package academico — comparación de los parámetros congelados de una sesión con los vigentes.
// US-PAR-03 AC-03: al consultar una sesión ya generada se muestran sus parámetros congelados
// y se señala cuáles difieren de los efectivos actuales de la cascada.
package academico

import (
	"context"
	"fmt"
	"sort"

	"github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/domain/geo"
	"github.com/siaa/backend/internal/domain/parametro"
)

// DiferenciaParametro es una clave cuyo valor congelado ya no coincide con el efectivo actual.
type DiferenciaParametro struct {
	Clave     string      `json:"clave"`
	Congelado interface{} `json:"congelado"`
	Actual    interface{} `json:"actual"`
}

// DiferenciasParametros resuelve la cascada actual para la sesión y devuelve las claves del
// catálogo cuyo valor congelado difiere. Lista vacía: la sesión usa los parámetros vigentes.
func (s *Service) DiferenciasParametros(ctx context.Context, sesion *academico.Sesion) []DiferenciaParametro {
	diferencias := make([]DiferenciaParametro, 0)
	asig, err := s.asignacionRepo.GetByID(ctx, sesion.AsignacionID())
	if err != nil || asig == nil {
		return diferencias
	}
	sede := sesion.SedeID()
	if p, errP := s.periodoRepo.GetByID(ctx, sesion.PeriodoID()); errP == nil && p != nil {
		sede = p.SedeID()
	}
	var espacio *geo.Espacio
	if sesion.EspacioID() != "" {
		espacio, _ = s.espacioRepo.FindByID(ctx, sesion.EspacioID())
	}
	actuales := resolverParametrosCongelados(s.parametrosEfectivos(ctx, sede, asig, espacio), asig)
	congelados := sesion.ParametrosCongelados()

	for clave := range parametro.ValoresPorDefecto() {
		k := string(clave)
		congelado, ok := congelados[k]
		if !ok {
			continue // sesiones antiguas sin la clave: el motor usa el valor por defecto
		}
		if actual := actuales[k]; !mismoValorParametro(congelado, actual) {
			diferencias = append(diferencias, DiferenciaParametro{Clave: k, Congelado: congelado, Actual: actual})
		}
	}
	sort.Slice(diferencias, func(i, j int) bool { return diferencias[i].Clave < diferencias[j].Clave })
	return diferencias
}

// mismoValorParametro compara valores de parámetro ignorando el tipo numérico con el que
// MongoDB los devuelve (int32, int64 o float64).
func mismoValorParametro(a, b interface{}) bool {
	if x, ok := numeroParametro(a); ok {
		y, okB := numeroParametro(b)
		return okB && x == y
	}
	return fmt.Sprint(a) == fmt.Sprint(b)
}

func numeroParametro(v interface{}) (float64, bool) {
	switch x := v.(type) {
	case int:
		return float64(x), true
	case int32:
		return float64(x), true
	case int64:
		return float64(x), true
	case float32:
		return float64(x), true
	case float64:
		return x, true
	}
	return 0, false
}
