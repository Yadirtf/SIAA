package marcaje_test

import (
	"testing"
	"time"

	"github.com/siaa/backend/internal/domain/geo"
	"github.com/siaa/backend/internal/domain/marcaje"
)

// Helper para armar un contexto base de pruebas
func armarContextoPrueba(t *testing.T) (marcaje.ContextoSesion, time.Time, geo.GeoPoint) {
	t.Helper()
	// Aula cuadrada en Bogotá: Lon -74.082 a -74.081, Lat 4.609 a 4.610
	p1, _ := geo.NewGeoPoint(-74.082, 4.609)
	p2, _ := geo.NewGeoPoint(-74.081, 4.609)
	p3, _ := geo.NewGeoPoint(-74.081, 4.610)
	p4, _ := geo.NewGeoPoint(-74.082, 4.610)
	poly, err := geo.NewGeoPolygon([]geo.GeoPoint{p1, p2, p3, p4})
	if err != nil {
		t.Fatalf("error creando poligono base: %v", err)
	}

	polyBuffer, err := geo.CalcularBufferGeodesico(poly, 10.0) // 10 metros de buffer
	if err != nil {
		t.Fatalf("error creando buffer: %v", err)
	}

	inicio := time.Date(2026, 9, 8, 8, 0, 0, 0, time.UTC)
	fin := inicio.Add(2 * time.Hour)

	ctx := marcaje.ContextoSesion{
		UsuarioActivo:          true,
		TienePermiso:           true,
		DispositivoVinculadoID: "disp-123",
		Sesion: &marcaje.SesionInfo{
			ID:               "ses-1",
			EspacioID:        "esp-101",
			EspacioCodigo:    "A-301",
			DocenteIDs:       []string{"doc-1"},
			EstudianteIDs:    []string{"est-1", "est-2"},
			InicioProgramado: inicio,
			FinProgramado:    fin,
			Modalidad:        "PRESENCIAL",
		},
		Parametros: marcaje.ParametrosMarcaje{
			HolguraEntradaAntesMin:   15,
			HolguraEntradaDespuesMin: 15,
			HolguraSalidaAntesMin:    10,
			HolguraSalidaDespuesMin:  15,
			PrecisionGpsMaxMetros:    35.0,
			UmbralTardanzaMin:        10,
			ExigirAttestation:        false,
			BloquearMockLocation:     true,
			BloquearRooteado:         true,
			DesfaseRelojMaxSegundos:  300,
		},
		Geometria:       poly,
		GeometriaBuffer: polyBuffer,
	}

	// Punto centro dentro del aula
	centroide := geo.CalcularCentroide(poly)

	return ctx, inicio, centroide
}

