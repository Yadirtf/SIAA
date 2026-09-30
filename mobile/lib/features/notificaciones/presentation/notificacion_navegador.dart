// notificacion_navegador.dart — Navegación al tocar una notificación (US-NOT-01/02, US-MAR-12)
// Guarda el destino hasta que el shell autenticado esté listo (app terminada, login o
// aviso de privacidad en pantalla) y luego lo abre.
import '../../../core/navigation/config/app_navigator_keys.dart';
import '../../privacidad/presentation/screens/aviso_privacidad_screen.dart';
import '../domain/models/destino_notificacion.dart';

class NotificacionNavegador {
  final void Function() _cerrarRutasSuperiores;
  final bool Function() _bloqueado;

  void Function(DestinoNotificacion destino)? _abrir;
  DestinoNotificacion? _pendiente;

  NotificacionNavegador({
    void Function()? cerrarRutasSuperiores,
    bool Function()? bloqueado,
  })  : _cerrarRutasSuperiores = cerrarRutasSuperiores ??
            (() => AppNavigatorKeys.navigator.currentState
                ?.popUntil((r) => r.isFirst)),
        _bloqueado = bloqueado ?? (() => AvisoPrivacidadScreen.visible);

  DestinoNotificacion? get pendiente => _pendiente;

  /// El shell autenticado registra cómo abrir un destino.
  void adjuntar(void Function(DestinoNotificacion destino) abrir) {
    _abrir = abrir;
    intentar();
  }

  void desadjuntar() => _abrir = null;

  /// Solicita abrir un destino (se aplica ahora o cuando el shell esté listo).
  void solicitar(DestinoNotificacion? destino) {
    if (destino == null) return;
    _pendiente = destino;
    intentar();
  }

  /// Abre el destino pendiente si hay shell y nada lo bloquea.
  void intentar() {
    final abrir = _abrir;
    final destino = _pendiente;
    if (abrir == null || destino == null || _bloqueado()) return;
    _pendiente = null;
    _cerrarRutasSuperiores();
    abrir(destino);
  }
}
