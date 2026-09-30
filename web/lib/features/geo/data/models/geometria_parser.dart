/// Convierte la `geometria` GeoJSON de un espacio (`{tipo, coordinates}`) en
/// su lista de vértices `[longitud, latitud]` (ADR-04), sin el vértice de
/// cierre que repite al primero. Devuelve lista vacía si no hay geometría.
List<List<double>> verticesDesdeGeometria(Object? geometria) {
  if (geometria is! Map) return const [];
  final anillos = geometria['coordinates'];
  if (anillos is! List || anillos.isEmpty || anillos.first is! List) {
    return const [];
  }
  final vertices = <List<double>>[];
  for (final punto in anillos.first as List) {
    if (punto is List && punto.length >= 2) {
      vertices.add([
        (punto[0] as num).toDouble(),
        (punto[1] as num).toDouble(),
      ]);
    }
  }
  if (vertices.length > 1 &&
      vertices.first[0] == vertices.last[0] &&
      vertices.first[1] == vertices.last[1]) {
    vertices.removeLast();
  }
  return vertices;
}
