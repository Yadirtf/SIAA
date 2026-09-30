// push_registro_service.dart — Registro del token push en el backend (US-NOT-01, US-MAR-12)
// Tras iniciar sesión: permiso → token → POST /me/notificaciones/tokens (y en cada rotación).
// Al cerrar sesión: DELETE del token antes de limpiar la sesión.
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import '../../../core/storage/secure_storage.dart';
import 'notificaciones_remote_datasource.dart';
import 'push_proveedor.dart';

String plataformaPushActual() {
  if (kIsWeb) return 'WEB';
  return Platform.isIOS ? 'IOS' : 'ANDROID';
}

class PushRegistroService {
  final PushProveedor? _push;
  final NotificacionesRemoteDataSource _remote;
  final Future<String> Function() _instalacionId;
  final String Function() _plataforma;

  StreamSubscription<String>? _renovaciones;
  String? _tokenRegistrado;

  PushRegistroService({
    PushProveedor? push,
    NotificacionesRemoteDataSource? remote,
    Future<String> Function()? instalacionId,
    String Function()? plataforma,
  })  : _push = push,
        _remote = remote ?? NotificacionesRemoteDataSource(),
        _instalacionId =
            instalacionId ?? SecureStorage.getOrCreateInstalacionId,
        _plataforma = plataforma ?? plataformaPushActual;

  /// false cuando Firebase no está configurado en este build.
  bool get habilitado => _push != null;

  /// Solicita permiso, obtiene el token y lo registra. Errores absorbidos:
  /// el push es un canal complementario a la bandeja.
  Future<void> registrar() async {
    final push = _push;
    if (push == null) return;
    try {
      if (!await push.solicitarPermiso()) return;
      final token = await push.obtenerToken();
      if (token == null || token.isEmpty) return;
      await _enviar(token);
      _renovaciones ??= push.tokenRenovado.listen((t) {
        _enviar(t).catchError((Object _) {});
      });
    } catch (e) {
      debugPrint('[SIAA-PUSH] No se pudo registrar el token: $e');
    }
  }

  Future<void> _enviar(String token) async {
    await _remote.registrarToken(
      token: token,
      plataforma: _plataforma(),
      dispositivoId: await _instalacionId(),
    );
    _tokenRegistrado = token;
  }

  /// Elimina el token en el servidor (con la sesión aún vigente) y localmente.
  Future<void> desregistrar() async {
    await _renovaciones?.cancel();
    _renovaciones = null;
    final push = _push;
    if (push == null) return;
    String? token = _tokenRegistrado;
    try {
      token ??= await push.obtenerToken();
    } catch (_) {}
    if (token != null && token.isNotEmpty) {
      try {
        await _remote.eliminarToken(token);
      } catch (e) {
        debugPrint('[SIAA-PUSH] No se pudo eliminar el token: $e');
      }
    }
    try {
      await push.eliminarTokenLocal();
    } catch (_) {}
    _tokenRegistrado = null;
  }
}
