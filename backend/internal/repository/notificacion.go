// Package repository — cola de avisos, tokens push y preferencias (EP-10).
package repository

import (
	"context"
	"time"

	"github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/domain/notificacion"
)

// NotificacionRepository es la cola de envío y la bandeja de cada usuario (US-NOT-01 AC-05).
type NotificacionRepository interface {
	// Encolar inserta el aviso; devuelve false si ya existía uno con la misma ClaveDedupe.
	Encolar(ctx context.Context, n *notificacion.Notificacion) (bool, error)
	// Pendientes devuelve avisos PENDIENTES programados hasta `hasta`, los más antiguos primero.
	Pendientes(ctx context.Context, hasta time.Time, limite int) ([]*notificacion.Notificacion, error)
	Actualizar(ctx context.Context, n *notificacion.Notificacion) error
	// Bandeja lista los avisos ya procesados del usuario (enviados o sin canal), recientes primero.
	Bandeja(ctx context.Context, usuarioID string, limite int) ([]*notificacion.Notificacion, error)
	// MarcarLeida devuelve false si el aviso no existe o no es del usuario.
	MarcarLeida(ctx context.Context, id, usuarioID string) (bool, error)
}

// TokenPush vincula un token FCM con el usuario y la instalación que lo registró.
type TokenPush struct {
	Token         string
	UsuarioID     string
	DispositivoID string
	Plataforma    string
	ActualizadoEn time.Time
}

// TokenPushRepository guarda los tokens de notificación por usuario y dispositivo.
type TokenPushRepository interface {
	// Guardar reasigna el token al usuario y dispositivo dados (un token es de una sola instalación).
	Guardar(ctx context.Context, t TokenPush) error
	Eliminar(ctx context.Context, token string) error
	ListarPorUsuario(ctx context.Context, usuarioID string) ([]TokenPush, error)
}

// PreferenciasRepository guarda qué avisos quiere recibir cada usuario.
type PreferenciasRepository interface {
	// Obtener devuelve nil si el usuario nunca configuró sus preferencias.
	Obtener(ctx context.Context, usuarioID string) (*notificacion.Preferencias, error)
	Guardar(ctx context.Context, usuarioID string, p notificacion.Preferencias) error
}

// AgendaRepository encuentra las sesiones vigentes que inician o cuyo marcaje cierra en una ventana.
type AgendaRepository interface {
	SesionesQueInician(ctx context.Context, desde, hasta time.Time) ([]*academico.Sesion, error)
	SesionesQueCierran(ctx context.Context, desde, hasta time.Time) ([]*academico.Sesion, error)
}
