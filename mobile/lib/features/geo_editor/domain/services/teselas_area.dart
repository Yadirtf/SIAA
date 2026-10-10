// teselas_area.dart — Aritmética de teselas XYZ (Web Mercator) para el caché sin conexión
// Función pura: convierte un área geográfica y un rango de zoom en la lista de teselas.
import 'dart:math' as math;

import '../models/clave_tesela.dart';

class TeselasArea {
  const TeselasArea._();

  static const _latMaxMercator = 85.05112878;

  static int columna(double longitud, int z) {
    final n = 1 << z;
    final x = ((longitud + 180.0) / 360.0 * n).floor();
    return x.clamp(0, n - 1);
  }

  static int fila(double latitud, int z) {
    final n = 1 << z;
    final lat = latitud.clamp(-_latMaxMercator, _latMaxMercator);
    final rad = lat * math.pi / 180.0;
    final y = ((1.0 - math.log(math.tan(rad) + 1.0 / math.cos(rad)) / math.pi) /
            2.0 *
            n)
        .floor();
    return y.clamp(0, n - 1);
  }

  /// Número de teselas que cubren [area] entre [zMin] y [zMax] (inclusive).
  static int contar(AreaGeo area, int zMin, int zMax) {
    var total = 0;
    for (var z = zMin; z <= zMax; z++) {
      final ancho = columna(area.este, z) - columna(area.oeste, z) + 1;
      final alto = fila(area.sur, z) - fila(area.norte, z) + 1;
      total += ancho * alto;
    }
    return total;
  }

  /// Teselas de [capa] que cubren [area] entre [zMin] y [zMax].
  static Iterable<ClaveTesela> enArea(
    String capa,
    AreaGeo area,
    int zMin,
    int zMax,
  ) sync* {
    for (var z = zMin; z <= zMax; z++) {
      final x0 = columna(area.oeste, z);
      final x1 = columna(area.este, z);
      final y0 = fila(area.norte, z);
      final y1 = fila(area.sur, z);
      for (var x = x0; x <= x1; x++) {
        for (var y = y0; y <= y1; y++) {
          yield ClaveTesela(capa: capa, z: z, x: x, y: y);
        }
      }
    }
  }

  /// Mayor zoom (≤ [zMax], ≥ [zMin]) cuyo total de teselas no supera [limite];
  /// null si ni siquiera el nivel mínimo cabe (el área es demasiado grande).
  static int? zoomMaximoDentroDeLimite(
    AreaGeo area,
    int zMin,
    int zMax,
    int limite,
  ) {
    for (var z = zMax; z >= zMin; z--) {
      if (contar(area, zMin, z) <= limite) return z;
    }
    return null;
  }

  /// Sustituye {z}/{x}/{y} en una plantilla XYZ.
  static String url(String plantilla, ClaveTesela t) => plantilla
      .replaceAll('{z}', '${t.z}')
      .replaceAll('{x}', '${t.x}')
      .replaceAll('{y}', '${t.y}');
}
