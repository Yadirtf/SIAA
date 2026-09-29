package shared

import "time"

// ZonaHorariaInstitucional es la zona en la que se muestran las horas al usuario (ADR-11).
const ZonaHorariaInstitucional = "America/Bogota"

// zonaInstitucional usa la base de zonas horarias del sistema y, si no está disponible,
// un desfase fijo UTC−5 (Colombia no aplica horario de verano).
var zonaInstitucional = func() *time.Location {
	if loc, err := time.LoadLocation(ZonaHorariaInstitucional); err == nil {
		return loc
	}
	return time.FixedZone("COT", -5*60*60)
}()

// HoraLocal formatea un instante como hora local institucional "HH:MM".
// Los instantes se almacenan y comparan en UTC; solo la presentación usa la hora local.
func HoraLocal(t time.Time) string {
	return t.In(zonaInstitucional).Format("15:04")
}

// ZonaInstitucional devuelve la zona horaria de la institución.
func ZonaInstitucional() *time.Location { return zonaInstitucional }

// FechaLocal devuelve la fecha AAAA-MM-DD del instante en la zona institucional.
func FechaLocal(t time.Time) string {
	return t.In(zonaInstitucional).Format("2006-01-02")
}
