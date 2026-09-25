// Package marcaje — caso de uso para procesamiento y registro de marcaje.
// Satisface US-MAR-01, US-MAR-03, US-MAR-04, US-MAR-05, US-MAR-10.
package marcaje

import (
	"context"
	"fmt"
	"time"

	"github.com/siaa/backend/internal/domain/geo"
	domainMarcaje "github.com/siaa/backend/internal/domain/marcaje"
	"github.com/siaa/backend/internal/platform/metrics"
	"github.com/siaa/backend/internal/repository"
)

// CrearMarcajeUseCase coordina la evaluación pura, verificación de integridad y persistencia.
type CrearMarcajeUseCase struct {
	marcajeRepo     repository.MarcajeRepository
	sesionRepo      repository.SesionRepository
	espacioRepo     repository.EspacioRepository
	dispositivoRepo repository.DispositivoRepository
	auditoriaRepo   repository.AuditoriaRepository
	metrics         *metrics.Collector
}

// NewCrearMarcajeUseCase construye el caso de uso con sus dependencias.
func NewCrearMarcajeUseCase(
	marcajeRepo repository.MarcajeRepository,
	sesionRepo repository.SesionRepository,
	espacioRepo repository.EspacioRepository,
	dispositivoRepo repository.DispositivoRepository,
	auditoriaRepo repository.AuditoriaRepository,
	m *metrics.Collector,
) *CrearMarcajeUseCase {
	return &CrearMarcajeUseCase{
		marcajeRepo:     marcajeRepo,
		sesionRepo:      sesionRepo,
		espacioRepo:     espacioRepo,
		dispositivoRepo: dispositivoRepo,
		auditoriaRepo:   auditoriaRepo,
		metrics:         m,
	}
}

// Ejecutar ensambla el contexto en una ronda de consultas y ejecuta el motor determinista.
func (uc *CrearMarcajeUseCase) Ejecutar(ctx context.Context, req domainMarcaje.SolicitudMarcaje, ahora time.Time) (*domainMarcaje.ResultadoEvaluacion, *domainMarcaje.Marcaje, error) {
	if ahora.IsZero() {
		ahora = time.Now().UTC()
	}

	// 1. Armar contexto en una sola ronda de consultas (T-MAR-03.4)
	contexto, err := uc.armarContexto(ctx, req, ahora)
	if err != nil {
		return nil, nil, err
	}

	// 2. Detección de saltos imposibles entre marcajes consecutivos (US-MAR-10 AC-04)
	uc.verificarSaltoImposible(ctx, req, contexto, ahora)

	// 3. Evaluar deterministamente con la función pura de dominio
	res := domainMarcaje.EvaluarMarcaje(req, *contexto, ahora)

	// 4. Si el resultado es PRECISION_INSUFICIENTE, no persiste ni consume idempotencia (Paso 6, AC-07)
	if res.Resultado == domainMarcaje.ResultadoPrecisionInsuficiente {
		if uc.metrics != nil {
			uc.metrics.RecordMarcajeResultado(string(res.Resultado))
		}
		return &res, nil, nil
	}

	// 5. Si fue resuelto por idempotencia en memoria, recuperar registro
	if res.MarcajeExistenteID != "" {
		existente, _ := uc.marcajeRepo.ObtenerPorID(ctx, res.MarcajeExistenteID)
		if uc.metrics != nil {
			uc.metrics.RecordMarcajeResultado(string(res.Resultado))
		}
		return &res, existente, nil
	}

	// 6. Construir entidad inmutable con evidencia técnica completa (US-MAR-04)
	m := uc.construirEntidadMarcaje(req, res, contexto, ahora)

	// 7. Persistir en MongoDB (maneja duplicados concurrentes de forma transparente - ADR-07)
	if err := uc.marcajeRepo.Crear(ctx, m); err != nil {
		return nil, nil, fmt.Errorf("error persistiendo evidencia de marcaje: %w", err)
	}

	// 8. Métricas y auditoría
	if uc.metrics != nil {
		uc.metrics.RecordMarcajeResultado(string(res.Resultado))
	}
	uc.registrarAuditoria(ctx, req, res, m)

	return &res, m, nil
}

