// push_mensajes_listener.dart — Manejo de mensajes push de la app (US-NOT-01, US-MAR-12)
// Primer plano: aviso en la app con acción "Ver". Segundo plano/terminada: navega al tocar.
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/navigation/config/app_navigator_keys.dart';
import '../data/push_proveedor.dart';
import '../domain/models/destino_notificacion.dart';
import 'notificacion_navegador.dart';

class PushMensajesListener {
  final PushProveedor _push;
  final NotificacionNavegador _navegador;

  /// Se invoca al recibir un mensaje en primer plano (p. ej. refrescar la bandeja).
  final void Function()? onMensaje;
  final List<StreamSubscription<MensajePush>> _subs = [];

  PushMensajesListener({
    required PushProveedor push,
    required NotificacionNavegador navegador,
    this.onMensaje,
  })  : _push = push,
        _navegador = navegador;

  Future<void> iniciar() async {
    _subs.add(_push.aperturas.listen(_abrir));
    _subs.add(_push.mensajesPrimerPlano.listen(_mostrarBanner));
    try {
      final inicial = await _push.aperturaInicial();
      if (inicial != null) _abrir(inicial);
    } catch (_) {}
  }

  void _abrir(MensajePush m) =>
      _navegador.solicitar(DestinoNotificacion.desdeDatos(m.datos));

  void _mostrarBanner(MensajePush m) {
    onMensaje?.call();
    final destino = DestinoNotificacion.desdeDatos(m.datos);
    final titulo = m.titulo ?? 'Nueva notificación';
    AppNavigatorKeys.messenger.currentState?.showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 6),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700)),
          if (m.cuerpo != null && m.cuerpo!.isNotEmpty) Text(m.cuerpo!),
        ],
      ),
      action: destino == null
          ? null
          : SnackBarAction(
              label: 'Ver',
              onPressed: () => _navegador.solicitar(destino),
            ),
    ));
  }

  Future<void> detener() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
  }
}
