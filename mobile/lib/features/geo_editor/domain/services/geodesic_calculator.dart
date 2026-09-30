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

  /// Comprueba si dos segmentos [p1, p2] y [p3, p4] se cruzan estrictamente.
  static bool _segmentosSeCruzan(
    List<double> p1,
    List<double> p2,
    List<double> p3,
    List<double> p4,
  ) {
    double ccw(List<double> a, List<double> b, List<double> c) {
      return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0]);
    }

    final d1 = ccw(p1, p2, p3);
    final d2 = ccw(p1, p2, p4);
    final d3 = ccw(p3, p4, p1);
    final d4 = ccw(p3, p4, p2);

    return ((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
        ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0));
  }

  /// Verifica si el polígono perimetral contiene aristas no adyacentes que se cruzan entre sí (forma de X).
  static bool tieneAutoInterseccion(List<List<double>> vertices) {
    if (vertices.length < 4) return false;

    // Normalizar a anillo cerrado
    final ring = List<List<double>>.from(vertices);
    if (ring.first[0] != ring.last[0] || ring.first[1] != ring.last[1]) {
      ring.add(ring.first);
    }

    final numEdges = ring.length - 1;
    for (int i = 0; i < numEdges; i++) {
      for (int j = i + 1; j < numEdges; j++) {
        // Ignorar aristas adyacentes y cierre (primera y última)
        if ((i - j).abs() <= 1) continue;
        if (i == 0 && j == numEdges - 1) continue;

        if (_segmentosSeCruzan(ring[i], ring[i + 1], ring[j], ring[j + 1])) {
          return true;
        }
      }
    }
    return false;
  }

  /// Calcula el área con signo en 2D (Shoelace) para determinar la orientación (CW vs CCW).
  static double _areaConSigno(List<List<double>> vertices) {
    double sum = 0.0;
    final n = vertices.length;
    for (int i = 0; i < n; i++) {
      final p1 = vertices[i];
      final p2 = vertices[(i + 1) % n];
      sum += (p2[0] - p1[0]) * (p2[1] + p1[1]);
    }
    return sum;
  }

  /// Asegura que el polígono esté ordenado en sentido antihorario (CCW),
  /// requerido por la especificación GeoJSON RFC 7946 e índices 2dsphere de MongoDB.
  static List<List<double>> normalizarSentidoAntihorario(
      List<List<double>> vertices) {
    if (vertices.length < 3) return List.from(vertices);

    final lista = List<List<double>>.from(vertices);
    final esCerrado = lista.length >= 4 &&
        lista.first[0] == lista.last[0] &&
        lista.first[1] == lista.last[1];

    if (esCerrado) {
      lista.removeLast();
    }

    // Para la fórmula sum += (x2 - x1) * (y2 + y1):
    // Si sum > 0 es horario (CW). Si sum < 0 es antihorario (CCW).
    final areaSigno = _areaConSigno(lista);
    if (areaSigno > 0) {
      // Invertir para convertir de horario a antihorario
      final invertida = lista.reversed.toList();
      if (esCerrado) {
        invertida.add(invertida.first);
      }
      return invertida;
    }

    if (esCerrado) {
      lista.add(lista.first);
    }
    return lista;
  }
}
