// Pruebas unitarias para BiometricAuthService.
// Satisface US-AUT-06, AC-01..AC-04 y RNF-USA-001.
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/core/auth/biometric_auth_service.dart';

void main() {
  group('BiometricAuthService (US-AUT-06)', () {
    late bool canCheck;
    late bool authResult;
    late String? storedToken;
    late BiometricAuthService service;

    setUp(() {
      canCheck = true;
      authResult = true;
      storedToken = 'sample-refresh-token-12345';
      service = BiometricAuthService(
        availabilityChecker: () async => canCheck,
        authInvoker: (reason) async => authResult,
        tokenFetcher: () async => storedToken,
      );
    });

    test('AC-01: Autenticación exitosa recupera token de refresco del almacenamiento seguro', () async {
      authResult = true;

      final result = await service.authenticate();

      expect(result.success, isTrue);
      expect(result.refreshToken, equals('sample-refresh-token-12345'));
      expect(result.requiresPasswordFallback, isFalse);
      expect(service.failedAttempts, equals(0));
    });

    test('AC-02: Dispositivo sin biometría reporta fallback obligatorio a contraseña', () async {
      canCheck = false;

      final result = await service.authenticate();

      expect(result.success, isFalse);
      expect(result.requiresPasswordFallback, isTrue);
    });

    test('AC-03: Tres intentos fallidos bloquean la biometría y exigen contraseña institucional', () async {
      authResult = false;

      // Intento 1
      final res1 = await service.authenticate();
      expect(res1.success, isFalse);
      expect(res1.requiresPasswordFallback, isFalse);
      expect(service.failedAttempts, equals(1));

      // Intento 2
      final res2 = await service.authenticate();
      expect(res2.success, isFalse);
      expect(res2.requiresPasswordFallback, isFalse);
      expect(service.failedAttempts, equals(2));

      // Intento 3 -> Bloqueo
      final res3 = await service.authenticate();
      expect(res3.success, isFalse);
      expect(res3.requiresPasswordFallback, isTrue);
      expect(service.failedAttempts, equals(3));

      // Intento 4 sin permitir llamada biométrica
      final res4 = await service.authenticate();
      expect(res4.success, isFalse);
      expect(res4.requiresPasswordFallback, isTrue);
      expect(res4.errorMessage, contains('Límite de 3 intentos biométricos excedido'));
    });

    test('resetFailedAttempts reinicia el contador de intentos', () {
      service.resetFailedAttempts();
      expect(service.failedAttempts, equals(0));
    });
  });
}