func (uc *CrearMarcajeUseCase) armarContexto(ctx context.Context, req domainMarcaje.SolicitudMarcaje, ahora time.Time) (*domainMarcaje.ContextoSesion, error) {
	contexto := &domainMarcaje.ContextoSesion{
		UsuarioActivo: true,
		TienePermiso:  true,
		Parametros: domainMarcaje.ParametrosMarcaje{
			HolguraEntradaAntesMin:   15,
			HolguraEntradaDespuesMin: 15,
			HolguraSalidaAntesMin:    10,
			HolguraSalidaDespuesMin:  15,
			PrecisionGpsMaxMetros:    35.0,
			UmbralTardanzaMin:        10,
			BloquearMockLocation:     true,
			BloquearRooteado:         true,
			DesfaseRelojMaxSegundos:  300,
		},
	}

	// Consultar sesión
	if req.SesionID != "" {
		s, err := uc.sesionRepo.FindByID(ctx, req.SesionID)
		if err == nil && s != nil {
			contexto.Sesion = &domainMarcaje.SesionInfo{
				ID:               s.ID(),
				EspacioID:        s.EspacioID(),
				DocenteIDs:       s.DocenteIDs(),
				InicioProgramado: s.InicioProgramado(),
				FinProgramado:    s.FinProgramado(),
				Modalidad:        "PRESENCIAL",
			}

			// Geometría y buffer desde la sesión o espacio
			if s.GeometriaSnapshot() != nil {
				contexto.Geometria = *s.GeometriaSnapshot()
			}
			if s.GeometriaBufferSnapshot() != nil {
				contexto.GeometriaBuffer = *s.GeometriaBufferSnapshot()
			}

			// Si el buffer no estaba congelado, consultar espacio en vivo
			if len(contexto.GeometriaBuffer.Vertices()) < 4 && s.EspacioID() != "" {
				esp, errEsp := uc.espacioRepo.FindByID(ctx, s.EspacioID())
				if errEsp == nil && esp != nil {
					if esp.Geometria != nil {
						contexto.Geometria = *esp.Geometria
					}
					if esp.GeometriaBuffer != nil {
						contexto.GeometriaBuffer = *esp.GeometriaBuffer
					}
					contexto.Sesion.EspacioCodigo = esp.Codigo
				}
			}
		}
	}

	// Dispositivo confiable vinculado
	if req.UsuarioID != "" {
		disps, errDisp := uc.dispositivoRepo.FindByUsuario(ctx, req.UsuarioID)
		if errDisp == nil && len(disps) > 0 {
			for _, d := range disps {
				if d.Confiable && !d.PendienteAprobacion && d.RevocadoEn == nil {
					contexto.DispositivoVinculadoID = d.InstalacionID
					break
				}
			}
		}
	}

	// Marcaje previo existente (idempotencia)
	if req.SesionID != "" && req.UsuarioID != "" && req.Tipo != "" {
		previo, _ := uc.marcajeRepo.ObtenerPrevio(ctx, req.SesionID, req.UsuarioID, req.Tipo)
		contexto.MarcajePrevio = previo
	}

	return contexto, nil
}

func (uc *CrearMarcajeUseCase) verificarSaltoImposible(ctx context.Context, req domainMarcaje.SolicitudMarcaje, contexto *domainMarcaje.ContextoSesion, ahora time.Time) {
	if req.UsuarioID == "" || req.Latitud == 0 || req.Longitud == 0 {
		return
	}
	ultimo, err := uc.marcajeRepo.ObtenerUltimoMarcajeUsuario(ctx, req.UsuarioID)
	if err == nil && ultimo != nil && len(ultimo.Geolocalizacion.Coordenadas) == 2 {
		deltaTiempo := ahora.Sub(ultimo.TimestampServidor)
		if deltaTiempo > 0 && deltaTiempo < 10*time.Minute {
			p1, err1 := geo.NewGeoPoint(ultimo.Geolocalizacion.Coordenadas[0], ultimo.Geolocalizacion.Coordenadas[1])
			p2, err2 := geo.NewGeoPoint(req.Longitud, req.Latitud)
			if err1 == nil && err2 == nil {
				distMetros := geo.CalcularDistanciaHaversine(p1, p2)
				velocidadKmh := (distMetros / 1000.0) / (deltaTiempo.Hours())
				if velocidadKmh > 120.0 { // Salto físicamente imposible en entorno urbano
					if uc.auditoriaRepo != nil {
						_ = uc.auditoriaRepo.Create(ctx, &repository.AuditEntry{
							Entidad:    "marcajes",
							Accion:     "ALERTA_SALTO_IMPOSIBLE",
							ActorID:    req.UsuarioID,
							IPOrigen:   req.DispositivoID,
							ValorNuevo: fmt.Sprintf("Velocidad detectada: %.1f km/h entre marcajes (%.0f m en %.1f min)", velocidadKmh, distMetros, deltaTiempo.Minutes()),
							CreadoEn:   ahora,
						})
					}
				}
			}
		}
	}
}

