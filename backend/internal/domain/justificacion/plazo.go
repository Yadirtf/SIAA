package justificacion

import "time"

// DiasHabilesPlazo es el plazo por defecto para radicar tras la sesión.
const DiasHabilesPlazo = 5

// DentroDelPlazo indica si ahora está dentro de los días hábiles (lunes a viernes)
// posteriores a la fecha de la sesión. Los festivos no se descuentan.
func DentroDelPlazo(fechaSesion, ahora time.Time, diasHabiles int) bool {
	limite := time.Date(fechaSesion.Year(), fechaSesion.Month(), fechaSesion.Day(), 0, 0, 0, 0, fechaSesion.Location())
	for contados := 0; contados < diasHabiles; {
		limite = limite.AddDate(0, 0, 1)
		if limite.Weekday() != time.Saturday && limite.Weekday() != time.Sunday {
			contados++
		}
	}
	// El plazo cubre el día hábil límite completo.
	return ahora.Before(limite.AddDate(0, 0, 1))
}
