// preferencia_biometria.dart — Preferencia local "reabrir con biometría" (US-AUT-06)
// Se guarda en el almacenamiento seguro del dispositivo; nunca viaja al servidor (AC-04).
// Por defecto está activa (AC-01: con sesión previa y biometría disponible se solicita);
// el usuario puede desactivarla desde su perfil.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PreferenciaBiometria {
  static const _clave = 'siaa_biometria_habilitada';

  final Future<String?> Function() _leer;
  final Future<void> Function(String valor) _escribir;

  PreferenciaBiometria({
    Future<String?> Function()? leer,
    Future<void> Function(String valor)? escribir,
  })  : _leer = leer ?? (() => const FlutterSecureStorage().read(key: _clave)),
        _escribir = escribir ??
            ((v) => const FlutterSecureStorage().write(key: _clave, value: v));

  /// true salvo que el usuario la haya desactivado explícitamente.
  Future<bool> habilitada() async {
    try {
      return await _leer() != 'false';
    } catch (_) {
      return true;
    }
  }

  Future<void> guardar(bool habilitada) async {
    try {
      await _escribir(habilitada ? 'true' : 'false');
    } catch (_) {
      // Sin almacenamiento seguro disponible se conserva el comportamiento por defecto.
    }
  }
}