func (uc *CrearMarcajeUseCase) construirEntidadMarcaje(req domainMarcaje.SolicitudMarcaje, res domainMarcaje.ResultadoEvaluacion, ctx *domainMarcaje.ContextoSesion, ahora time.Time) *domainMarcaje.Marcaje {
	origen := req.Origen
	if origen == "" {
		origen = domainMarcaje.OrigenAppMovil
	}

	espacioID := ""
	if ctx.Sesion != nil {
		espacioID = ctx.Sesion.EspacioID
	}

	return &domainMarcaje.Marcaje{
		SesionID:              req.SesionID,
		UsuarioID:             req.UsuarioID,
		DocenteID:             req.UsuarioID,
		EspacioID:             espacioID,
		RolMarcaje:            req.RolMarcaje,
		Tipo:                  req.Tipo,
		Resultado:             res.Resultado,
		MotivoRechazo:         string(res.MotivoRechazo),
		PasoFallido:           res.PasoFallido,
		DistanciaMetros:       res.DistanciaMetros,
		ContenidoEnBuffer:     res.Resultado == domainMarcaje.ResultadoPresente || res.Resultado == domainMarcaje.ResultadoTardanza,
		TimestampServidor:     ahora,
		TimestampDispositivo:  req.TimestampDispositivo,
		Timestamp:             ahora,
		DesfaseRelojSegundos:  res.DesfaseRelojSegundos,
		MinutosRespectoInicio: res.MinutosRespectoInicio,
		DiferenciaMinutos:     res.MinutosRespectoInicio,
		Geolocalizacion: domainMarcaje.TelemetriaGPS{
			Coordenadas:           []float64{req.Longitud, req.Latitud}, // [longitud, latitud]
			PrecisionMetros:       req.PrecisionMetros,
			MetodoCaptura:         "FUSED_LOCATION",
			MockLocationDetectado: req.Integridad.MockLocation,
		},
		Dispositivo: domainMarcaje.DispositivoMarcaje{
			ID:            req.DispositivoID,
			Modelo:        req.ModeloDispositivo,
			SO:            req.SODispositivo,
			VersionApp:    req.VersionApp,
			Rooteado:      req.Integridad.Rooteado,
			Emulador:      req.Integridad.Emulador,
			AttestationOk: req.Integridad.AttestationOk,
		},
		VerificacionComplement: req.VerificacionComplementaria,
		Origen:                 origen,
		Anulado:                false,
		EsAnomalia:             res.EsAnomalia,
		IdempotencyKey:         req.IdempotencyKey,
		CreadoEn:               ahora,
	}
}

func (uc *CrearMarcajeUseCase) registrarAuditoria(ctx context.Context, req domainMarcaje.SolicitudMarcaje, res domainMarcaje.ResultadoEvaluacion, m *domainMarcaje.Marcaje) {
	if uc.auditoriaRepo == nil {
		return
	}
	// Auditar rechazos de integridad y anomalías
	if res.Resultado == domainMarcaje.ResultadoRechazadoIntegridad || res.EsAnomalia {
		_ = uc.auditoriaRepo.Create(ctx, &repository.AuditEntry{
			Entidad:    "marcajes",
			EntidadID:  m.ID,
			Accion:     "MARCAJE_ANOMALIA_SEGURIDAD",
			ActorID:    req.UsuarioID,
			IPOrigen:   req.DispositivoID,
			ValorNuevo: fmt.Sprintf("Resultado: %s, Motivo: %s, Desfase: %ds", res.Resultado, res.MotivoRechazo, res.DesfaseRelojSegundos),
			CreadoEn:   m.TimestampServidor,
		})
	}
}