func TestEvaluarMarcaje_BateriaMinima11_4(t *testing.T) {
	ctxBase, inicio, centroide := armarContextoPrueba(t)

	t.Run("Caso Feliz — Dentro de aula, min 4, presente", func(t *testing.T) {
		ahora := inicio.Add(4 * time.Minute)
		req := marcaje.SolicitudMarcaje{
			SesionID:             "ses-1",
			UsuarioID:            "doc-1",
			RolMarcaje:           marcaje.RolDocente,
			Tipo:                 marcaje.TipoEntrada,
			Latitud:              centroide.Latitud(),
			Longitud:             centroide.Longitud(),
			PrecisionMetros:      8.0,
			TimestampDispositivo: ahora,
			DispositivoID:        "disp-123",
		}
		res := marcaje.EvaluarMarcaje(req, ctxBase, ahora)
		if res.Resultado != marcaje.ResultadoPresente {
			t.Errorf("esperado PRESENTE, obtuvo: %s (%s)", res.Resultado, res.Mensaje)
		}
		if res.PermiteReintento || res.PuedeJustificar {
			t.Errorf("un marcaje feliz no permite reintento ni requiere justificacion")
		}
	})

	t.Run("Caso Tardanza — Minuto 12, holgura 15, tardanza", func(t *testing.T) {
		ahora := inicio.Add(12 * time.Minute)
		req := marcaje.SolicitudMarcaje{
			SesionID:             "ses-1",
			UsuarioID:            "doc-1",
			RolMarcaje:           marcaje.RolDocente,
			Tipo:                 marcaje.TipoEntrada,
			Latitud:              centroide.Latitud(),
			Longitud:             centroide.Longitud(),
			PrecisionMetros:      10.0,
			TimestampDispositivo: ahora,
			DispositivoID:        "disp-123",
		}
		res := marcaje.EvaluarMarcaje(req, ctxBase, ahora)
		if res.Resultado != marcaje.ResultadoTardanza {
			t.Errorf("esperado TARDANZA, obtuvo: %s", res.Resultado)
		}
		if res.MinutosRespectoInicio != 12 {
			t.Errorf("esperado 12 minutos respecto al inicio, obtuvo: %d", res.MinutosRespectoInicio)
		}
	})

	t.Run("Caso Fuera de horario — Minuto 25, holgura 15", func(t *testing.T) {
		ahora := inicio.Add(25 * time.Minute)
		req := marcaje.SolicitudMarcaje{
			SesionID:             "ses-1",
			UsuarioID:            "doc-1",
			RolMarcaje:           marcaje.RolDocente,
			Tipo:                 marcaje.TipoEntrada,
			Latitud:              centroide.Latitud(),
			Longitud:             centroide.Longitud(),
			PrecisionMetros:      10.0,
			TimestampDispositivo: ahora,
			DispositivoID:        "disp-123",
		}
		res := marcaje.EvaluarMarcaje(req, ctxBase, ahora)
		if res.Resultado != marcaje.ResultadoRechazadoFueraHorario {
			t.Errorf("esperado RECHAZADO_FUERA_DE_HORARIO, obtuvo: %s", res.Resultado)
		}
		if res.PasoFallido != marcaje.PasoVentanaTemporal {
			t.Errorf("esperado paso 5, obtuvo: %d", res.PasoFallido)
		}
		if !res.PuedeJustificar {
			t.Errorf("fuera de horario debe permitir justificar")
		}
	})

	t.Run("Caso Fuera de area — 40m del aula", func(t *testing.T) {
		ahora := inicio.Add(5 * time.Minute)
		// Punto exterior distante
		req := marcaje.SolicitudMarcaje{
			SesionID:             "ses-1",
			UsuarioID:            "doc-1",
			RolMarcaje:           marcaje.RolDocente,
			Tipo:                 marcaje.TipoEntrada,
			Latitud:              4.6095,
			Longitud:             -74.0805, // Fuera del buffer
			PrecisionMetros:      12.0,
			TimestampDispositivo: ahora,
			DispositivoID:        "disp-123",
		}
		res := marcaje.EvaluarMarcaje(req, ctxBase, ahora)
		if res.Resultado != marcaje.ResultadoRechazadoFueraDeArea {
			t.Errorf("esperado RECHAZADO_FUERA_DE_AREA, obtuvo: %s", res.Resultado)
		}
		if res.DistanciaMetros <= 0 {
			t.Errorf("distancia debe ser informada (> 0), obtuvo: %f", res.DistanciaMetros)
		}
		if res.PasoFallido != marcaje.PasoContencionGeoespacial {
			t.Errorf("esperado paso 8, obtuvo: %d", res.PasoFallido)
		}
	})

	t.Run("Caso Borde exacto — Vertice del buffer es DENTRO", func(t *testing.T) {
		ahora := inicio.Add(5 * time.Minute)
		vBuffer := ctxBase.GeometriaBuffer.Vertices()[0]
		req := marcaje.SolicitudMarcaje{
			SesionID:             "ses-1",
			UsuarioID:            "doc-1",
			RolMarcaje:           marcaje.RolDocente,
			Tipo:                 marcaje.TipoEntrada,
			Latitud:              vBuffer.Latitud(),
			Longitud:             vBuffer.Longitud(),
			PrecisionMetros:      12.0,
			TimestampDispositivo: ahora,
			DispositivoID:        "disp-123",
		}
		res := marcaje.EvaluarMarcaje(req, ctxBase, ahora)
		if res.Resultado != marcaje.ResultadoPresente {
			t.Errorf("borde exacto debe ser aceptado como PRESENTE, obtuvo: %s (%s)", res.Resultado, res.Mensaje)
		}
	})

	t.Run("Caso Sin asignacion — Docente no asignado", func(t *testing.T) {
		ahora := inicio.Add(5 * time.Minute)
		req := marcaje.SolicitudMarcaje{
			SesionID:             "ses-1",
			UsuarioID:            "doc-ajeno",
			RolMarcaje:           marcaje.RolDocente,
			Tipo:                 marcaje.TipoEntrada,
			Latitud:              centroide.Latitud(),
			Longitud:             centroide.Longitud(),
			PrecisionMetros:      10.0,
			TimestampDispositivo: ahora,
			DispositivoID:        "disp-123",
		}
		res := marcaje.EvaluarMarcaje(req, ctxBase, ahora)
		if res.Resultado != marcaje.ResultadoRechazadoSinAsignacion {
			t.Errorf("esperado RECHAZADO_SIN_ASIGNACION, obtuvo: %s", res.Resultado)
		}
		if res.PasoFallido != marcaje.PasoAsignacion {
			t.Errorf("esperado paso 4, obtuvo: %d", res.PasoFallido)
		}
	})

	t.Run("Caso Mock location activo y bloqueado", func(t *testing.T) {
		ahora := inicio.Add(5 * time.Minute)
		req := marcaje.SolicitudMarcaje{
			SesionID:             "ses-1",
			UsuarioID:            "doc-1",
			RolMarcaje:           marcaje.RolDocente,
			Tipo:                 marcaje.TipoEntrada,
			Latitud:              centroide.Latitud(),
			Longitud:             centroide.Longitud(),
			PrecisionMetros:      10.0,
			TimestampDispositivo: ahora,
			DispositivoID:        "disp-123",
			Integridad: marcaje.IntegridadDispositivo{
				MockLocation: true,
			},
		}
		res := marcaje.EvaluarMarcaje(req, ctxBase, ahora)
		if res.Resultado != marcaje.ResultadoRechazadoIntegridad || res.MotivoRechazo != marcaje.MotivoMockLocation {
			t.Errorf("esperado RECHAZADO_INTEGRIDAD por MOCK_LOCATION, obtuvo: %s (%s)", res.Resultado, res.MotivoRechazo)
		}
		if res.PasoFallido != marcaje.PasoIntegridadUbicacion {
			t.Errorf("esperado paso 7, obtuvo: %d", res.PasoFallido)
		}
	})

	t.Run("Caso Precision insuficiente — 62m con max 35m", func(t *testing.T) {
		ahora := inicio.Add(5 * time.Minute)
		req := marcaje.SolicitudMarcaje{
			SesionID:             "ses-1",
			UsuarioID:            "doc-1",
			RolMarcaje:           marcaje.RolDocente,
			Tipo:                 marcaje.TipoEntrada,
			Latitud:              centroide.Latitud(),
			Longitud:             centroide.Longitud(),
			PrecisionMetros:      62.0,
			TimestampDispositivo: ahora,
			DispositivoID:        "disp-123",
		}
		res := marcaje.EvaluarMarcaje(req, ctxBase, ahora)
		if res.Resultado != marcaje.ResultadoPrecisionInsuficiente {
			t.Errorf("esperado PRECISION_INSUFICIENTE, obtuvo: %s", res.Resultado)
		}
		if !res.PermiteReintento {
			t.Errorf("precision insuficiente debe permitir reintento")
		}
		if res.PasoFallido != marcaje.PasoPrecision {
			t.Errorf("esperado paso 6, obtuvo: %d", res.PasoFallido)
		}
	})
}
