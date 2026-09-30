package academico

import (
	"errors"
	"fmt"
	"strconv"
	"strings"
	"time"
)

const (
	ZonaHorariaDefault = "America/Bogota" // ADR-11, US-ACA-02 AC-03
)

var (
	ErrFranjaDiaInvalido     = errors.New("día de la semana inválido (debe ser 1=Lunes a 7=Domingo)")
	ErrFranjaHorasVacias     = errors.New("hora de inicio y hora de fin son requeridas en formato HH:MM")
	ErrFranjaFinMenorOIgual  = errors.New("la hora de fin debe ser estrictamente posterior a la hora de inicio (US-ACA-02 AC-02)")
	ErrFranjaFormatoInvalido = errors.New("formato de hora inválido, use HH:MM (ej. 07:00, 18:30)")
	ErrFranjaDuracionCorta   = errors.New("la duración de la franja es inferior a 15 minutos (US-ACA-02 AC-04)")
	ErrFranjaDuracionLarga   = errors.New("la duración de la franja es superior a 8 horas (US-ACA-02 AC-04)")
)

// FranjaHoraria representa un bloque recurrente de clase (US-ACA-02).
type FranjaHoraria struct {
	diaSemana   int    // 1 = Lunes, 2 = Martes, ..., 7 = Domingo (ISO 8601)
	horaInicio  string // "HH:MM", ej. "08:00"
	horaFin     string // "HH:MM", ej. "10:00"
	zonaHoraria string // "America/Bogota"
}

// NuevaFranjaHoraria valida y crea un value object FranjaHoraria inmutable.
func NuevaFranjaHoraria(diaSemana int, horaInicio, horaFin, zonaHoraria string) (FranjaHoraria, []string, error) {
	var advertencias []string

	if diaSemana < 1 || diaSemana > 7 {
		return FranjaHoraria{}, nil, ErrFranjaDiaInvalido
	}

	horaInicio = strings.TrimSpace(horaInicio)
	horaFin = strings.TrimSpace(horaFin)
	zonaHoraria = strings.TrimSpace(zonaHoraria)
	if zonaHoraria == "" {
		zonaHoraria = ZonaHorariaDefault
	}

	// Validar que la zona horaria sea válida
	if _, err := time.LoadLocation(zonaHoraria); err != nil {
		zonaHoraria = ZonaHorariaDefault
	}

	minInicio, err := minutosDesdeMedianoche(horaInicio)
	if err != nil {
		return FranjaHoraria{}, nil, fmt.Errorf("hora de inicio inválida: %w", err)
	}

	minFin, err := minutosDesdeMedianoche(horaFin)
	if err != nil {
		return FranjaHoraria{}, nil, fmt.Errorf("hora de fin inválida: %w", err)
	}

	if minFin <= minInicio {
		return FranjaHoraria{}, nil, ErrFranjaFinMenorOIgual
	}

	duracionMin := minFin - minInicio
	if duracionMin < 15 {
		advertencias = append(advertencias, "Advertencia: duración menor a 15 minutos (US-ACA-02 AC-04)")
	}
	if duracionMin > 8*60 {
		advertencias = append(advertencias, "Advertencia: duración mayor a 8 horas (US-ACA-02 AC-04)")
	}

	return FranjaHoraria{
		diaSemana:   diaSemana,
		horaInicio:  horaInicio,
		horaFin:     horaFin,
		zonaHoraria: zonaHoraria,
	}, advertencias, nil
}

// ReconstituirFranjaHoraria reconstituye una franja desde base de datos.
func ReconstituirFranjaHoraria(diaSemana int, horaInicio, horaFin, zonaHoraria string) FranjaHoraria {
	if zonaHoraria == "" {
		zonaHoraria = ZonaHorariaDefault
	}
	return FranjaHoraria{
		diaSemana:   diaSemana,
		horaInicio:  horaInicio,
		horaFin:     horaFin,
		zonaHoraria: zonaHoraria,
	}
}

func (f FranjaHoraria) DiaSemana() int      { return f.diaSemana }
func (f FranjaHoraria) HoraInicio() string  { return f.horaInicio }
func (f FranjaHoraria) HoraFin() string     { return f.horaFin }
func (f FranjaHoraria) ZonaHoraria() string { return f.zonaHoraria }

// MinutosInicio retorna los minutos transcurridos desde 00:00.
func (f FranjaHoraria) MinutosInicio() int {
	m, _ := minutosDesdeMedianoche(f.horaInicio)
	return m
}

// MinutosFin retorna los minutos transcurridos desde 00:00.
func (f FranjaHoraria) MinutosFin() int {
	m, _ := minutosDesdeMedianoche(f.horaFin)
	return m
}

// SeSolapaCon evalúa si dos franjas coinciden en el mismo día y se solapan temporalmente.
func (f FranjaHoraria) SeSolapaCon(otra FranjaHoraria) bool {
	if f.diaSemana != otra.diaSemana {
		return false
	}
	// Intervalos [A_ini, A_fin) y [B_ini, B_fin) se solapan si A_ini < B_fin && B_ini < A_fin
	return f.MinutosInicio() < otra.MinutosFin() && otra.MinutosInicio() < f.MinutosFin()
}

func minutosDesdeMedianoche(hhmm string) (int, error) {
	partes := strings.Split(hhmm, ":")
	if len(partes) != 2 {
		return 0, ErrFranjaFormatoInvalido
	}

	h, err := strconv.Atoi(partes[0])
	if err != nil || h < 0 || h > 23 {
		return 0, ErrFranjaFormatoInvalido
	}

	m, err := strconv.Atoi(partes[1])
	if err != nil || m < 0 || m > 59 {
		return 0, ErrFranjaFormatoInvalido
	}

	return h*60 + m, nil
}
