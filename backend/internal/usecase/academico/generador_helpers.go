// Package academico — DTOs y helpers para el generador masivo de sesiones (US-ACA-05).
package academico

import (
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/domain/parametro"
)

// GenerarSesionesCmd parámetros para disparar la generación de sesiones de un periodo.
type GenerarSesionesCmd struct {
	PeriodoID    string        `json:"periodoId"`
	AsignacionID *string       `json:"asignacionId,omitempty"` // Opcional: generar solo para una asignación
	Actor        ContextoActor `json:"-"`
}

// FechaExcluidaDTO detalle de una fecha no lectiva excluida de la generación (AC-05).
type FechaExcluidaDTO struct {
	Fecha  string `json:"fecha"`
	Motivo string `json:"motivo"`
	Tipo   string `json:"tipo"`
}

// AsignacionOmitidaDTO detalle de una asignación que no pudo generar sesiones (AC-05).
type AsignacionOmitidaDTO struct {
	AsignacionID string `json:"asignacionId"`
	Motivo       string `json:"motivo"`
}

// InformeGeneracionDTO resultado exhaustivo de la generación de sesiones (AC-03, AC-05).
type InformeGeneracionDTO struct {
	PeriodoID                    string                 `json:"periodoId"`
	TotalDiasCalendario          int                    `json:"totalDiasCalendario"`
	AsignacionesProcesadas       int                    `json:"asignacionesProcesadas"`
	SesionesGeneradas            int                    `json:"sesionesGeneradas"`
	SesionesOmitidasIdempotencia int                    `json:"sesionesOmitidasIdempotencia"`
	FechasExcluidas              []FechaExcluidaDTO     `json:"fechasExcluidas"`
	AsignacionesOmitidas         []AsignacionOmitidaDTO `json:"asignacionesOmitidas"`
	DuracionMs                   int64                  `json:"duracionMs"`
	Mensaje                      string                 `json:"mensaje"`
}

func esFechaExcluida(fecha time.Time, sedeID, facultadID string, excepciones []*academico.CalendarioExcepcion) (bool, string) {
	for _, exc := range excepciones {
		if exc.AfectaFechaYAmbito(fecha, sedeID, facultadID) {
			return true, fmt.Sprintf("%s (%s)", exc.Nombre(), exc.Tipo())
		}
	}
	return false, ""
}

func resolverParametrosCongelados(asig *academico.Asignacion) map[string]interface{} {
	congelados := make(map[string]interface{})
	for k, v := range parametro.ValoresPorDefecto() {
		congelados[string(k)] = v
	}
	// Aplicar overrides específicos de la asignación (AC-02)
	for k, v := range asig.ParametrosOverride() {
		congelados[k] = v
	}
	return congelados
}

func calcularTiemposSesion(fecha time.Time, horaInicio, horaFin string, loc *time.Location) (time.Time, time.Time, error) {
	partsIni := strings.Split(horaInicio, ":")
	partsFin := strings.Split(horaFin, ":")
	if len(partsIni) != 2 || len(partsFin) != 2 {
		return time.Time{}, time.Time{}, fmt.Errorf("horas invalidas")
	}

	hIni, _ := strconv.Atoi(partsIni[0])
	mIni, _ := strconv.Atoi(partsIni[1])
	hFin, _ := strconv.Atoi(partsFin[0])
	mFin, _ := strconv.Atoi(partsFin[1])

	y, m, d := fecha.Date()
	tIni := time.Date(y, m, d, hIni, mIni, 0, 0, loc)
	tFin := time.Date(y, m, d, hFin, mFin, 0, 0, loc)
	return tIni, tFin, nil
}

func getParamInt(m map[string]interface{}, clave parametro.Clave, fallback int) int {
	if v, ok := m[string(clave)]; ok {
		switch x := v.(type) {
		case int:
			return x
		case float64:
			return int(x)
		case int64:
			return int(x)
		}
	}
	return fallback
}
