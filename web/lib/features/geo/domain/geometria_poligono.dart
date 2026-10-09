import 'dart:math' as math;

/// Radio ecuatorial WGS84, el mismo que usa el backend (geodesic.go).
const double radioTierraWgs84 = 6378137.0;

/// Área geodésica aproximada en m² de un anillo `[longitud, latitud]` (sin
/// vértice de cierre), con la misma fórmula del backend para que el valor en
/// vivo del editor coincida con el que se persiste (US-GEO-07 AC-01).
double areaGeodesicaM2(List<List<double>> vertices) {
  if (vertices.length < 3) return 0;
  double rad(double g) => g * math.pi / 180;
  var total = 0.0;
  for (var i = 0; i < vertices.length; i++) {
    final p1 = vertices[i];
    final p2 = vertices[(i + 1) % vertices.length];
    var dLon = rad(p2[0]) - rad(p1[0]);
    while (dLon > math.pi) {
      dLon -= 2 * math.pi;
    }
    while (dLon < -math.pi) {
      dLon += 2 * math.pi;
    }
    total += dLon * (2 + math.sin(rad(p1[1])) + math.sin(rad(p2[1])));
  }
  return (total * radioTierraWgs84 * radioTierraWgs84 / 2).abs();
}

/// Punto en pantalla (píxeles) usado para medir cercanía a las aristas.
typedef PuntoPantalla = ({double x, double y});

/// Resultado de buscar la arista más cercana a un toque.
class AristaCercana {
  /// Índice del vértice inicial de la arista; el nuevo vértice va en
  /// `indice + 1`.
  final int indice;

  /// Distancia en píxeles del toque a la arista.
  final double distancia;

  /// Fracción `[0, 1]` de la arista donde cae la proyección del toque.
  final double t;

  const AristaCercana(this.indice, this.distancia, this.t);
}

/// Arista del polígono cerrado más cercana a [toque], en coordenadas de
/// pantalla. Devuelve `null` si hay menos de 3 vértices o si la más cercana
/// está a más de [tolerancia] píxeles (US-GEO-07 AC-02).
AristaCercana? aristaMasCercana(
  List<PuntoPantalla> puntos,
  PuntoPantalla toque, {
  double tolerancia = 14,
}) {
  if (puntos.length < 3) return null;
  AristaCercana? mejor;
  for (var i = 0; i < puntos.length; i++) {
    final a = puntos[i];
    final b = puntos[(i + 1) % puntos.length];
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    final largo2 = dx * dx + dy * dy;
    var t = largo2 == 0
        ? 0.0
        : ((toque.x - a.x) * dx + (toque.y - a.y) * dy) / largo2;
    t = t.clamp(0.0, 1.0);
    final px = a.x + t * dx - toque.x;
    final py = a.y + t * dy - toque.y;
    final d = math.sqrt(px * px + py * py);
    if (mejor == null || d < mejor.distancia) {
      mejor = AristaCercana(i, d, t);
    }
  }
  if (mejor == null || mejor.distancia > tolerancia) return null;
  return mejor;
}
