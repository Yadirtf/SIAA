package notificacion

import (
	"fmt"
	"time"
)

// Preferencias indica qué avisos quiere recibir el usuario (RF-NOT-003, US-NOT-02 AC-02).
type Preferencias struct {
	RecordatorioSesion     bool `json:"recordatorioSesion"`
	CierreVentana          bool `json:"cierreVentana"`
	ResultadoJustificacion bool `json:"resultadoJustificacion"`
	CambioHorario          bool `json:"cambioHorario"`
}

// Obligatorias son los avisos institucionales que el usuario no puede desactivar.
var Obligatorias = []string{"cambioHorario"}

// PreferenciasPorDefecto activa todo el catálogo.
func PreferenciasPorDefecto() Preferencias {
	return Preferencias{RecordatorioSesion: true, CierreVentana: true, ResultadoJustificacion: true, CambioHorario: true}
}

// AplicarObligatorias fuerza los avisos institucionales.
func (p *Preferencias) AplicarObligatorias() {
	p.CambioHorario = true
}

// Permite indica si el usuario quiere recibir el tipo dado.
func (p Preferencias) Permite(t Tipo) bool {
	switch t {
	case TipoRecordatorioSesion:
		return p.RecordatorioSesion
	case TipoCierreVentana:
		return p.CierreVentana
	case TipoResultadoJustificacion:
		return p.ResultadoJustificacion
	}
	return true
}

// FranjaSilencio es el horario nocturno sin avisos (US-NOT-02 AC-04), en hora institucional.
// Inicio y Fin son minutos desde medianoche; si Inicio > Fin la franja cruza la medianoche.
type FranjaSilencio struct {
	Inicio, Fin int
	Zona        *time.Location
	Activa      bool
}

// NuevaFranjaSilencio interpreta "HH:MM"; con ambos vacíos no hay franja.
func NuevaFranjaSilencio(inicio, fin string, zona *time.Location) (FranjaSilencio, error) {
	if inicio == "" && fin == "" {
		return FranjaSilencio{Zona: zona}, nil
	}
	i, err := minutosDelDia(inicio)
	if err != nil {
		return FranjaSilencio{}, err
	}
	f, err := minutosDelDia(fin)
	if err != nil {
		return FranjaSilencio{}, err
	}
	return FranjaSilencio{Inicio: i, Fin: f, Zona: zona, Activa: i != f}, nil
}

func minutosDelDia(s string) (int, error) {
	t, err := time.Parse("15:04", s)
	if err != nil {
		return 0, fmt.Errorf("hora de la franja de silencio inválida %q: %w", s, err)
	}
	return t.Hour()*60 + t.Minute(), nil
}

// Contiene indica si el instante cae dentro de la franja de silencio.
func (f FranjaSilencio) Contiene(t time.Time) bool {
	if !f.Activa {
		return false
	}
	local := t.In(f.Zona)
	m := local.Hour()*60 + local.Minute()
	if f.Inicio < f.Fin {
		return m >= f.Inicio && m < f.Fin
	}
	return m >= f.Inicio || m < f.Fin
}

// FinDesde devuelve el primer instante posterior a t en que termina la franja.
func (f FranjaSilencio) FinDesde(t time.Time) time.Time {
	local := t.In(f.Zona)
	fin := time.Date(local.Year(), local.Month(), local.Day(), f.Fin/60, f.Fin%60, 0, 0, f.Zona)
	if !fin.After(local) {
		fin = fin.AddDate(0, 0, 1)
	}
	return fin.UTC()
}
