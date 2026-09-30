// Package marcaje — motor determinista puro de validación de asistencia.
// Implementa el algoritmo RN-001 (11 pasos) conforme a §11 del backlog técnico.
// Cobertura exigida: >= 90 % (RNF-MAN-001, ADR-02, ADR-03).
package marcaje

import (
	"math"
	"strings"
	"time"

	"github.com/siaa/backend/internal/domain/geo"
)

// EvaluarMarcaje ejecuta los 11 pasos deterministas de validación sobre el contexto dado.
// Es una función pura: sin red, sin base de datos y con reloj inyectable.
func EvaluarMarcaje(entrada SolicitudMarcaje, ctx ContextoSesion, ahora time.Time) ResultadoEvaluacion {
	// ── PASO 1: AUTORIZACIÓN ──────────────────────────────────────────
	if !ctx.UsuarioActivo {
		return ResultadoEvaluacion{
			Resultado:   ResultadoRechazadoSinAsignacion,
			PasoFallido: PasoAutorizacion,
			Mensaje:     "Usuario inactivo o suspendido en el sistema.",
		}
	}
	if !ctx.TienePermiso {
		return ResultadoEvaluacion{
			Resultado:   ResultadoRechazadoSinAsignacion,
			PasoFallido: PasoAutorizacion,
			Mensaje:     "No posees el permiso necesario (marcaje:crear) para registrar asistencia.",
		}
	}

	// ── PASO 2: DISPOSITIVO VINCULADO ─────────────────────────────────
	// El dispositivo emisor debe coincidir exactamente con el dispositivo confiable registrado
	if ctx.DispositivoVinculadoID != "" && entrada.DispositivoID != ctx.DispositivoVinculadoID {
		return ResultadoEvaluacion{
			Resultado:        ResultadoRechazadoIntegridad,
			MotivoRechazo:    MotivoDispositivoNoVinculado,
			PasoFallido:      PasoDispositivo,
			PermiteReintento: false,
			PuedeJustificar:  true,
			Mensaje: GenerarMensaje(ResultadoRechazadoIntegridad, MotivoDispositivoNoVinculado, DatosMensaje{
				DispositivoEsperado: ctx.DispositivoVinculadoID,
				DispositivoRecibido: entrada.DispositivoID,
			}),
		}
	}

	// ── PASO 3: ATESTACIÓN DE APLICACIÓN ──────────────────────────────
	if ctx.Parametros.ExigirAttestation && !entrada.Integridad.AttestationOk {
		return ResultadoEvaluacion{
			Resultado:        ResultadoRechazadoIntegridad,
			MotivoRechazo:    MotivoAttestationFallida,
			PasoFallido:      PasoAttestation,
			PermiteReintento: false,
			PuedeJustificar:  true,
			Mensaje:          GenerarMensaje(ResultadoRechazadoIntegridad, MotivoAttestationFallida, DatosMensaje{}),
		}
	}

	// ── PASO 4: ASIGNACIÓN ACADÉMICA ──────────────────────────────────
	if ok, resAsign := evaluarAsignacion(entrada, ctx.Sesion, ahora); !ok {
		return resAsign
	}

	// ── PASO 5: VENTANA TEMPORAL ──────────────────────────────────────
	var ventanaAbre, ventanaCierra time.Time
	if entrada.RolMarcaje == RolEstudiante && ctx.Sesion.VentanaEstudiantilAbierta {
		ventanaAbre = ctx.Sesion.InicioProgramado
		ventanaCierra = ctx.Sesion.VentanaEstudiantilCierra
	} else if entrada.Tipo == TipoSalida {
		ventanaAbre = ctx.Sesion.FinProgramado.Add(-time.Duration(ctx.Parametros.HolguraSalidaAntesMin) * time.Minute)
		ventanaCierra = ctx.Sesion.FinProgramado.Add(time.Duration(ctx.Parametros.HolguraSalidaDespuesMin) * time.Minute)
	} else {
		ventanaAbre = ctx.Sesion.InicioProgramado.Add(-time.Duration(ctx.Parametros.HolguraEntradaAntesMin) * time.Minute)
		ventanaCierra = ctx.Sesion.InicioProgramado.Add(time.Duration(ctx.Parametros.HolguraEntradaDespuesMin) * time.Minute)
	}

	// Intervalo cerrado [ventanaAbre, ventanaCierra] (§11.4: bordes exactos son válidos)
	if ahora.Before(ventanaAbre) || ahora.After(ventanaCierra) {
		minutosDesv := int(math.Round(ahora.Sub(ctx.Sesion.InicioProgramado).Minutes()))
		return ResultadoEvaluacion{
			Resultado:             ResultadoRechazadoFueraHorario,
			MotivoRechazo:         MotivoFueraDeHorario,
			PasoFallido:           PasoVentanaTemporal,
			MinutosDesviacion:     minutosDesv,
			MinutosRespectoInicio: minutosDesv,
			PermiteReintento:      false,
			PuedeJustificar:       true,
			Mensaje: GenerarMensaje(ResultadoRechazadoFueraHorario, MotivoFueraDeHorario, DatosMensaje{
				MinutosDesviacion: minutosDesv,
				VentanaAbre:       ventanaAbre,
				VentanaCierra:     ventanaCierra,
			}),
		}
	}

	// ── PASO 6: PRECISIÓN GPS ─────────────────────────────────────────
	maxPrecision := ctx.Parametros.PrecisionGpsMaxMetros
	if maxPrecision <= 0 {
		maxPrecision = 35.0
	}
	if entrada.PrecisionMetros > maxPrecision {
		return ResultadoEvaluacion{
			Resultado:          ResultadoPrecisionInsuficiente,
			MotivoRechazo:      MotivoPrecisionInsuficiente,
			PasoFallido:        PasoPrecision,
			PrecisionRecibida:  entrada.PrecisionMetros,
			PrecisionRequerida: maxPrecision,
			PermiteReintento:   true, // No persiste, no consume idempotencia
			PuedeJustificar:    false,
			Mensaje: GenerarMensaje(ResultadoPrecisionInsuficiente, MotivoPrecisionInsuficiente, DatosMensaje{
				PrecisionRecibida:  entrada.PrecisionMetros,
				PrecisionRequerida: maxPrecision,
			}),
		}
	}

	// ── PASO 7: INTEGRIDAD DE UBICACIÓN ───────────────────────────────
	if ctx.Parametros.BloquearMockLocation && entrada.Integridad.MockLocation {
		return ResultadoEvaluacion{
			Resultado:        ResultadoRechazadoIntegridad,
			MotivoRechazo:    MotivoMockLocation,
			PasoFallido:      PasoIntegridadUbicacion,
			PermiteReintento: false,
			PuedeJustificar:  true,
			Mensaje:          GenerarMensaje(ResultadoRechazadoIntegridad, MotivoMockLocation, DatosMensaje{}),
		}
	}
	if ctx.Parametros.BloquearRooteado && (entrada.Integridad.Rooteado || entrada.Integridad.Emulador) {
		return ResultadoEvaluacion{
			Resultado:        ResultadoRechazadoIntegridad,
			MotivoRechazo:    MotivoDispositivoComprometido,
			PasoFallido:      PasoIntegridadUbicacion,
			PermiteReintento: false,
			PuedeJustificar:  true,
			Mensaje:          GenerarMensaje(ResultadoRechazadoIntegridad, MotivoDispositivoComprometido, DatosMensaje{}),
		}
	}

	// ── PASO 8: CONTENCIÓN GEOESPACIAL ────────────────────────────────
	esVirtual := strings.ToUpper(ctx.Sesion.Modalidad) == "VIRTUAL"
	var distancia float64

	if !esVirtual {
		// Validar rangos WGS84 para detectar coordenadas invertidas (ADR-04, §11.4)
		if entrada.Latitud < -90.0 || entrada.Latitud > 90.0 || entrada.Longitud < -180.0 || entrada.Longitud > 180.0 {
			return ResultadoEvaluacion{
				Resultado:        ResultadoRechazadoIntegridad,
				MotivoRechazo:    MotivoDispositivoComprometido,
				PasoFallido:      PasoContencionGeoespacial,
				PermiteReintento: false,
				PuedeJustificar:  false,
				Mensaje:          "Coordenadas geográficas inválidas o fuera de rango.",
			}
		}

		punto, errPt := geo.NewGeoPoint(entrada.Longitud, entrada.Latitud) // [longitud, latitud]
		if errPt != nil {
			return ResultadoEvaluacion{
				Resultado:        ResultadoRechazadoIntegridad,
				MotivoRechazo:    MotivoDispositivoComprometido,
				PasoFallido:      PasoContencionGeoespacial,
				PermiteReintento: false,
				Mensaje:          "Coordenadas geográficas inválidas.",
			}
		}

		// Evaluar contención contra la geometría con buffer precalculado
		if !geo.ContienePunto(ctx.GeometriaBuffer, punto) {
			distancia = geo.DistanciaAlPoligono(ctx.Geometria, punto)
			return ResultadoEvaluacion{
				Resultado:        ResultadoRechazadoFueraDeArea,
				MotivoRechazo:    MotivoFueraDeArea,
				PasoFallido:      PasoContencionGeoespacial,
				DistanciaMetros:  math.Round(distancia*10) / 10,
				PermiteReintento: false,
				PuedeJustificar:  true,
				Mensaje: GenerarMensaje(ResultadoRechazadoFueraDeArea, MotivoFueraDeArea, DatosMensaje{
					DistanciaMetros: distancia,
					AulaNombre:      ctx.Sesion.EspacioCodigo,
				}),
			}
		}
	}

	// ── PASO 9: VERIFICACIÓN COMPLEMENTARIA ───────────────────────────
	if !esVirtual && ctx.VerificacionExigida {
		if entrada.VerificacionComplementaria == nil || !contieneString(ctx.ValoresVerificacionValidos, entrada.VerificacionComplementaria.Valor) {
			return ResultadoEvaluacion{
				Resultado:        ResultadoRechazadoVerificacion,
				MotivoRechazo:    MotivoVerificacionFallida,
				PasoFallido:      PasoVerificacionComplement,
				PermiteReintento: true,
				PuedeJustificar:  true,
				Mensaje:          GenerarMensaje(ResultadoRechazadoVerificacion, MotivoVerificacionFallida, DatosMensaje{}),
			}
		}
	}

	// ── PASO 10: IDEMPOTENCIA ─────────────────────────────────────────
	if ctx.MarcajePrevio != nil && !ctx.MarcajePrevio.Anulado {
		return ResultadoEvaluacion{
			Resultado:             ctx.MarcajePrevio.Resultado,
			MotivoRechazo:         MotivoRechazo(ctx.MarcajePrevio.MotivoRechazo),
			PasoFallido:           ctx.MarcajePrevio.PasoFallido,
			Mensaje:               "Marcaje previo recuperado exitosamente.",
			DistanciaMetros:       ctx.MarcajePrevio.DistanciaMetros,
			MinutosRespectoInicio: ctx.MarcajePrevio.MinutosRespectoInicio,
			PermiteReintento:      false,
			PuedeJustificar:       ctx.MarcajePrevio.RequiereJustificacion(),
			MarcajeExistenteID:    ctx.MarcajePrevio.ID,
		}
	}

	// ── PASO 11: CLASIFICACIÓN ────────────────────────────────────────
	minutosRespectoInicio := int(math.Round(ahora.Sub(ctx.Sesion.InicioProgramado).Minutes()))
	desfaseSegundos := int(math.Abs(ahora.Sub(entrada.TimestampDispositivo).Seconds()))
	esAnomalia := false
	maxDesfase := ctx.Parametros.DesfaseRelojMaxSegundos
	if maxDesfase <= 0 {
		maxDesfase = 300 // 5 minutos por defecto
	}
	if desfaseSegundos > maxDesfase {
		esAnomalia = true
	}

	var resultadoFinal ResultadoMarcaje
	if entrada.Tipo == TipoSalida {
		resultadoFinal = ResultadoPresente
	} else {
		umbralTardanza := ctx.Parametros.UmbralTardanzaMin
		if umbralTardanza <= 0 {
			umbralTardanza = 10
		}
		if minutosRespectoInicio <= umbralTardanza {
			resultadoFinal = ResultadoPresente
		} else {
			resultadoFinal = ResultadoTardanza
		}
	}

	return ResultadoEvaluacion{
		Resultado:             resultadoFinal,
		Mensaje:               GenerarMensaje(resultadoFinal, "", DatosMensaje{MinutosRespectoInicio: minutosRespectoInicio, Hora: ahora}),
		DistanciaMetros:       distancia,
		MinutosRespectoInicio: minutosRespectoInicio,
		PermiteReintento:      false,
		PuedeJustificar:       false,
		DesfaseRelojSegundos:  desfaseSegundos,
		EsAnomalia:            esAnomalia,
	}
}

func contieneString(lista []string, objetivo string) bool {
	for _, item := range lista {
		if item == objetivo {
			return true
		}
	}
	return false
}
