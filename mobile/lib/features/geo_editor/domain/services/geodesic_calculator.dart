import 'dart:math' as math;

/// Cálculos geodésicos para previsualización cartográfica en el cliente móvil.
/// AC-06: cálculo de área aproximada en pantalla antes de enviar al backend.
/// ADR-04: coordenadas en orden [longitud, latitud].
class GeodesicCalculator {
  static const double radioTierraWGS84 = 6378137.0;

  static double _toRadians(double degrees) => degrees * math.pi / 180.0;

  /// Calcula la distancia Haversine en metros entre dos puntos [lon, lat].
  static double distanciaHaversine(List<double> p1, List<double> p2) {
    final lon1 = p1[0];
    final lat1 = p1[1];
    final lon2 = p2[0];
    final lat2 = p2[1];

    final lat1Rad = _toRadians(lat1);
    final lat2Rad = _toRadians(lat2);
    final deltaLat = _toRadians(lat2 - lat1);
    final deltaLon = _toRadians(lon2 - lon1);

    final sinDeltaLat = math.sin(deltaLat / 2.0);
    final sinDeltaLon = math.sin(deltaLon / 2.0);

    final a = sinDeltaLat * sinDeltaLat +
        math.cos(lat1Rad) * math.cos(lat2Rad) * sinDeltaLon * sinDeltaLon;
    final c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a));

    return radioTierraWGS84 * c;
  }

  /// Calcula el perímetro en metros de una lista de vértices [lon, lat].
  static double calcularPerimetro(List<List<double>> vertices) {
    if (vertices.length < 2) return 0.0;
    double perimetro = 0.0;
    for (int i = 0; i < vertices.length - 1; i++) {
      perimetro += distanciaHaversine(vertices[i], vertices[i + 1]);
    }
    return perimetro;
  }

  /// Calcula el área geodésica en metros cuadrados (m²) usando el algoritmo de Chamberlain-Duquette.
  /// AC-06, T-GEO-02.2.
  static double calcularArea(List<List<double>> vertices) {
    if (vertices.length < 3) return 0.0;

    // Asegurar que el anillo esté cerrado
    final ring = List<List<double>>.from(vertices);
    final p0 = ring.first;
    final pLast = ring.last;
    if (p0[0] != pLast[0] || p0[1] != pLast[1]) {
      ring.add(p0);
    }

    if (ring.length < 4) return 0.0;

    double total = 0.0;
    for (int i = 0; i < ring.length - 1; i++) {
      final p1 = ring[i];
      final p2 = ring[i + 1];

      final lon1 = _toRadians(p1[0]);
      final lat1 = _toRadians(p1[1]);
      final lon2 = _toRadians(p2[0]);
      final lat2 = _toRadians(p2[1]);

      double deltaLon = lon2 - lon1;
      while (deltaLon > math.pi) {
        deltaLon -= 2 * math.pi;
      }
      while (deltaLon < -math.pi) {
        deltaLon += 2 * math.pi;
      }

      total += deltaLon * (2.0 + math.sin(lat1) + math.sin(lat2));
    }

    return (total.abs() * radioTierraWGS84 * radioTierraWGS84 / 2.0);
  }
}
