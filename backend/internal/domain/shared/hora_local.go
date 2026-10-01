package shared

import (
	"fmt"
	"time"
)

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

// HoraLocal formatea un instante como hora local institucional de 12 horas: "2:05 p. m.".
// Los instantes se almacenan y comparan en UTC; solo la presentación usa la hora local.
func HoraLocal(t time.Time) string {
	l := t.In(zonaInstitucional)
	return formato12h(l.Hour(), l.Minute())
}

// FechaHoraLocal formatea un instante como "2026-10-01 2:05 p. m." en la zona institucional.
func FechaHoraLocal(t time.Time) string {
	return FechaLocal(t) + " " + HoraLocal(t)
}

// FechaHoraSegundosLocal formatea un instante como "2026-10-01 2:05:09 p. m.".
func FechaHoraSegundosLocal(t time.Time) string {
	l := t.In(zonaInstitucional)
	h, sufijo := hora12y(l.Hour())
	return fmt.Sprintf("%s %d:%02d:%02d %s", FechaLocal(t), h, l.Minute(), l.Second(), sufijo)
}

// Hora12h convierte una franja "18:30" (24 h) a "6:30 p. m."; si no es una hora la devuelve igual.
func Hora12h(hhmm string) string {
	var h, m int
	if _, err := fmt.Sscanf(hhmm, "%d:%d", &h, &m); err != nil || h < 0 || h > 23 || m < 0 || m > 59 {
		return hhmm
	}
	return formato12h(h, m)
}

func formato12h(h, m int) string {
	h12, sufijo := hora12y(h)
	return fmt.Sprintf("%d:%02d %s", h12, m, sufijo)
}

// hora12y devuelve la hora de 12 h y su sufijo como se escribe en Colombia.
func hora12y(h int) (int, string) {
	sufijo := "a. m."
	if h >= 12 {
		sufijo = "p. m."
	}
	if h%12 == 0 {
		return 12, sufijo
	}
	return h % 12, sufijo
}

// ZonaInstitucional devuelve la zona horaria de la institución.
func ZonaInstitucional() *time.Location { return zonaInstitucional }

// FechaLocal devuelve la fecha AAAA-MM-DD del instante en la zona institucional.
func FechaLocal(t time.Time) string {
	return t.In(zonaInstitucional).Format("2006-01-02")
}
