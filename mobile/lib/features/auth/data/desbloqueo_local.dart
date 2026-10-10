// desbloqueo_local.dart — Decide si al abrir la app se exige verificación local (US-AUT-06)
// Se exige cuando hay una sesión previa guardada, el usuario no desactivó la opción y el
// dispositivo puede verificarlo localmente (biometría o, en su defecto, su PIN/patrón).
// Sin ningún mecanismo local la sesión se restaura como antes: no se bloquea el uso (AC-02).
import '../../../core/auth/biometric_auth_service.dart';
import '../../../core/auth/preferencia_biometria.dart';
import '../../../core/storage/secure_storage.dart';

class DesbloqueoLocal {
  final BiometricAuthService _servicio;
  final PreferenciaBiometria _preferencia;
  final Future<String?> Function() _leerRefreshToken;

  DesbloqueoLocal({
    BiometricAuthService? servicio,
    PreferenciaBiometria? preferencia,
    Future<String?> Function()? leerRefreshToken,
  })  : _servicio = servicio ?? BiometricAuthService(),
        _preferencia = preferencia ?? PreferenciaBiometria(),
        _leerRefreshToken = leerRefreshToken ?? SecureStorage.getRefreshToken;

  Future<bool> requiereDesbloqueo() async {
    try {
      final token = await _leerRefreshToken();
      if (token == null || token.isEmpty) return false;
      if (!await _preferencia.habilitada()) return false;
      return await _servicio.isBiometricsAvailable() ||
          await _servicio.isDeviceCredentialAvailable();
    } catch (_) {
      return false;
    }
  }
}
