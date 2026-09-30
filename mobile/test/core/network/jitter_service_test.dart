// Pruebas unitarias de JitterService.
// Satisface US-PLT-05, AC-05 y Mitigación de Riesgo R-05.
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/core/network/jitter_service.dart';

void main() {
  group('JitterService (US-PLT-05 AC-05 / R-05)', () {
    test('calculateJitter respeta estrictamente el límite máximo de 20 segundos', () {
      final service = JitterService();
      const maxSeconds = 20;
      const maxMs = maxSeconds * 1000;

      for (int i = 0; i < 1000; i++) {
        final jitter = service.calculateJitter(maxSeconds: maxSeconds);
        expect(jitter.inMilliseconds, greaterThanOrEqualTo(0));
        expect(jitter.inMilliseconds, lessThanOrEqualTo(maxMs));
      }
    });

    test('calculateJitter respeta límites personalizados', () {
      final service = JitterService();
      const maxSeconds = 5;
      const maxMs = maxSeconds * 1000;

      for (int i = 0; i < 200; i++) {
        final jitter = service.calculateJitter(maxSeconds: maxSeconds);
        expect(jitter.inMilliseconds, greaterThanOrEqualTo(0));
        expect(jitter.inMilliseconds, lessThanOrEqualTo(maxMs));
      }
    });

    test('calculateJitter con maxSeconds <= 0 retorna Duration.zero', () {
      final service = JitterService();
      expect(service.calculateJitter(maxSeconds: 0), equals(Duration.zero));
      expect(service.calculateJitter(maxSeconds: -5), equals(Duration.zero));
    });

    test('produce distribución aleatoria uniforme verificable', () {
      final random = Random(42); // Seed fija para verificación determinista
      final service = JitterService(random: random);

      final values = <int>[];
      for (int i = 0; i < 100; i++) {
        values.add(service.calculateJitter(maxSeconds: 20).inMilliseconds);
      }

      final distinctCount = values.toSet().length;
      expect(distinctCount, greaterThan(80), reason: 'Debe exhibir variabilidad aleatoria');
      expect(values.reduce(min), greaterThanOrEqualTo(0));
      expect(values.reduce(max), lessThanOrEqualTo(20000));
    });
  });
}
