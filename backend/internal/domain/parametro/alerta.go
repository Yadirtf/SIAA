// Package parametro — evaluación de alertas tempranas de asistencia según parámetros efectivos.
// Satisface US-PAR-04 (AC-01..AC-03), RF-PAR-008 y RF-NOT-004.
// ADR-02: función pura, sin base de datos ni red.
package parametro

import (
	"fmt"
)

// TipoAlertaAsistencia define la categoría de la alerta emitida.
type TipoAlertaAsistencia string

const (
	AlertaPorcentajeBajo            TipoAlertaAsistencia = "PORCENTAJE_BAJO"
	AlertaInasistenciasConsecutivas TipoAlertaAsistencia = "INASISTENCIAS_CONSECUTIVAS"
)

// AlertaAsistencia representa una alerta temprana de asistencia calculada.
type AlertaAsistencia struct {
	Tipo           TipoAlertaAsistencia `json:"tipo"`
	DocenteID      string               `json:"docenteId"`
	FacultadID     string               `json:"facultadId"`
	AsignaturaID   string               `json:"asignaturaId"`
	GrupoID        string               `json:"grupoId"`
	Mensaje        string               `json:"mensaje"`
	ValorActual    float64              `json:"valorActual"`
	UmbralDefinido float64              `json:"umbralDefinido"`
	EsAgrupada     bool                 `json:"esAgrupada"` // true si agrupa ausencias previas (AC-03)
}

// HistorialAlertasDocente contiene el registro previo de alertas para evitar duplicaciones (AC-03).
type HistorialAlertasDocente struct {
	AlertaConsecutivaEmitida bool
	UltimoConteoReportado    int
}

// EvaluarAlertasAsistencia evalúa las inasistencias y porcentaje respecto a los parámetros configurados (US-PAR-04).
func EvaluarAlertasAsistencia(
	docenteID, facultadID, asignaturaID, grupoID string,
	sesionesTotales int,
	sesionesAsistidas int,
	inasistenciasConsecutivas int,
	parametrosEfectivos map[Clave]interface{},
	historial HistorialAlertasDocente,
) []AlertaAsistencia {
	var alertas []AlertaAsistencia

	// 1. Obtener parámetros efectivos con fallback seguro
	pctMin := 80.0
	if v, ok := parametrosEfectivos[ClavePorcentajeMinimoAsistencia]; ok {
		if intVal, okInt := toInt(v); okInt {
			pctMin = float64(intVal)
		}
	}

	umbralConsecutivas := 3
	if v, ok := parametrosEfectivos[ClaveInasistenciasConsecutivasAlerta]; ok {
		if intVal, okInt := toInt(v); okInt {
			umbralConsecutivas = intVal
		}
	}

	// 2. Evaluar porcentaje de asistencia (AC-01)
	if sesionesTotales > 0 {
		pctActual := (float64(sesionesAsistidas) / float64(sesionesTotales)) * 100.0
		if pctActual < pctMin {
			alertas = append(alertas, AlertaAsistencia{
				Tipo:           AlertaPorcentajeBajo,
				DocenteID:      docenteID,
				FacultadID:     facultadID,
				AsignaturaID:   asignaturaID,
				GrupoID:        grupoID,
				Mensaje:        fmt.Sprintf("Porcentaje de asistencia actual (%.1f%%) inferior al mínimo configurado (%.1f%%)", pctActual, pctMin),
				ValorActual:    pctActual,
				UmbralDefinido: pctMin,
				EsAgrupada:     false,
			})
		}
	}

	// 3. Evaluar inasistencias consecutivas y agrupación (AC-02, AC-03)
	if inasistenciasConsecutivas >= umbralConsecutivas {
		esAgrupada := false
		if historial.AlertaConsecutivaEmitida && inasistenciasConsecutivas > historial.UltimoConteoReportado {
			// AC-03: No se duplica la alerta individual; se marca como agrupada
			esAgrupada = true
		}

		alertas = append(alertas, AlertaAsistencia{
			Tipo:           AlertaInasistenciasConsecutivas,
			DocenteID:      docenteID,
			FacultadID:     facultadID,
			AsignaturaID:   asignaturaID,
			GrupoID:        grupoID,
			Mensaje:        fmt.Sprintf("El docente alcanzó %d inasistencias consecutivas (umbral: %d)", inasistenciasConsecutivas, umbralConsecutivas),
			ValorActual:    float64(inasistenciasConsecutivas),
			UmbralDefinido: float64(umbralConsecutivas),
			EsAgrupada:     esAgrupada,
		})
	}

	return alertas
}
