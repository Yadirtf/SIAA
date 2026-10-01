package handler

import (
	"time"

	"github.com/siaa/backend/internal/domain/shared"
)

// maxDiasRango limita los listados por rango para que la consulta siga siendo liviana.
const maxDiasRango = 190

// rangoFechas valida los parámetros desde/hasta (AAAA-MM-DD, inclusivos) de un listado.
func rangoFechas(desde, hasta string) (string, string, error) {
	var d, h time.Time
	var err error
	if desde != "" {
		if d, err = time.Parse("2006-01-02", desde); err != nil {
			return "", "", shared.NewValidationError("La fecha 'desde' debe tener el formato AAAA-MM-DD.")
		}
	}
	if hasta != "" {
		if h, err = time.Parse("2006-01-02", hasta); err != nil {
			return "", "", shared.NewValidationError("La fecha 'hasta' debe tener el formato AAAA-MM-DD.")
		}
	}
	if desde != "" && hasta != "" {
		if h.Before(d) {
			return "", "", shared.NewValidationError("La fecha 'hasta' no puede ser anterior a 'desde'.")
		}
		if h.Sub(d) > maxDiasRango*24*time.Hour {
			return "", "", shared.NewValidationError("El rango de fechas no puede superar un semestre (190 días).")
		}
	}
	return desde, hasta, nil
}
