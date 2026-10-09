// Package notificacion modela el catálogo de avisos, las preferencias del usuario y la franja
// de silencio institucional (EP-10: RF-NOT-001..003, US-NOT-01, US-NOT-02, US-MAR-12).
package notificacion

import (
	"errors"
	"time"
)

// Tipo identifica un aviso del catálogo (US-NOT-02 AC-01).
type Tipo string

const (
	TipoRecordatorioSesion     Tipo = "RECORDATORIO_SESION"
	TipoCierreVentana          Tipo = "CIERRE_VENTANA"
	TipoResultadoJustificacion Tipo = "RESULTADO_JUSTIFICACION"
	TipoCambioHorario          Tipo = "CAMBIO_HORARIO"
	// TipoAlertaInasistencias avisa al coordinador de la facultad (US-PAR-04 AC-02).
	TipoAlertaInasistencias Tipo = "ALERTA_INASISTENCIAS"
)

// Estado del aviso en la cola de envío (US-NOT-01 AC-05).
type Estado string

const (
	EstadoPendiente  Estado = "PENDIENTE"
	EstadoEnviada    Estado = "ENVIADA"
	EstadoSinCanal   Estado = "SIN_CANAL"  // sin token ni correo aplicable; queda en la bandeja
	EstadoDescartada Estado = "DESCARTADA" // desactivada por el usuario o vencida
	EstadoFallida    Estado = "FALLIDA"
)

// Canal por el que efectivamente salió el aviso.
const (
	CanalPush   = "PUSH"
	CanalCorreo = "CORREO"
)

// MaxIntentos antes de dar un aviso por fallido.
const MaxIntentos = 5

// ErrTokenInvalido lo devuelve el enviador cuando el servicio reporta el token como caducado o
// inexistente; el token se purga (US-NOT-01 AC-03).
var ErrTokenInvalido = errors.New("token de notificaciones inválido o caducado")

// Notificacion es un aviso en la cola de envío y, a la vez, una entrada de la bandeja del usuario.
type Notificacion struct {
	ID             string
	UsuarioID      string
	Tipo           Tipo
	Titulo         string
	Cuerpo         string
	Datos          map[string]string // ruta de navegación e identificadores (US-NOT-02 AC-03)
	ClaveDedupe    string            // un mismo aviso nunca se encola dos veces
	Estado         Estado
	Canal          string
	Intentos       int
	UltimoError    string
	Leida          bool
	ProgramadaPara time.Time
	VenceEn        *time.Time // después de esta hora el aviso ya no sirve (p. ej. la ventana cerró)
	EnviadaEn      *time.Time
	CreadaEn       time.Time
}

// Vencida indica si el aviso perdió sentido en el instante dado.
func (n *Notificacion) Vencida(ahora time.Time) bool {
	return n.VenceEn != nil && !ahora.Before(*n.VenceEn)
}

// RutaDe devuelve la pantalla de la app a la que lleva cada tipo al tocarlo.
func RutaDe(t Tipo) string {
	switch t {
	case TipoRecordatorioSesion, TipoCierreVentana:
		return "/marcaje"
	case TipoResultadoJustificacion:
		return "/justificaciones"
	}
	return "/horario"
}

// PermiteCorreo indica los avisos que salen por correo cuando no hay push: los cambios de
// horario y las alertas de inasistencias al coordinador. Los recordatorios caducan en minutos y el resultado de una justificación ya se
// informa por correo al revisarla.
func PermiteCorreo(t Tipo) bool {
	return t == TipoCambioHorario || t == TipoAlertaInasistencias
}
