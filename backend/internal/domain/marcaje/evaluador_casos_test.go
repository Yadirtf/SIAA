package marcaje_test

import (
	"testing"
	"time"

	marcaje "github.com/siaa/backend/internal/domain/marcaje"
)

func TestEvaluarMarcaje_CasosAdicionales(t *testing.T) {
	ctxBase, inicio, centroide := armarContextoPrueba(t)

	t.Run("Caso Idempotencia — Devuelve marcaje previo existente", func(t *testing.T) {
		ahora := inicio.Add(5 * time.Minute)
		ctxConPrevio := ctxBase
		ctxConPrevio.MarcajePrevio = &marcaje.Marcaje{
			ID:                    "marc-existente-1",
			Resultado:             marcaje.ResultadoPresente,
			MinutosRespectoInicio: 5,
			Anulado:               false,
		}
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
		res := marcaje.EvaluarMarcaje(req, ctxConPrevio, ahora)
		if res.MarcajeExistenteID != "marc-existente-1" {
			t.Errorf("esperado id 'marc-existente-1', obtuvo: %s", res.MarcajeExistenteID)
		}
		if res.Resultado != marcaje.ResultadoPresente {
			t.Errorf("esperado resultado del previo PRESENTE, obtuvo: %s", res.Resultado)
		}
	})

	t.Run("Caso Dispositivo ajeno — No coincide con vinculado", func(t *testing.T) {
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
			DispositivoID:        "otro-telefono",
		}
		res := marcaje.EvaluarMarcaje(req, ctxBase, ahora)
		if res.Resultado != marcaje.ResultadoRechazadoIntegridad || res.MotivoRechazo != marcaje.MotivoDispositivoNoVinculado {
			t.Errorf("esperado RECHAZADO_INTEGRIDAD por DISPOSITIVO_NO_VINCULADO, obtuvo: %s (%s)", res.Resultado, res.MotivoRechazo)
		}
		if res.PasoFallido != marcaje.PasoDispositivo {
			t.Errorf("esperado paso 2, obtuvo: %d", res.PasoFallido)
		}
	})

	t.Run("Caso Modalidad Virtual — Omite pasos geoespaciales", func(t *testing.T) {
		ahora := inicio.Add(5 * time.Minute)
		ctxVirtual := ctxBase
		ctxVirtual.Sesion = &marcaje.SesionInfo{
			ID:               "ses-virt",
			DocenteIDs:       []string{"doc-1"},
			InicioProgramado: inicio,
			FinProgramado:    inicio.Add(2 * time.Hour),
			Modalidad:        "VIRTUAL",
		}
		req := marcaje.SolicitudMarcaje{
			SesionID:             "ses-virt",
			UsuarioID:            "doc-1",
			RolMarcaje:           marcaje.RolDocente,
			Tipo:                 marcaje.TipoEntrada,
			Latitud:              0.0,
			Longitud:             0.0,
			PrecisionMetros:      5.0,
			TimestampDispositivo: ahora,
			DispositivoID:        "disp-123",
		}
		res := marcaje.EvaluarMarcaje(req, ctxVirtual, ahora)
		if res.Resultado != marcaje.ResultadoPresente {
			t.Errorf("en virtual con hora valida debe clasificar como PRESENTE, obtuvo: %s", res.Resultado)
		}
	})

	t.Run("Caso Coordenadas invertidas — Latitud > 90 o Longitud > 180", func(t *testing.T) {
		ahora := inicio.Add(5 * time.Minute)
		req := marcaje.SolicitudMarcaje{
			SesionID:             "ses-1",
			UsuarioID:            "doc-1",
			RolMarcaje:           marcaje.RolDocente,
			Tipo:                 marcaje.TipoEntrada,
			Latitud:              150.0,
			Longitud:             -74.0815,
			PrecisionMetros:      10.0,
			TimestampDispositivo: ahora,
			DispositivoID:        "disp-123",
		}
		res := marcaje.EvaluarMarcaje(req, ctxBase, ahora)
		if res.Resultado != marcaje.ResultadoRechazadoIntegridad {
			t.Errorf("coordenadas invertidas/invalidas deben ser rechazadas por integridad, obtuvo: %s", res.Resultado)
		}
	})

	t.Run("Caso Apertura exacta e Cierre exacto", func(t *testing.T) {
		abre := inicio.Add(-15 * time.Minute)
		cierra := inicio.Add(15 * time.Minute)

		reqAbre := marcaje.SolicitudMarcaje{
			SesionID:             "ses-1",
			UsuarioID:            "doc-1",
			RolMarcaje:           marcaje.RolDocente,
			Tipo:                 marcaje.TipoEntrada,
			Latitud:              centroide.Latitud(),
			Longitud:             centroide.Longitud(),
			PrecisionMetros:      10.0,
			TimestampDispositivo: abre,
			DispositivoID:        "disp-123",
		}
		resAbre := marcaje.EvaluarMarcaje(reqAbre, ctxBase, abre)
		if resAbre.Resultado != marcaje.ResultadoPresente {
			t.Errorf("apertura exacta debe ser aceptada, obtuvo: %s", resAbre.Resultado)
		}

		reqCierra := reqAbre
		reqCierra.TimestampDispositivo = cierra
		resCierra := marcaje.EvaluarMarcaje(reqCierra, ctxBase, cierra)
		if resCierra.Resultado != marcaje.ResultadoTardanza {
			t.Errorf("cierre exacto a min 15 con tardanza 10 debe ser TARDANZA, obtuvo: %s", resCierra.Resultado)
		}
	})

	t.Run("Caso Suplente designado — Suplente marca OK, Titular es rechazado", func(t *testing.T) {
		ctxSuplente, inicio, centroide := armarContextoPrueba(t)
		ahora := inicio.Add(5 * time.Minute)
		ctxSuplente.Sesion.SuplenteID = "doc-suplente"

		reqSuplente := marcaje.SolicitudMarcaje{
			SesionID:             "ses-1",
			UsuarioID:            "doc-suplente",
			RolMarcaje:           marcaje.RolDocente,
			Tipo:                 marcaje.TipoEntrada,
			Latitud:              centroide.Latitud(),
			Longitud:             centroide.Longitud(),
			PrecisionMetros:      10.0,
			TimestampDispositivo: ahora,
			DispositivoID:        "disp-123",
		}
		resSuplente := marcaje.EvaluarMarcaje(reqSuplente, ctxSuplente, ahora)
		if resSuplente.Resultado != marcaje.ResultadoPresente {
			t.Errorf("suplente debe ser aceptado, obtuvo: %s", resSuplente.Resultado)
		}

		reqTitular := reqSuplente
		reqTitular.UsuarioID = "doc-1"
		resTitular := marcaje.EvaluarMarcaje(reqTitular, ctxSuplente, ahora)
		if resTitular.Resultado != marcaje.ResultadoRechazadoSinAsignacion {
			t.Errorf("titular habiendo suplente debe recibir RECHAZADO_SIN_ASIGNACION, obtuvo: %s", resTitular.Resultado)
		}
	})

	t.Run("Caso Marcaje Estudiantil — Grupo autorizado y ventana", func(t *testing.T) {
		ctxEst, inicio, centroide := armarContextoPrueba(t)
		ahora := inicio.Add(30 * time.Minute)
		ctxEst.Sesion.VentanaEstudiantilAbierta = true
		ctxEst.Sesion.VentanaEstudiantilCierra = inicio.Add(45 * time.Minute)

		reqEstValido := marcaje.SolicitudMarcaje{
			SesionID:             "ses-1",
			UsuarioID:            "est-1",
			RolMarcaje:           marcaje.RolEstudiante,
			Tipo:                 marcaje.TipoEntrada,
			Latitud:              centroide.Latitud(),
			Longitud:             centroide.Longitud(),
			PrecisionMetros:      10.0,
			TimestampDispositivo: ahora,
			DispositivoID:        "disp-123",
		}
		resEstValido := marcaje.EvaluarMarcaje(reqEstValido, ctxEst, ahora)
		if resEstValido.Resultado != marcaje.ResultadoTardanza && resEstValido.Resultado != marcaje.ResultadoPresente {
			t.Errorf("estudiante valido debe ser clasificado, obtuvo: %s", resEstValido.Resultado)
		}

		reqEstAjeno := reqEstValido
		reqEstAjeno.UsuarioID = "est-no-matriculado"
		resEstAjeno := marcaje.EvaluarMarcaje(reqEstAjeno, ctxEst, ahora)
		if resEstAjeno.Resultado != marcaje.ResultadoRechazadoSinAsignacion {
			t.Errorf("estudiante no matriculado debe ser RECHAZADO_SIN_ASIGNACION, obtuvo: %s", resEstAjeno.Resultado)
		}

		ctxEstCerrada, _, _ := armarContextoPrueba(t)
		ctxEstCerrada.Sesion.VentanaEstudiantilAbierta = false
		resEstCerrada := marcaje.EvaluarMarcaje(reqEstValido, ctxEstCerrada, ahora)
		if resEstCerrada.Resultado != marcaje.ResultadoRechazadoFueraHorario {
			t.Errorf("ventana estudiantil cerrada debe rechazar por horario, obtuvo: %s", resEstCerrada.Resultado)
		}
	})

	t.Run("Caso Verificacion Complementaria QR/WiFi", func(t *testing.T) {
		ctxVerif, inicio, centroide := armarContextoPrueba(t)
		ahora := inicio.Add(5 * time.Minute)
		ctxVerif.VerificacionExigida = true
		ctxVerif.ValoresVerificacionValidos = []string{"BSSID-AULA-1", "QR-SECRETO-AULA"}

		reqOk := marcaje.SolicitudMarcaje{
			SesionID:             "ses-1",
			UsuarioID:            "doc-1",
			RolMarcaje:           marcaje.RolDocente,
			Tipo:                 marcaje.TipoEntrada,
			Latitud:              centroide.Latitud(),
			Longitud:             centroide.Longitud(),
			PrecisionMetros:      10.0,
			TimestampDispositivo: ahora,
			DispositivoID:        "disp-123",
			VerificacionComplementaria: &marcaje.VerificacionEntrada{
				Metodo: "WIFI",
				Valor:  "BSSID-AULA-1",
			},
		}
		resOk := marcaje.EvaluarMarcaje(reqOk, ctxVerif, ahora)
		if resOk.Resultado != marcaje.ResultadoPresente {
			t.Errorf("verificacion valida debe resultar en PRESENTE, obtuvo: %s", resOk.Resultado)
		}

		reqErr := reqOk
		reqErr.VerificacionComplementaria = &marcaje.VerificacionEntrada{
			Metodo: "WIFI",
			Valor:  "OTRO-BSSID",
		}
		resErr := marcaje.EvaluarMarcaje(reqErr, ctxVerif, ahora)
		if resErr.Resultado != marcaje.ResultadoRechazadoVerificacion {
			t.Errorf("verificacion incorrecta debe ser RECHAZADO_VERIFICACION, obtuvo: %s", resErr.Resultado)
		}
	})

	t.Run("Caso Desfase de Reloj — Detecta anomalia si supera umbral", func(t *testing.T) {
		ctxDesfase, inicio, centroide := armarContextoPrueba(t)
		ahora := inicio.Add(5 * time.Minute)
		timestampRelojAdelantado := ahora.Add(10 * time.Minute)
		req := marcaje.SolicitudMarcaje{
			SesionID:             "ses-1",
			UsuarioID:            "doc-1",
			RolMarcaje:           marcaje.RolDocente,
			Tipo:                 marcaje.TipoEntrada,
			Latitud:              centroide.Latitud(),
			Longitud:             centroide.Longitud(),
			PrecisionMetros:      10.0,
			TimestampDispositivo: timestampRelojAdelantado,
			DispositivoID:        "disp-123",
		}
		res := marcaje.EvaluarMarcaje(req, ctxDesfase, ahora)
		if !res.EsAnomalia {
			t.Errorf("se esperaba que el desfase de 600s fuera marcado como anomalia")
		}
		if res.DesfaseRelojSegundos < 590 {
			t.Errorf("desfase segundos esperado ~600, obtuvo: %d", res.DesfaseRelojSegundos)
		}
	})
}
