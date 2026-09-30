// Package academico — DTOs y helpers para el generador masivo de sesiones (US-ACA-05).
package academico

import (
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/domain/geo"
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

// resolverParametrosCongelados combina los parámetros efectivos de la cascada jerárquica
// (o los valores por defecto si no hay resolutor) con los overrides propios de la asignación,
// que tienen la mayor precedencia. Los overrides se normalizan a la clave del catálogo para
// aceptar tanto "holgura_entrada_despues_min" como "holguraEntradaDespuesMin" (SRS §6.2).
func resolverParametrosCongelados(base map[string]interface{}, asig *academico.Asignacion) map[string]interface{} {
	congelados := make(map[string]interface{})
	catalogo := make(map[string]string)
	for k, v := range parametro.ValoresPorDefecto() {
		congelados[string(k)] = v
		catalogo[normalizarClaveParametro(string(k))] = string(k)
	}
	// Los alias camelCase (datos semilla heredados) se aplican primero y las claves del
	// catálogo después, para que un valor en snake_case de la cascada nunca quede tapado
	// por su alias según el orden aleatorio de iteración del mapa.
	for k, v := range base {
		if clave, ok := catalogo[normalizarClaveParametro(k)]; ok && clave != k {
			congelados[clave] = v
		} else if !ok {
			congelados[k] = v
		}
	}
	for k, v := range base {
		if catalogo[normalizarClaveParametro(k)] == k {
			congelados[k] = v
		}
	}
	for k, v := range asig.ParametrosOverride() {
		if clave, ok := catalogo[normalizarClaveParametro(k)]; ok {
			congelados[clave] = v
			continue
		}
		congelados[k] = v
	}
	return congelados
}

func normalizarClaveParametro(k string) string {
	return strings.ToLower(strings.ReplaceAll(k, "_", ""))
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

// sedeSesion toma la sede del aula; si la sesión no tiene aula (virtual), la del periodo.
func sedeSesion(sedePeriodo string, espacio *geo.Espacio) string {
	if espacio != nil && espacio.SedeID != "" {
		return espacio.SedeID
	}
	return sedePeriodo
}
