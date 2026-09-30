package notificaciones

import (
	"context"
	"errors"
	"time"

	"github.com/siaa/backend/internal/domain/notificacion"
	"github.com/siaa/backend/internal/repository"
)

// EnviadorPush entrega un aviso a un token (FCM, que a su vez llega a iOS por APNs).
type EnviadorPush interface {
	Enviar(ctx context.Context, token string, n *notificacion.Notificacion) error
}

// Correo es el canal de respaldo.
type Correo interface {
	Enviar(ctx context.Context, para, asunto, cuerpo string) error
}

// Despachador vacía la cola: aplica preferencias, franja de silencio y vencimiento, envía por
// push a los dispositivos vigentes, purga tokens caducados y usa correo como respaldo.
type Despachador struct {
	cola         repository.NotificacionRepository
	tokens       repository.TokenPushRepository
	preferencias repository.PreferenciasRepository
	usuarios     repository.UsuarioRepository
	dispositivos repository.DispositivoRepository
	push         EnviadorPush
	correo       Correo
	silencio     notificacion.FranjaSilencio
	lote         int
}

// NewDespachador crea el despachador; push y correo pueden ser nil (sin ese canal).
func NewDespachador(cola repository.NotificacionRepository, tokens repository.TokenPushRepository,
	preferencias repository.PreferenciasRepository, usuarios repository.UsuarioRepository,
	dispositivos repository.DispositivoRepository, push EnviadorPush, correo Correo, silencio notificacion.FranjaSilencio,
) *Despachador {
	return &Despachador{cola: cola, tokens: tokens, preferencias: preferencias, usuarios: usuarios,
		dispositivos: dispositivos, push: push, correo: correo, silencio: silencio, lote: 200}
}

// EjecutarCiclo procesa los avisos pendientes hasta `ahora`; devuelve cuántos salieron.
func (d *Despachador) EjecutarCiclo(ctx context.Context, ahora time.Time) (int, error) {
	pendientes, err := d.cola.Pendientes(ctx, ahora, d.lote)
	if err != nil {
		return 0, err
	}
	enviados := 0
	var primerError error
	for _, n := range pendientes {
		d.procesar(ctx, n, ahora)
		if n.Estado == notificacion.EstadoEnviada {
			enviados++
		}
		// Un fallo al guardar un aviso no detiene el resto del lote; se informa al final.
		if err := d.cola.Actualizar(ctx, n); err != nil && primerError == nil {
			primerError = err
		}
	}
	return enviados, primerError
}

func (d *Despachador) procesar(ctx context.Context, n *notificacion.Notificacion, ahora time.Time) {
	if n.Vencida(ahora) || !d.permitido(ctx, n) {
		n.Estado = notificacion.EstadoDescartada
		return
	}
	// US-NOT-02 AC-04: en la franja de silencio se aplaza, salvo que para entonces ya no sirva.
	if d.silencio.Contiene(ahora) {
		n.ProgramadaPara = d.silencio.FinDesde(ahora)
		if n.Vencida(n.ProgramadaPara) {
			n.Estado = notificacion.EstadoDescartada
		}
		return
	}
	entregado, reintentar := d.enviarPush(ctx, n)
	switch {
	case entregado:
		d.marcarEnviada(n, notificacion.CanalPush, ahora)
	case reintentar && n.Intentos < notificacion.MaxIntentos:
		n.ProgramadaPara = ahora.Add(time.Duration(1<<n.Intentos) * time.Minute)
	case d.enviarCorreo(ctx, n):
		d.marcarEnviada(n, notificacion.CanalCorreo, ahora)
	case reintentar:
		n.Estado = notificacion.EstadoFallida
	default:
		n.Estado = notificacion.EstadoSinCanal // queda en la bandeja de la app
	}
}

func (d *Despachador) marcarEnviada(n *notificacion.Notificacion, canal string, ahora time.Time) {
	n.Estado, n.Canal, n.EnviadaEn, n.UltimoError = notificacion.EstadoEnviada, canal, &ahora, ""
}

func (d *Despachador) permitido(ctx context.Context, n *notificacion.Notificacion) bool {
	p, err := d.preferencias.Obtener(ctx, n.UsuarioID)
	if err != nil || p == nil {
		return true
	}
	p.AplicarObligatorias()
	return p.Permite(n.Tipo)
}

// enviarPush intenta cada token vigente del usuario. Devuelve si alguno lo recibió y si hubo
// un fallo transitorio que amerita reintento.
func (d *Despachador) enviarPush(ctx context.Context, n *notificacion.Notificacion) (entregado, reintentar bool) {
	if d.push == nil {
		return false, false
	}
	tokens, err := d.tokens.ListarPorUsuario(ctx, n.UsuarioID)
	if err != nil {
		n.Intentos++
		n.UltimoError = err.Error()
		return false, true
	}
	for _, t := range tokens {
		if !d.dispositivoVigente(ctx, t) {
			_ = d.tokens.Eliminar(ctx, t.Token) // US-NOT-01 AC-04: dispositivo revocado
			continue
		}
		err := d.push.Enviar(ctx, t.Token, n)
		switch {
		case err == nil:
			entregado = true
		case errors.Is(err, notificacion.ErrTokenInvalido):
			_ = d.tokens.Eliminar(ctx, t.Token) // US-NOT-01 AC-03
		default:
			reintentar = true
			n.UltimoError = err.Error()
		}
	}
	if !entregado && reintentar {
		n.Intentos++
	}
	return entregado, reintentar && !entregado
}

func (d *Despachador) dispositivoVigente(ctx context.Context, t repository.TokenPush) bool {
	if d.dispositivos == nil || t.DispositivoID == "" {
		return true
	}
	disp, err := d.dispositivos.FindByInstalacion(ctx, t.UsuarioID, t.DispositivoID)
	if err != nil {
		return true
	}
	return disp == nil || disp.RevocadoEn == nil
}

func (d *Despachador) enviarCorreo(ctx context.Context, n *notificacion.Notificacion) bool {
	if d.correo == nil || d.usuarios == nil || !notificacion.PermiteCorreo(n.Tipo) {
		return false
	}
	u, err := d.usuarios.FindByID(ctx, n.UsuarioID)
	if err != nil || u == nil || u.Correo == "" || !u.Activo {
		return false
	}
	return d.correo.Enviar(ctx, u.Correo, "SIAA - "+n.Titulo, n.Cuerpo+"\r\n") == nil
}
