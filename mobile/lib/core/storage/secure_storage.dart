// Almacenamiento seguro — T-PLT-03.6
// Usa Keystore (Android) o Keychain (iOS) para tokens y datos sensibles.
// RNF-SEG-003: ningún token en preferencias en claro.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // ─── Claves ─────────────────────────────────────────────────
  static const _keyAccessToken   = 'siaa_access_token';
  static const _keyRefreshToken  = 'siaa_refresh_token';
  static const _keyInstalacionId = 'siaa_instalacion_id';
  static const _keyConsentimiento = 'siaa_consentimiento_version';

  // ─── Tokens de sesión ──────────────────────────────────────

  /// Guarda el par de tokens de sesión en almacenamiento seguro.
  static Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _keyAccessToken, value: accessToken),
      _storage.write(key: _keyRefreshToken, value: refreshToken),
    ]);
  }

  /// Obtiene el token de acceso actual.
  static Future<String?> getAccessToken() =>
      _storage.read(key: _keyAccessToken);

  /// Obtiene el token de refresco actual.
  static Future<String?> getRefreshToken() =>
      _storage.read(key: _keyRefreshToken);

  /// Elimina todos los datos de sesión (logout).
  static Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: _keyAccessToken),
      _storage.delete(key: _keyRefreshToken),
    ]);
  }

  // ─── ID de instalación ─────────────────────────────────────
  // UUID generado en el primer arranque. NO es IMEI ni ID publicitario.
  // US-AUT-03: identificador estable y privado de la instalación.

  /// Obtiene o genera el ID de instalación de la app.
  static Future<String> getOrCreateInstalacionId() async {
    var id = await _storage.read(key: _keyInstalacionId);
    if (id == null) {
      id = _generateUUID();
      await _storage.write(key: _keyInstalacionId, value: id);
    }
    return id;
  }

  // ─── Consentimiento ────────────────────────────────────────

  /// Guarda la versión de la política de privacidad aceptada.
  static Future<void> saveConsentimiento(String version) =>
      _storage.write(key: _keyConsentimiento, value: version);

  /// Obtiene la versión de política aceptada (null si no ha aceptado).
  static Future<String?> getConsentimientoVersion() =>
      _storage.read(key: _keyConsentimiento);

  /// Elimina todos los datos del almacenamiento (útil para logout completo).
  static Future<void> clearAll() => _storage.deleteAll();

  // ─── Utilidades ────────────────────────────────────────────

  static String _generateUUID() {
    // Implementación simple de UUID v4
    final now = DateTime.now().microsecondsSinceEpoch;
    final random = now.toRadixString(16).padLeft(16, '0');
    return '${random.substring(0, 8)}-${random.substring(8, 12)}-4${random.substring(13, 16)}-a${random.substring(0, 3)}-${DateTime.now().millisecondsSinceEpoch.toRadixString(16).padLeft(12, '0')}';
  }
}
