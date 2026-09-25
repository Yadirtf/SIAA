// Package academico — Generador masivo de sesiones de clase (US-ACA-05).
// Satisface US-ACA-05 (AC-01..AC-07), RF-ACA-007, RF-PAR-006, SRS §4.2 y §6.4.
package academico

import (
	"context"
	"fmt"
	"time"

	"github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/domain/geo"
	"github.com/siaa/backend/internal/domain/parametro"
	"github.com/siaa/backend/internal/domain/shared"
	applog "github.com/siaa/backend/internal/platform/log"
)

// (Los DTOs GenerarSesionesCmd, InformeGeneracionDTO, etc. residen en generador_helpers.go)

// GenerarSesiones ejecuta el algoritmo central de generación de sesiones (US-ACA-05).
func (s *Service) GenerarSesiones(ctx context.Context, cmd GenerarSesionesCmd) (*InformeGeneracionDTO, error) {
	inicioT := time.Now()

	// 1. Validar y recuperar periodo académico
	periodo, err := s.periodoRepo.GetByID(ctx, cmd.PeriodoID)
	if err != nil || periodo == nil {
		return nil, shared.NewNotFoundError("Periodo", cmd.PeriodoID)
	}

	if periodo.Estado() == academico.EstadoCerrado {
		return nil, academico.ErrPeriodoCerradoModif
	}

	// 2. Recuperar excepciones del calendario activas para la sede / global
	excepciones, err := s.excepcionRepo.ListByRango(ctx, periodo.FechaInicio(), periodo.FechaFin())
	if err != nil {
		s.log.Warn("no se pudieron cargar excepciones de calendario", applog.Err(err))
	}

	// 3. Recuperar asignaciones del periodo
	var asignaciones []*academico.Asignacion
	if cmd.AsignacionID != nil && *cmd.AsignacionID != "" {
		asig, errAsig := s.asignacionRepo.GetByID(ctx, *cmd.AsignacionID)
		if errAsig != nil || asig == nil {
			return nil, shared.NewNotFoundError("Asignacion", *cmd.AsignacionID)
		}
		asignaciones = []*academico.Asignacion{asig}
	} else {
		list, errList := s.asignacionRepo.ListByPeriodoID(ctx, cmd.PeriodoID)
		if errList != nil {
			return nil, fmt.Errorf("consultar asignaciones: %w", errList)
		}
		for i := range list {
			asignaciones = append(asignaciones, &list[i])
		}
	}

	informe := &InformeGeneracionDTO{
		PeriodoID:            cmd.PeriodoID,
		FechasExcluidas:      make([]FechaExcluidaDTO, 0),
		AsignacionesOmitidas: make([]AsignacionOmitidaDTO, 0),
	}

	loc, _ := time.LoadLocation("America/Bogota")
	if loc == nil {
		loc = time.UTC
	}

	diasTotal := 0
	sesionesNuevas := make([]*academico.Sesion, 0)
	omitidasIdempotencia := 0

	// Caché local de geometrías de espacios para evitar lecturas redundantes en bulk
	espaciosCache := make(map[string]*geo.Espacio)

	for _, asig := range asignaciones {
		if asig.Estado() != academico.AsignacionActiva {
			informe.AsignacionesOmitidas = append(informe.AsignacionesOmitidas, AsignacionOmitidaDTO{
				AsignacionID: asig.ID(),
				Motivo:       "Asignación en estado INACTIVA",
			})
			continue
		}

		franja := asig.Franja()
		diaSemanaObjetivo := franja.DiaSemana() // 1=Lunes .. 7=Domingo

		// Resolver snapshot de parámetros efectivos (AC-02, AC-06, SRS §3.5)
		paramsCongelados := resolverParametrosCongelados(asig)

		// Recuperar geometría del aula para congelar versión (AC-02)
		var espacioSnap *geo.Espacio
		if asig.EspacioID() != "" {
			if cached, ok := espaciosCache[asig.EspacioID()]; ok {
				espacioSnap = cached
			} else {
				esp, _ := s.espacioRepo.FindByID(ctx, asig.EspacioID())
				if esp != nil {
					espaciosCache[asig.EspacioID()] = esp
					espacioSnap = esp
				}
			}
		}

		versionGeometria := 0
		var geomSnapshot *geo.GeoPolygon
		var geomBufferSnapshot *geo.GeoPolygon
		if espacioSnap != nil {
			versionGeometria = espacioSnap.VersionGeometria
			geomSnapshot = espacioSnap.Geometria
			geomBufferSnapshot = espacioSnap.GeometriaBuffer
		}

		// Iterar cada día del periodo académico (AC-01)
		yIni, mIni, dIni := periodo.FechaInicio().Date()
		cur := time.Date(yIni, mIni, dIni, 0, 0, 0, 0, loc)
		yFin, mFin, dFin := periodo.FechaFin().Date()
		fin := time.Date(yFin, mFin, dFin, 23, 59, 59, 0, loc)

		for !cur.After(fin) {
			diasTotal++
			// Convertir weekday estándar (0=Sunday .. 6=Saturday) a ISO (1=Lunes .. 7=Domingo)
			w := int(cur.Weekday())
			if w == 0 {
				w = 7
			}

			fechaStr := cur.Format("2006-01-02")

			// Verificar si coincide con el día de la semana de la franja
			if w == diaSemanaObjetivo {
				// AC-01: Verificar excepciones de calendario (festivos, paros, recesos)
				excluida, motivoEx := esFechaExcluida(cur, periodo.SedeID(), asig.FacultadID(), excepciones)
				if excluida {
					informe.FechasExcluidas = append(informe.FechasExcluidas, FechaExcluidaDTO{
						Fecha:  fechaStr,
						Motivo: motivoEx,
						Tipo:   "EXCEPCION_CALENDARIO",
					})
					cur = cur.AddDate(0, 0, 1)
					continue
				}

				// AC-03: Verificar idempotencia — no duplicar sesión
				existente, _ := s.sesionRepo.FindByAsignacionFechaHora(ctx, asig.ID(), fechaStr, franja.HoraInicio())
				if existente != nil {
					omitidasIdempotencia++
					cur = cur.AddDate(0, 0, 1)
					continue
				}

				// Calcular marcas de tiempo absolutas
				inicioProg, finProg, errHoras := calcularTiemposSesion(cur, franja.HoraInicio(), franja.HoraFin(), loc)
				if errHoras != nil {
					cur = cur.AddDate(0, 0, 1)
					continue
				}

				// Calcular ventanas de entrada y salida a partir de holguras congeladas
				holguraAntes := getParamInt(paramsCongelados, parametro.ClaveHolguraEntradaAntes, 15)
				holguraDespues := getParamInt(paramsCongelados, parametro.ClaveHolguraEntradaDespues, 15)
				ventanaEntradaAbre := inicioProg.Add(-time.Duration(holguraAntes) * time.Minute)
				ventanaEntradaCierra := inicioProg.Add(time.Duration(holguraDespues) * time.Minute)

				var ventanaSalidaAbre, ventanaSalidaCierra *time.Time
				salidaOblig := fmt.Sprintf("%v", paramsCongelados[string(parametro.ClaveSalidaObligatoria)])
				if salidaOblig == "OBLIGATORIO" || salidaOblig == "OPCIONAL" {
					hSalAntes := getParamInt(paramsCongelados, parametro.ClaveHolguraSalidaAntes, 10)
					hSalDespues := getParamInt(paramsCongelados, parametro.ClaveHolguraSalidaDespues, 20)
					a := finProg.Add(-time.Duration(hSalAntes) * time.Minute)
					c := finProg.Add(time.Duration(hSalDespues) * time.Minute)
					ventanaSalidaAbre = &a
					ventanaSalidaCierra = &c
				}

				// Construir la nueva sesión con estado PROGRAMADA (AC-07)
				sesion, errSesion := academico.NuevaSesion(
					shared.NewID(),
					periodo.ID(),
					asig.ID(),
					asig.AsignaturaID(),
					asig.GrupoID(),
					asig.DocenteIDs(),
					asig.EspacioID(),
					fechaStr,
					franja.HoraInicio(),
					franja.HoraFin(),
					inicioProg,
					finProg,
					ventanaEntradaAbre,
					ventanaEntradaCierra,
					ventanaSalidaAbre,
					ventanaSalidaCierra,
					versionGeometria,
					geomSnapshot,
					geomBufferSnapshot,
					paramsCongelados,
					s.clk.Now(),
				)
				if errSesion == nil {
					sesionesNuevas = append(sesionesNuevas, sesion)
				}
			}

			cur = cur.AddDate(0, 0, 1)
		}
		informe.AsignacionesProcesadas++
	}

	// Persistir sesiones generadas en MongoDB en batch (AC-04)
	creadas, errBatch := s.sesionRepo.CreateBatch(ctx, sesionesNuevas)
	if errBatch != nil {
		s.log.Warn("algunas sesiones no pudieron guardarse en batch", applog.Err(errBatch))
	}

	informe.TotalDiasCalendario = diasTotal
	informe.SesionesGeneradas = creadas
	informe.SesionesOmitidasIdempotencia = omitidasIdempotencia
	informe.DuracionMs = time.Since(inicioT).Milliseconds()
	informe.Mensaje = fmt.Sprintf("Generación completada: %d sesiones creadas, %d omitidas por idempotencia.", creadas, omitidasIdempotencia)

	// Auditoría de la generación masiva (AC-05)
	s.auditar(ctx, "periodo", cmd.PeriodoID, "SESIONES_GENERADAS", cmd.Actor, nil, map[string]interface{}{
		"generadas": creadas,
		"omitidas":  omitidasIdempotencia,
	})

	return informe, nil
}
