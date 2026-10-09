// Package auth — Autenticación biométrica local y almacenamiento seguro.
// Satisface US-AUT-06, AC-01..AC-04 y RNF-USA-001.
// La verificación la hace el sistema operativo: la app solo recibe "superada" o "no
// superada"; ningún dato biométrico se lee, se transmite ni se guarda (AC-04).
import 'package:local_auth/local_auth.dart';
import '../storage/secure_storage.dart';

/// Resultado del intento de autenticación biométrica local.
class BiometricAuthResult {
  final bool success;
  final String? refreshToken;
  final String? errorMessage;
  final bool requiresPasswordFallback;

  /// El usuario (o el sistema) canceló el diálogo: no cuenta como intento fallido.
  final bool cancelado;

  const BiometricAuthResult._({
    required this.success,
    this.refreshToken,
    this.errorMessage,
    this.requiresPasswordFallback = false,
    this.cancelado = false,
  });

  factory BiometricAuthResult.success(String refreshToken) =>
      BiometricAuthResult._(success: true, refreshToken: refreshToken);

  factory BiometricAuthResult.failure(String message,
          {bool requiresPassword = false, bool cancelado = false}) =>
      BiometricAuthResult._(
        success: false,
        errorMessage: message,
        requiresPasswordFallback: requiresPassword,
        cancelado: cancelado,
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
  final LocalAuthInvoker? _credencialInvoker;
  final BiometricAvailabilityChecker? _availabilityChecker;
  final BiometricAvailabilityChecker? _dispositivoSeguroChecker;
  final TokenFetcher _tokenFetcher;

  int _failedAttempts = 0;
  static const int maxFailedAttempts = 3;

  static const _cancelaciones = {
    LocalAuthExceptionCode.userCanceled,
    LocalAuthExceptionCode.systemCanceled,
    LocalAuthExceptionCode.userRequestedFallback,
  };

  BiometricAuthService({
    LocalAuthentication? localAuth,
    LocalAuthInvoker? authInvoker,
    LocalAuthInvoker? credencialInvoker,
    BiometricAvailabilityChecker? availabilityChecker,
    BiometricAvailabilityChecker? dispositivoSeguroChecker,
    TokenFetcher? tokenFetcher,
  })  : _localAuth =
            localAuth ?? (authInvoker == null ? LocalAuthentication() : null),
        _authInvoker = authInvoker,
        _credencialInvoker = credencialInvoker,
        _availabilityChecker = availabilityChecker,
        _dispositivoSeguroChecker = dispositivoSeguroChecker,
        _tokenFetcher = tokenFetcher ?? SecureStorage.getRefreshToken;

  int get failedAttempts => _failedAttempts;

  /// Verifica si el hardware soporta biometría y si el usuario tiene biometría enrolada (AC-01, AC-02).
  Future<bool> isBiometricsAvailable() async {
    final checker = _availabilityChecker;
    if (checker != null) return checker();
    final auth = _localAuth;
    if (auth == null) return false;
    try {
      return await auth.canCheckBiometrics && await auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// El dispositivo tiene un bloqueo propio (PIN, patrón o código) utilizable como
  /// alternativa local cuando no hay biometría configurada (AC-02).
  Future<bool> isDeviceCredentialAvailable() async {
    final checker = _dispositivoSeguroChecker;
    if (checker != null) return checker();
    final auth = _localAuth;
    if (auth == null) return false;
    try {
      return await auth.isDeviceSupported();
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
    if (_failedAttempts >= maxFailedAttempts) {
      return BiometricAuthResult.failure(
        'Límite de 3 intentos biométricos excedido. Ingrese su contraseña institucional.',
        requiresPassword: true,
      );
    }
    if (!await isBiometricsAvailable()) {
      return BiometricAuthResult.failure(
        'Biometría no disponible o no configurada en este dispositivo.',
        requiresPassword: true,
      );
    }
    try {
      final invoker = _authInvoker;
      final auth = _localAuth;
      final ok = invoker != null
          ? await invoker(reason)
          : auth != null &&
              await auth.authenticate(
                  localizedReason: reason, biometricOnly: true);
      if (ok) {
        _failedAttempts = 0;
        return await _recuperarToken();
      }
      return _registrarFallo('Verificación biométrica no superada');
    } on LocalAuthException catch (e) {
      if (_cancelaciones.contains(e.code)) {
        return BiometricAuthResult.failure('Verificación cancelada.',
            cancelado: true);
      }
      if (e.code == LocalAuthExceptionCode.biometricLockout ||
          e.code == LocalAuthExceptionCode.temporaryLockout) {
        _failedAttempts = maxFailedAttempts;
        return BiometricAuthResult.failure(
          'La biometría quedó bloqueada en el dispositivo. Ingrese su contraseña institucional.',
          requiresPassword: true,
        );
      }
      return _registrarFallo('Error durante la autenticación biométrica');
    } catch (e) {
      return _registrarFallo('Error durante la autenticación biométrica: $e');
    }
  }

  /// Desbloqueo con el PIN, patrón o código del propio dispositivo (AC-02).
  /// Lo valida el sistema operativo; la app nunca ve el PIN.
  Future<BiometricAuthResult> autenticarConCredencialDispositivo({
    String reason = 'Use el PIN o patrón de su dispositivo para abrir SIAA',
  }) async {
    try {
      final invoker = _credencialInvoker;
      final auth = _localAuth;
      final ok = invoker != null
          ? await invoker(reason)
          : auth != null && await auth.authenticate(localizedReason: reason);
      if (ok) return await _recuperarToken();
      return BiometricAuthResult.failure('Verificación no superada.');
    } on LocalAuthException catch (e) {
      return BiometricAuthResult.failure('Verificación cancelada.',
          cancelado: _cancelaciones.contains(e.code));
    } catch (_) {
      return BiometricAuthResult.failure(
        'El dispositivo no permite la verificación local. Ingrese con su contraseña.',
        requiresPassword: true,
      );
    }
  }

  Future<BiometricAuthResult> _recuperarToken() async {
    final token = await _tokenFetcher();
    if (token == null || token.isEmpty) {
      return BiometricAuthResult.failure(
        'No hay sesión activa para restaurar; ingrese con credenciales.',
        requiresPassword: true,
      );
    }
    return BiometricAuthResult.success(token);
  }

  BiometricAuthResult _registrarFallo(String detalle) {
    _failedAttempts++;
    final bloqueado = _failedAttempts >= maxFailedAttempts;
    return BiometricAuthResult.failure(
      bloqueado
          ? 'Tres intentos biométricos fallidos. Ingrese su contraseña institucional.'
          : '$detalle (intento $_failedAttempts de $maxFailedAttempts).',
      requiresPassword: bloqueado,
    );
  }

  /// Reinicia el contador de intentos fallidos al autenticarse exitosamente con contraseña.
  void resetFailedAttempts() {
    _failedAttempts = 0;
  }
}
