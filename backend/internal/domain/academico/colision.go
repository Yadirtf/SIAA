package academico

import (
	"fmt"
)

type TipoColision string

const (
	ColisionDocente TipoColision = "COLISION_DOCENTE" // RF-ACA-005, US-ACA-03 AC-02
	ColisionAula    TipoColision = "COLISION_AULA"    // RF-ACA-005, US-ACA-03 AC-03
)

// ReporteColision detalla un conflicto de solapamiento horario encontrado.
type ReporteColision struct {
	Tipo             TipoColision `json:"tipo"`
	Mensaje          string       `json:"mensaje"`
	AsignacionPrevia string       `json:"asignacionPreviaId"`
	DocenteConflicto string       `json:"docenteId,omitempty"`
	EspacioConflicto string       `json:"espacioId,omitempty"`
	DiaSemana        int          `json:"diaSemana"`
	HoraInicio       string       `json:"horaInicio"`
	HoraFin          string       `json:"horaFin"`
}

// DetectarColisiones analiza una lista de asignaciones existentes contra una nueva asignación
// y retorna un reporte si existe alguna colisión de docente o de aula (función pura).
func DetectarColisiones(existentes []Asignacion, nueva Asignacion) *ReporteColision {
	for _, prev := range existentes {
		// Ignorar si está borrada, inactiva, o es la misma asignación que se está actualizando
		if prev.Borrado() || prev.Estado() != AsignacionActiva || (nueva.ID() != "" && prev.ID() == nueva.ID()) {
			continue
		}

		// Solo hay conflicto si pertenecen al mismo periodo académico
		if prev.PeriodoID() != nueva.PeriodoID() {
			continue
		}

		// Solo hay conflicto si las franjas horarias se solapan
		if !prev.Franja().SeSolapaCon(nueva.Franja()) {
			continue
		}

		// 1. Detección de colisión de docente (US-ACA-03 AC-02):
		// Un docente no puede estar en dos asignaciones solapadas en el tiempo.
		for _, docID := range nueva.DocenteIDs() {
			if prev.ContieneDocente(docID) {
				return &ReporteColision{
					Tipo:             ColisionDocente,
					Mensaje:          fmt.Sprintf("Conflicto docente: el docente %s ya tiene una clase asignada en el día %d de %s a %s (US-ACA-03 AC-02)", docID, prev.Franja().DiaSemana(), prev.Franja().HoraInicio(), prev.Franja().HoraFin()),
					AsignacionPrevia: prev.ID(),
					DocenteConflicto: docID,
					DiaSemana:        prev.Franja().DiaSemana(),
					HoraInicio:       prev.Franja().HoraInicio(),
					HoraFin:          prev.Franja().HoraFin(),
				}
			}
		}

		// 2. Detección de colisión de aula (US-ACA-03 AC-03):
		// Un aula física no puede tener dos grupos en la misma franja y periodo.
		// (Modalidades virtuales no usan espacio físico exclusivo).
		if !nueva.ExentaGeoespacial() && !prev.ExentaGeoespacial() && nueva.EspacioID() != "" && prev.EspacioID() == nueva.EspacioID() {
			return &ReporteColision{
				Tipo:             ColisionAula,
				Mensaje:          fmt.Sprintf("Conflicto de aula: el espacio %s ya se encuentra ocupado en el día %d de %s a %s por otro grupo (US-ACA-03 AC-03)", nueva.EspacioID(), prev.Franja().DiaSemana(), prev.Franja().HoraInicio(), prev.Franja().HoraFin()),
				AsignacionPrevia: prev.ID(),
				EspacioConflicto: nueva.EspacioID(),
				DiaSemana:        prev.Franja().DiaSemana(),
				HoraInicio:       prev.Franja().HoraInicio(),
				HoraFin:          prev.Franja().HoraFin(),
			}
		}
	}

	return nil
}
