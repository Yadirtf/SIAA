// Package marcaje — catálogo de mensajes de retroalimentación accionables.
// Satisface US-MAR-06 (AC-01..AC-06), RNF-USA-005, §9.1 y T-MAR-06.1.
// Principio: responder siempre "QUÉ PASÓ, POR QUÉ PASÓ y QUÉ PUEDE HACER EL USUARIO".
package marcaje

import (
	"fmt"
	"math"
	"time"
)

// DatosMensaje contiene los datos contextuales para interpolar en los mensajes de usuario.
type DatosMensaje struct {
	DistanciaMetros       float64
	AulaNombre            string
	MinutosDesviacion     int
	MinutosRespectoInicio int
	VentanaAbre           time.Time
	VentanaCierra         time.Time
	PrecisionRecibida     float64
	PrecisionRequerida    float64
	DispositivoEsperado   string
	DispositivoRecibido   string
	Hora                  time.Time
}

// GenerarMensaje construye el texto legible y accionable para la UI del usuario.
func GenerarMensaje(res ResultadoMarcaje, motivo MotivoRechazo, datos DatosMensaje) string {
	switch res {
	case ResultadoPresente:
		if !datos.Hora.IsZero() {
			return fmt.Sprintf("Asistencia registrada exitosamente a las %s.", datos.Hora.Format("15:04"))
		}
		return "Asistencia registrada exitosamente a tiempo."

	case ResultadoTardanza:
		return fmt.Sprintf("Asistencia registrada con novedad de retardo (%d minutos tarde). Procura llegar a tiempo a tu sesión.", datos.MinutosRespectoInicio)

	case ResultadoRechazadoFueraDeArea:
		distRedondeada := math.Round(datos.DistanciaMetros)
		if datos.AulaNombre != "" {
			return fmt.Sprintf("Estás a %.0f m del espacio %s. Debes ingresar al aula asignada para registrar tu asistencia.", distRedondeada, datos.AulaNombre)
		}
		return fmt.Sprintf("Estás a %.0f m fuera del perímetro permitido del aula. Acércate a tu salón de clase para marcar.", distRedondeada)

	case ResultadoRechazadoFueraHorario:
		if datos.MinutosDesviacion < 0 {
			return fmt.Sprintf("Aún no inicia el horario de marcaje. Faltan %d minutos para la apertura de la ventana.", -datos.MinutosDesviacion)
		}
		return fmt.Sprintf("Ventana de marcaje cerrada hace %d minutos. Si tuviste un inconveniente comprobable, radica una justificación en el sistema.", datos.MinutosDesviacion)

	case ResultadoPrecisionInsuficiente:
		return fmt.Sprintf("Señal GPS débil (precisión actual: %.1f m, requerida: %.1f m). Acércate a una ventana o despeja tu vista al cielo e inténtalo de nuevo.", datos.PrecisionRecibida, datos.PrecisionRequerida)

	case ResultadoRechazadoIntegridad:
		switch motivo {
		case MotivoMockLocation:
			return "No es posible registrar marcaje con una aplicación de ubicación simulada activa. Desactiva los ajustes de ubicación falsa en tu dispositivo y reintenta."
		case MotivoDispositivoComprometido:
			return "Dispositivo modificado (root/jailbreak/emulador detectado). Por políticas de seguridad institucional, los marcajes deben realizarse en dispositivos estándar."
		case MotivoAttestationFallida:
			return "No se pudo verificar la autenticidad e integridad de la aplicación institucional instalada. Actualiza la app desde la tienda oficial."
		case MotivoDispositivoNoVinculado:
			return "Este dispositivo no coincide con el teléfono confiable registrado en tu cuenta. Vincula este dispositivo con un administrador o utiliza tu dispositivo principal."
		default:
			return "El registro no pudo validarse debido a señales de seguridad en tu dispositivo. Si consideras que es un error, contacta a soporte técnico institucional."
		}

	case ResultadoRechazadoSinAsignacion:
		return "No tienes una sesión de clase activa asignada en este momento. Verifica tu horario académico."

	case ResultadoRechazadoVerificacion:
		return "La verificación complementaria (código QR o red institucional) no coincide con los valores registrados para este espacio físico. Confirma tu ubicación e inténtalo de nuevo."

	default:
		return "No fue posible procesar el marcaje de asistencia. Inténtalo de nuevo o contacta al administrador."
	}
}
