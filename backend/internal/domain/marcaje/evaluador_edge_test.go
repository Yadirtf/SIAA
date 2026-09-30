package marcaje_test

import (
	"testing"
	"time"

	marcaje "github.com/siaa/backend/internal/domain/marcaje"
)

func TestEvaluarMarcaje_EdgeCases(t *testing.T) {
	ctx, inicio, centroide := armarContextoPrueba(t)

	t.Run("Caso Paso 1 — Usuario inactivo", func(t *testing.T) {
		ctxInactivo := ctx
		ctxInactivo.UsuarioActivo = false
		ahora := inicio.Add(5 * time.Minute)
		req := marcaje.SolicitudMarcaje{
			SesionID:        "ses-1",
			UsuarioID:       "doc-1",
			Tipo:            marcaje.TipoEntrada,
			Latitud:         centroide.Latitud(),
			Longitud:        centroide.Longitud(),
			PrecisionMetros: 10.0,
			DispositivoID:   "disp-123",
		}
		res := marcaje.EvaluarMarcaje(req, ctxInactivo, ahora)
		if res.PasoFallido != marcaje.PasoAutorizacion {
			t.Errorf("esperado paso 1, obtuvo: %d", res.PasoFallido)
		}
	})

	t.Run("Caso Paso 1 — Sin permiso marcaje:crear", func(t *testing.T) {
		ctxSinPermiso := ctx
		ctxSinPermiso.TienePermiso = false
		ahora := inicio.Add(5 * time.Minute)
		req := marcaje.SolicitudMarcaje{
			SesionID:        "ses-1",
			UsuarioID:       "doc-1",
			Tipo:            marcaje.TipoEntrada,
			Latitud:         centroide.Latitud(),
			Longitud:        centroide.Longitud(),
			PrecisionMetros: 10.0,
			DispositivoID:   "disp-123",
		}
		res := marcaje.EvaluarMarcaje(req, ctxSinPermiso, ahora)
		if res.PasoFallido != marcaje.PasoAutorizacion {
			t.Errorf("esperado paso 1, obtuvo: %d", res.PasoFallido)
		}
	})

	t.Run("Caso Paso 3 — Attestation exigida y fallida", func(t *testing.T) {
		ctxAtt := ctx
		ctxAtt.Parametros.ExigirAttestation = true
		ahora := inicio.Add(5 * time.Minute)
		req := marcaje.SolicitudMarcaje{
			SesionID:        "ses-1",
			UsuarioID:       "doc-1",
			Tipo:            marcaje.TipoEntrada,
			Latitud:         centroide.Latitud(),
			Longitud:        centroide.Longitud(),
			PrecisionMetros: 10.0,
			DispositivoID:   "disp-123",
			Integridad: marcaje.IntegridadDispositivo{
				AttestationOk: false,
			},
		}
		res := marcaje.EvaluarMarcaje(req, ctxAtt, ahora)
		if res.PasoFallido != marcaje.PasoAttestation || res.MotivoRechazo != marcaje.MotivoAttestationFallida {
			t.Errorf("esperado paso 3 attestation fallida, obtuvo: %d (%s)", res.PasoFallido, res.MotivoRechazo)
		}
	})

	t.Run("Caso Paso 4 — Sesion nil", func(t *testing.T) {
		ctxNil := ctx
		ctxNil.Sesion = nil
		ahora := inicio.Add(5 * time.Minute)
		req := marcaje.SolicitudMarcaje{
			SesionID:        "ses-1",
			UsuarioID:       "doc-1",
			Tipo:            marcaje.TipoEntrada,
			Latitud:         centroide.Latitud(),
			Longitud:        centroide.Longitud(),
			PrecisionMetros: 10.0,
			DispositivoID:   "disp-123",
		}
		res := marcaje.EvaluarMarcaje(req, ctxNil, ahora)
		if res.PasoFallido != marcaje.PasoAsignacion {
			t.Errorf("esperado paso 4 sin sesion, obtuvo: %d", res.PasoFallido)
		}
	})

	t.Run("Caso Paso 7 — Dispositivo rooteado bloqueado", func(t *testing.T) {
		ahora := inicio.Add(5 * time.Minute)
		req := marcaje.SolicitudMarcaje{
			SesionID:        "ses-1",
			UsuarioID:       "doc-1",
			Tipo:            marcaje.TipoEntrada,
			Latitud:         centroide.Latitud(),
			Longitud:        centroide.Longitud(),
			PrecisionMetros: 10.0,
			DispositivoID:   "disp-123",
			Integridad: marcaje.IntegridadDispositivo{
				Rooteado: true,
			},
		}
		res := marcaje.EvaluarMarcaje(req, ctx, ahora)
		if res.PasoFallido != marcaje.PasoIntegridadUbicacion || res.MotivoRechazo != marcaje.MotivoDispositivoComprometido {
			t.Errorf("esperado paso 7 por rooteado, obtuvo: %d (%s)", res.PasoFallido, res.MotivoRechazo)
		}
	})

	t.Run("Caso Marcaje de Salida — Dentro de holgura salida", func(t *testing.T) {
		ahoraFin := inicio.Add(2 * time.Hour).Add(5 * time.Minute)
		req := marcaje.SolicitudMarcaje{
			SesionID:        "ses-1",
			UsuarioID:       "doc-1",
			Tipo:            marcaje.TipoSalida,
			Latitud:         centroide.Latitud(),
			Longitud:        centroide.Longitud(),
			PrecisionMetros: 10.0,
			DispositivoID:   "disp-123",
		}
		res := marcaje.EvaluarMarcaje(req, ctx, ahoraFin)
		if res.Resultado != marcaje.ResultadoPresente {
			t.Errorf("salida dentro de holgura debe ser PRESENTE, obtuvo: %s (%s)", res.Resultado, res.Mensaje)
		}
	})
}

