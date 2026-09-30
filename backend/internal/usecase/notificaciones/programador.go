package notificaciones

import (
	"context"
	"fmt"
	"time"

	domainMarcaje "github.com/siaa/backend/internal/domain/marcaje"
	"github.com/siaa/backend/internal/repository"
)

const procesoProgramador = "notificaciones"

// Programador encola los recordatorios de clase y los avisos de cierre de ventana. Recorre por
// marca de agua, así un ciclo tardío no pierde avisos ni los repite (ADR-09).
type Programador struct {
	agenda        repository.AgendaRepository
	marcajes      repository.MarcajeRepository
	procesos      repository.ProcesoRepository
	productor     *Productor
	anticipacion  time.Duration // recordatorio antes del inicio
	avisoDeCierre time.Duration // aviso antes del cierre de la ventana (US-MAR-12 AC-01)
}

// NewProgramador crea el programador con 15 min de recordatorio y 5 min de aviso de cierre.
func NewProgramador(agenda repository.AgendaRepository, marcajes repository.MarcajeRepository, procesos repository.ProcesoRepository, productor *Productor) *Programador {
	return &Programador{agenda: agenda, marcajes: marcajes, procesos: procesos, productor: productor,
		anticipacion: 15 * time.Minute, avisoDeCierre: 5 * time.Minute}
}

// ConAnticipacion ajusta los minutos de recordatorio y de aviso de cierre (0 = sin cambio).
func (p *Programador) ConAnticipacion(recordatorioMin, cierreMin int) *Programador {
	if recordatorioMin > 0 {
		p.anticipacion = time.Duration(recordatorioMin) * time.Minute
	}
	if cierreMin > 0 {
		p.avisoDeCierre = time.Duration(cierreMin) * time.Minute
	}
	return p
}

// EjecutarCiclo encola los avisos cuya hora de envío cae entre la marca anterior y `ahora`.
// En la primera ejecución no se envía nada atrasado.
func (p *Programador) EjecutarCiclo(ctx context.Context, ahora time.Time) (int, error) {
	desde := ahora
	if marca, err := p.procesos.ObtenerMarca(ctx, procesoProgramador); err != nil {
		return 0, err
	} else if marca != nil && marca.Before(ahora) {
		desde = *marca
	}
	encolados := 0

	inician, err := p.agenda.SesionesQueInician(ctx, desde.Add(p.anticipacion), ahora.Add(p.anticipacion))
	if err != nil {
		return 0, fmt.Errorf("recordatorios: %w", err)
	}
	// Si la cola falla no se avanza la marca: el siguiente ciclo reintenta y la clave de
	// deduplicación evita repetir lo que sí quedó encolado.
	for _, s := range inician {
		for _, d := range s.DocenteIDs() {
			if err := p.productor.RecordatorioSesion(ctx, s, d); err != nil {
				return encolados, fmt.Errorf("encolar recordatorio: %w", err)
			}
			encolados++
		}
	}

	cierran, err := p.agenda.SesionesQueCierran(ctx, desde.Add(p.avisoDeCierre), ahora.Add(p.avisoDeCierre))
	if err != nil {
		return encolados, fmt.Errorf("avisos de cierre: %w", err)
	}
	if len(cierran) > 0 {
		ids := make([]string, len(cierran))
		for i, s := range cierran {
			ids[i] = s.ID()
		}
		// US-MAR-12 AC-02: quien ya marcó no recibe el aviso.
		consolidados, err := p.marcajes.ListarConsolidados(ctx, ids, domainMarcaje.TipoEntrada)
		if err != nil {
			return encolados, err
		}
		marco := map[string]bool{}
		for _, m := range consolidados {
			marco[m.SesionID+"|"+m.UsuarioID] = true
		}
		for _, s := range cierran {
			for _, d := range s.DocenteIDs() {
				if marco[s.ID()+"|"+d] {
					continue
				}
				if err := p.productor.CierreVentana(ctx, s, d); err != nil {
					return encolados, fmt.Errorf("encolar aviso de cierre: %w", err)
				}
				encolados++
			}
		}
	}
	return encolados, p.procesos.GuardarMarca(ctx, procesoProgramador, ahora)
}
