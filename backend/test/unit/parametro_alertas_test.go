// Package unit_test — pruebas unitarias para US-PAR-04 (Alertas de asistencia).
package unit_test

import (
	"testing"

	"github.com/siaa/backend/internal/domain/parametro"
)

func TestUS_PAR_04_AlertasAsistencia(t *testing.T) {
	efectivos := map[parametro.Clave]interface{}{
		parametro.ClavePorcentajeMinimoAsistencia:      85,
		parametro.ClaveInasistenciasConsecutivasAlerta: 3,
	}

	t.Run("AC-01: Disparar alerta cuando porcentaje de asistencia es menor al umbral", func(t *testing.T) {
		// 7 asistidas de 10 = 70% < 85%
		alertas := parametro.EvaluarAlertasAsistencia(
			"doc-1", "fac-1", "asig-1", "grp-1",
			10, 7, 0,
			efectivos,
			parametro.HistorialAlertasDocente{},
		)

		if len(alertas) != 1 {
			t.Fatalf("esperaba 1 alerta, obtuvo %d", len(alertas))
		}
		if alertas[0].Tipo != parametro.AlertaPorcentajeBajo {
			t.Errorf("tipo esperado AlertaPorcentajeBajo, obtuvo %s", alertas[0].Tipo)
		}
		if alertas[0].ValorActual != 70.0 {
			t.Errorf("valor actual esperado 70.0, obtuvo %.1f", alertas[0].ValorActual)
		}
	})

	t.Run("AC-02: Disparar alerta de inasistencias consecutivas al alcanzar umbral", func(t *testing.T) {
		alertas := parametro.EvaluarAlertasAsistencia(
			"doc-1", "fac-1", "asig-1", "grp-1",
			10, 9, 3, // 3 consecutivas == umbral 3
			efectivos,
			parametro.HistorialAlertasDocente{AlertaConsecutivaEmitida: false},
		)

		if len(alertas) != 1 {
			t.Fatalf("esperaba 1 alerta, obtuvo %d", len(alertas))
		}
		if alertas[0].Tipo != parametro.AlertaInasistenciasConsecutivas {
			t.Errorf("tipo esperado AlertaInasistenciasConsecutivas, obtuvo %s", alertas[0].Tipo)
		}
		if alertas[0].EsAgrupada {
			t.Error("primera alerta consecutiva no debe marcarse como agrupada")
		}
	})

	t.Run("AC-03: Agrupar alerta y no duplicar si el conteo sigue creciendo", func(t *testing.T) {
		historial := parametro.HistorialAlertasDocente{
			AlertaConsecutivaEmitida: true,
			UltimoConteoReportado:    3,
		}

		alertas := parametro.EvaluarAlertasAsistencia(
			"doc-1", "fac-1", "asig-1", "grp-1",
			10, 9, 4, // 9/10 = 90% >= 85% (no alerta por pct); 4 consecutivas > 3 reportadas antes
			efectivos,
			historial,
		)

		if len(alertas) != 1 {
			t.Fatalf("esperaba 1 alerta agrupada, obtuvo %d", len(alertas))
		}
		if !alertas[0].EsAgrupada {
			t.Error("la alerta por ausencia subsecuente debe marcarse como agrupada (AC-03)")
		}
	})
}