func TestMarcaje_EsAnulable(t *testing.T) {
	mActivo := marcaje.Marcaje{Anulado: false}
	if !mActivo.EsAnulable() {
		t.Errorf("marcaje no anulado debe ser anulable")
	}

	mAnulado := marcaje.Marcaje{Anulado: true}
	if mAnulado.EsAnulable() {
		t.Errorf("marcaje ya anulado no debe ser anulable")
	}
}

func TestGenerarMensaje_Cobertura(t *testing.T) {
	datos := marcaje.DatosMensaje{
		DistanciaMetros:       48.2,
		AulaNombre:            "A-301",
		MinutosDesviacion:     -10,
		MinutosRespectoInicio: 15,
		PrecisionRecibida:     60.0,
		PrecisionRequerida:    35.0,
		Hora:                  time.Now(),
	}

	_ = marcaje.GenerarMensaje(marcaje.ResultadoPresente, "", datos)
	_ = marcaje.GenerarMensaje(marcaje.ResultadoTardanza, "", datos)
	_ = marcaje.GenerarMensaje(marcaje.ResultadoRechazadoFueraDeArea, marcaje.MotivoFueraDeArea, datos)
	_ = marcaje.GenerarMensaje(marcaje.ResultadoRechazadoFueraHorario, marcaje.MotivoFueraDeHorario, datos)
	datos.MinutosDesviacion = 25
	_ = marcaje.GenerarMensaje(marcaje.ResultadoRechazadoFueraHorario, marcaje.MotivoFueraDeHorario, datos)
	_ = marcaje.GenerarMensaje(marcaje.ResultadoPrecisionInsuficiente, marcaje.MotivoPrecisionInsuficiente, datos)
	_ = marcaje.GenerarMensaje(marcaje.ResultadoRechazadoIntegridad, marcaje.MotivoMockLocation, datos)
	_ = marcaje.GenerarMensaje(marcaje.ResultadoRechazadoIntegridad, marcaje.MotivoDispositivoComprometido, datos)
	_ = marcaje.GenerarMensaje(marcaje.ResultadoRechazadoIntegridad, marcaje.MotivoAttestationFallida, datos)
	_ = marcaje.GenerarMensaje(marcaje.ResultadoRechazadoIntegridad, marcaje.MotivoDispositivoNoVinculado, datos)
	_ = marcaje.GenerarMensaje(marcaje.ResultadoRechazadoIntegridad, "", datos)
	_ = marcaje.GenerarMensaje(marcaje.ResultadoRechazadoSinAsignacion, marcaje.MotivoSinAsignacion, datos)
	_ = marcaje.GenerarMensaje(marcaje.ResultadoRechazadoVerificacion, marcaje.MotivoVerificacionFallida, datos)
	_ = marcaje.GenerarMensaje("OTRO", "", datos)
}
