// push_proveedor.dart — Abstracción del proveedor de notificaciones push (US-NOT-01)
// Permite probar el registro de tokens sin depender de Firebase en las pruebas.

/// Mensaje push recibido o tocado por el usuario.
class MensajePush {
  final String? titulo;
  final String? cuerpo;

  /// Payload `data` (todos strings según el contrato).
  final Map<String, dynamic> datos;

  const MensajePush({this.titulo, this.cuerpo, this.datos = const {}});
}

abstract class PushProveedor {
  /// Solicita el permiso de notificaciones; true si quedó concedido.
  Future<bool> solicitarPermiso();

  Future<String?> obtenerToken();

  /// Emite el nuevo token cuando el proveedor lo rota.
  Stream<String> get tokenRenovado;

  /// Invalida el token local (cierre de sesión).
  Future<void> eliminarTokenLocal();

  /// Mensajes recibidos con la app en primer plano.
  Stream<MensajePush> get mensajesPrimerPlano;

  /// Notificaciones tocadas con la app en segundo plano.
  Stream<MensajePush> get aperturas;

  /// Notificación que abrió la app desde terminada (si la hubo).
  Future<MensajePush?> aperturaInicial();
}
