// Package auth — Autenticación biométrica local y almacenamiento seguro.
// Satisface US-AUT-06, AC-01..AC-04 y RNF-USA-001.
import 'package:local_auth/local_auth.dart';
import '../storage/secure_storage.dart';

/// Resultado del intento de autenticación biométrica local.
class BiometricAuthResult {
  final bool success;
  final String? refreshToken;
  final String? errorMessage;
  final bool requiresPasswordFallback;

  const BiometricAuthResult._({
    required this.success,
    this.refreshToken,
    this.errorMessage,
    this.requiresPasswordFallback = false,
  });

  factory BiometricAuthResult.success(String refreshToken) => BiometricAuthResult._(
        success: true,
        refreshToken: refreshToken,
      );

  factory BiometricAuthResult.failure(String message, {bool requiresPassword = false}) =>
      BiometricAuthResult._(
        success: false,
        errorMessage: message,
        requiresPasswordFallback: requiresPassword,
      );
}

typedef TokenFetcher = Future<String?> Function();
typedef LocalAuthInvoker = Future<bool> Function(String reason);
typedef BiometricAvailabilityChecker = Future<bool> Function();

/// Servicio de autenticación biométrica local (huella dactilar, FaceID)
/// que interactúa estrictamente con el hardware local sin enviar datos al servidor.
class BiometricAuthService {
  final LocalAuthentication? _localAuth;
  final LocalAuthInvoker? _authInvoker;
  final BiometricAvailabilityChecker? _availabilityChecker;
  final TokenFetcher _tokenFetcher;

  int _failedAttempts = 0;
  static const int maxFailedAttempts = 3;

  BiometricAuthService({
    LocalAuthentication? localAuth,
    LocalAuthInvoker? authInvoker,
    BiometricAvailabilityChecker? availabilityChecker,
    TokenFetcher? tokenFetcher,
  })  : _localAuth = localAuth ?? (authInvoker == null ? LocalAuthentication() : null),
        _authInvoker = authInvoker,
        _availabilityChecker = availabilityChecker,
        _tokenFetcher = tokenFetcher ?? SecureStorage.getRefreshToken;

  int get failedAttempts => _failedAttempts;

  /// Verifica si el hardware soporta biometría y si el usuario tiene biometría enrolada (AC-01, AC-02).
  Future<bool> isBiometricsAvailable() async {
    if (_availabilityChecker != null) {
      return await _availabilityChecker!();
    }
    if (_localAuth == null) return false;
    try {
      final canCheck = await _localAuth!.canCheckBiometrics;
      final isSupported = await _localAuth!.isDeviceSupported();
      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  /// Ejecuta la autenticación biométrica local en el dispositivo.
  /// Si supera los 3 intentos fallidos, bloquea y exige contraseña institucional completa (AC-03).
  /// Ningún dato biométrico sale jamás del dispositivo (AC-04).
  Future<BiometricAuthResult> authenticate({
    String reason = 'Confirme su identidad biométrica para acceder a SIAA',
  }) async {
    // Si ya alcanzó el límite de 3 fallos consecutivos, forzar contraseña
    if (_failedAttempts >= maxFailedAttempts) {
      return BiometricAuthResult.failure(
        'Límite de 3 intentos biométricos excedido. Ingrese su contraseña institucional.',
        requiresPassword: true,
      );
    }

    final available = await isBiometricsAvailable();
    if (!available) {
      return BiometricAuthResult.failure(
        'Biometría no disponible o no configurada en este dispositivo.',
        requiresPassword: true,
      );
    }

    try {
      bool authenticated = false;
      if (_authInvoker != null) {
        authenticated = await _authInvoker!(reason);
      } else if (_localAuth != null) {
        authenticated = await _localAuth!.authenticate(
          localizedReason: reason,
        );
      }

      if (authenticated) {
        _failedAttempts = 0;
        final token = await _tokenFetcher();
        if (token == null || token.isEmpty) {
          return BiometricAuthResult.failure(
            'No hay sesión activa para restaurar; ingrese con credenciales.',
            requiresPassword: true,
          );
        }
        return BiometricAuthResult.success(token);
      } else {
        _failedAttempts++;
        final isLocked = _failedAttempts >= maxFailedAttempts;
        return BiometricAuthResult.failure(
          isLocked
              ? 'Tres intentos biométricos fallidos. Ingrese su contraseña institucional.'
              : 'Verificación biométrica no superada (intento $_failedAttempts de $maxFailedAttempts).',
          requiresPassword: isLocked,
        );
      }
    } catch (e) {
      _failedAttempts++;
      final isLocked = _failedAttempts >= maxFailedAttempts;
      return BiometricAuthResult.failure(
        'Error durante la autenticación biométrica: $e',
        requiresPassword: isLocked,
      );
    }
  }

  /// Reinicia el contador de intentos fallidos al autenticarse exitosamente con contraseña.
  void resetFailedAttempts() {
    _failedAttempts = 0;
  }
}
