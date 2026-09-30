// Package marcaje — validación de asignación académica (Paso 4 de RN-001).
// Separa la verificación de pertenencia a grupo, codocencia y suplencia (§11.2, T-MAR-03.1).
package marcaje

import (
	"strings"
	"time"
)

// evaluarAsignacion verifica si el usuario tiene asignación activa para la sesión.
// Satisface RF-ACA-010, US-ACA-09 y US-MAR-13.
func evaluarAsignacion(entrada SolicitudMarcaje, sesion *SesionInfo, ahora time.Time) (bool, ResultadoEvaluacion) {
	if sesion == nil {
		return false, ResultadoEvaluacion{
			Resultado:        ResultadoRechazadoSinAsignacion,
			MotivoRechazo:    MotivoSinAsignacion,
			PasoFallido:      PasoAsignacion,
			PermiteReintento: false,
			PuedeJustificar:  false,
			Mensaje:          GenerarMensaje(ResultadoRechazadoSinAsignacion, MotivoSinAsignacion, DatosMensaje{}),
		}
	}

	usuarioID := strings.TrimSpace(entrada.UsuarioID)
	if entrada.RolMarcaje == RolEstudiante {
		if !contieneString(sesion.EstudianteIDs, usuarioID) {
			return false, ResultadoEvaluacion{
				Resultado:        ResultadoRechazadoSinAsignacion,
				MotivoRechazo:    MotivoSinAsignacion,
				PasoFallido:      PasoAsignacion,
				PermiteReintento: false,
				PuedeJustificar:  false,
				Mensaje:          "No estás matriculado en el grupo correspondiente a esta sesión.",
			}
		}
		if !sesion.VentanaEstudiantilAbierta || ahora.After(sesion.VentanaEstudiantilCierra) {
			return false, ResultadoEvaluacion{
				Resultado:        ResultadoRechazadoFueraHorario,
				MotivoRechazo:    MotivoVentanaEstudiantilCerrada,
				PasoFallido:      PasoAsignacion,
				PermiteReintento: false,
				PuedeJustificar:  true,
				Mensaje:          "La ventana de marcaje para estudiantes no está habilitada o ya concluyó.",
			}
		}
	} else {
		// Docente o suplente (RF-ACA-010, US-ACA-09)
		if sesion.SuplenteID != "" {
			if usuarioID != sesion.SuplenteID {
				return false, ResultadoEvaluacion{
					Resultado:        ResultadoRechazadoSinAsignacion,
					MotivoRechazo:    MotivoSinAsignacion,
					PasoFallido:      PasoAsignacion,
					PermiteReintento: false,
					PuedeJustificar:  true,
					Mensaje:          "Esta sesión cuenta con un suplente designado; la autorización del titular se encuentra suspendida.",
				}
			}
		} else if !contieneString(sesion.DocenteIDs, usuarioID) {
			return false, ResultadoEvaluacion{
				Resultado:        ResultadoRechazadoSinAsignacion,
				MotivoRechazo:    MotivoSinAsignacion,
				PasoFallido:      PasoAsignacion,
				PermiteReintento: false,
				PuedeJustificar:  false,
				Mensaje:          GenerarMensaje(ResultadoRechazadoSinAsignacion, MotivoSinAsignacion, DatosMensaje{}),
			}
		}
	}

	return true, ResultadoEvaluacion{}
}
