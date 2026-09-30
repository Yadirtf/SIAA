// Package network — Servicio de Jitter aleatorio para mitigar picos de concurrencia.
// Satisface US-PLT-05, AC-05 y Mitigación de Riesgo R-05.
import 'dart:math';

/// Servicio de desfase temporal aleatorio (jitter) para evitar la sincronización
/// simultánea de peticiones masivas en el cambio de hora (pico de las 7:00 AM).
class JitterService {
  final Random _random;

  JitterService({Random? random}) : _random = random ?? Random();

  /// Calcula una duración de jitter en el intervalo [0, maxSeconds * 1000] milisegundos.
  Duration calculateJitter({int maxSeconds = 20}) {
    if (maxSeconds <= 0) {
      return Duration.zero;
    }
    final maxMs = maxSeconds * 1000;
    final jitterMs = _random.nextInt(maxMs + 1);
    return Duration(milliseconds: jitterMs);
  }

  /// Espera asíncronamente el tiempo de jitter calculado antes de ejecutar la petición.
  Future<void> waitJitter({int maxSeconds = 20}) async {
    final delay = calculateJitter(maxSeconds: maxSeconds);
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
  }
}
