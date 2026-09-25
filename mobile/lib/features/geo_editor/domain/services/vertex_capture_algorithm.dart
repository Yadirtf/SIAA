import '../models/gps_reading.dart';

/// Excepción lanzada cuando todas las lecturas de una ráfaga superan el umbral de error permitido.
/// AC-02, T-GEO-02.4.
class PrecisionInsuficienteException implements Exception {
  final String message;
  final double umbralMetros;
  final int totalMuestras;

  PrecisionInsuficienteException({
    required this.message,
    required this.umbralMetros,
    required this.totalMuestras,
  });

  @override
  String toString() =>
      'PrecisionInsuficienteException: $message (umbral: ${umbralMetros}m, muestras: $totalMuestras)';
}

/// Algoritmo de captura y filtrado estadístico de vértices GPS.
/// Implementa AC-01, AC-02, T-GEO-02.4.
class VertexCaptureAlgorithm {
  final int muestrasRequeridas;
  final double umbralPrecisionMetros;

  const VertexCaptureAlgorithm({
    this.muestrasRequeridas = 5,
    this.umbralPrecisionMetros = 15.0,
  });

  /// Procesa una ráfaga de lecturas GPS:
  /// 1. Descarta lecturas con accuracy > umbralPrecisionMetros.
  /// 2. Si no queda ninguna lectura válida, lanza PrecisionInsuficienteException.
  /// 3. Promedia las coordenadas (longitud y latitud) y la precisión de las lecturas válidas.
  /// ADR-04: coordenadas en orden [longitud, latitud].
  GpsReading processReadings(List<GpsReading> readings) {
    if (readings.isEmpty) {
      throw PrecisionInsuficienteException(
        message: 'No se recibieron lecturas de GPS para procesar.',
        umbralMetros: umbralPrecisionMetros,
        totalMuestras: 0,
      );
    }

    // AC-02: descartar lecturas que superen el umbral configurable (15 m por defecto)
    final lecturasValidas =
        readings.where((r) => r.accuracy <= umbralPrecisionMetros).toList();

    if (lecturasValidas.isEmpty) {
      throw PrecisionInsuficienteException(
        message:
            'Todas las $muestrasRequeridas lecturas superaron el umbral de precisión permitido (${umbralPrecisionMetros.toStringAsFixed(1)} m).',
        umbralMetros: umbralPrecisionMetros,
        totalMuestras: readings.length,
      );
    }

    // AC-01: promedio aritmético de las coordenadas válidas
    double sumLon = 0.0;
    double sumLat = 0.0;
    double sumAcc = 0.0;

    for (final r in lecturasValidas) {
      sumLon += r.longitude;
      sumLat += r.latitude;
      sumAcc += r.accuracy;
    }

    final count = lecturasValidas.length.toDouble();
    return GpsReading(
      longitude: sumLon / count,
      latitude: sumLat / count,
      accuracy: sumAcc / count,
      timestamp: DateTime.now().toUtc(),
    );
  }
}
