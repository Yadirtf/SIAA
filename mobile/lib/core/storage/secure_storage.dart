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
    webOptions: WebOptions(
      dbName: 'SiaaStorage',
      publicKey: 'SiaaPublicKey',
    ),
  );

  // Caché en memoria para mitigar restricciones de descifrado WebCrypto y OperationError
  static final Map<String, String> _memoryCache = {};

  // ─── Claves ─────────────────────────────────────────────────
  static const _keyAccessToken   = 'siaa_access_token';
  static const _keyRefreshToken  = 'siaa_refresh_token';
  static const _keyInstalacionId = 'siaa_instalacion_id';
  static const _keyConsentimiento = 'siaa_consentimiento_version';

  // ─── Tokens de sesión ──────────────────────────────────────

  /// Guarda el par de tokens de sesión en almacenamiento seguro y en memoria.
  static Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
  }) async {
    _memoryCache[_keyAccessToken] = accessToken;
    _memoryCache[_keyRefreshToken] = refreshToken;
    try {
      await Future.wait([
        _storage.write(key: _keyAccessToken, value: accessToken),
        _storage.write(key: _keyRefreshToken, value: refreshToken),
      ]);
    } catch (_) {
      // Si el motor seguro subyacente (ej. WebCrypto en navegador) falla, la sesión persiste en memoria
    }
  }

  /// Obtiene el token de acceso actual sin lanzar excepciones por fallos de descifrado WebCrypto.
  static Future<String?> getAccessToken() async {
    if (_memoryCache.containsKey(_keyAccessToken)) {
      return _memoryCache[_keyAccessToken];
    }
    try {
      final token = await _storage.read(key: _keyAccessToken);
      if (token != null) {
        _memoryCache[_keyAccessToken] = token;
      }
      return token;
    } catch (_) {
      return _memoryCache[_keyAccessToken];
    }
  }

  /// Obtiene el token de refresco actual.
  static Future<String?> getRefreshToken() async {
    if (_memoryCache.containsKey(_keyRefreshToken)) {
      return _memoryCache[_keyRefreshToken];
    }
    try {
      final token = await _storage.read(key: _keyRefreshToken);
      if (token != null) {
        _memoryCache[_keyRefreshToken] = token;
      }
      return token;
    } catch (_) {
      return _memoryCache[_keyRefreshToken];
    }
  }

  /// Elimina todos los datos de sesión (logout).
  static Future<void> clearSession() async {
    _memoryCache.remove(_keyAccessToken);
    _memoryCache.remove(_keyRefreshToken);
    try {
      await Future.wait([
        _storage.delete(key: _keyAccessToken),
        _storage.delete(key: _keyRefreshToken),
      ]);
    } catch (_) {}
  }

  // ─── ID de instalación ─────────────────────────────────────
  // UUID generado en el primer arranque. NO es IMEI ni ID publicitario.
  // US-AUT-03: identificador estable y privado de la instalación.

  /// Obtiene o genera el ID de instalación de la app.
  static Future<String> getOrCreateInstalacionId() async {
    if (_memoryCache.containsKey(_keyInstalacionId)) {
      return _memoryCache[_keyInstalacionId]!;
    }
    String? id;
    try {
      id = await _storage.read(key: _keyInstalacionId);
    } catch (_) {}

    if (id == null) {
      id = _generateUUID();
      _memoryCache[_keyInstalacionId] = id;
      try {
        await _storage.write(key: _keyInstalacionId, value: id);
      } catch (_) {}
    } else {
      _memoryCache[_keyInstalacionId] = id;
    }
    return id;
  }

  // ─── Consentimiento ────────────────────────────────────────

  /// Guarda la versión de la política de privacidad aceptada.
  static Future<void> saveConsentimiento(String version) async {
    _memoryCache[_keyConsentimiento] = version;
    try {
      await _storage.write(key: _keyConsentimiento, value: version);
    } catch (_) {}
  }

  /// Obtiene la versión de política aceptada (null si no ha aceptado).
  static Future<String?> getConsentimientoVersion() async {
    if (_memoryCache.containsKey(_keyConsentimiento)) {
      return _memoryCache[_keyConsentimiento];
    }
    try {
      final version = await _storage.read(key: _keyConsentimiento);
      if (version != null) {
        _memoryCache[_keyConsentimiento] = version;
      }
      return version;
    } catch (_) {
      return _memoryCache[_keyConsentimiento];
    }
  }

  /// Elimina todos los datos del almacenamiento (útil para logout completo).
  static Future<void> clearAll() async {
    _memoryCache.clear();
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }

  // ─── Utilidades ────────────────────────────────────────────

  static String _generateUUID() {
    // Implementación simple de UUID v4
    final now = DateTime.now().microsecondsSinceEpoch;
    final random = now.toRadixString(16).padLeft(16, '0');
    return '${random.substring(0, 8)}-${random.substring(8, 12)}-4${random.substring(13, 16)}-a${random.substring(0, 3)}-${DateTime.now().millisecondsSinceEpoch.toRadixString(16).padLeft(12, '0')}';
  }
}
